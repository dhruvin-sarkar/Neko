package com.example.neko

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.BasicMessageChannel
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.JSONMessageCodec
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

/// Bridge between the always-running NotificationListenerService and the notch.
///
/// Delivery, in priority order:
///  1. Main app engine listening ([sink] set) → NotchController (adds theme +
///     boot-restore persistence).
///  2. Overlay engine alive (cached by its foreground service) → push straight
///     onto the channel `overlayListener` receives on. Works with the app killed.
///  3. Neither alive (app killed + overlay down) → stash the event and boot the
///     overlay via NotchBootService, which shows it and flushes the event.
object NotchBridge {
    // Must match flutter_overlay_window's OverlayConstants.
    private const val OVERLAY_ENGINE_TAG = "myCachedEngine"
    private const val OVERLAY_MESSENGER_TAG = "x-slayer/overlay_messenger"

    @Volatile
    var sink: EventChannel.EventSink? = null

    @Volatile
    var listenerConnected = false

    @Volatile
    private var mediaShownDirect = false

    // Method channel for the overlay's transport buttons, registered directly on
    // the overlay engine so play/pause/skip work even when the main app process
    // has been killed and only the overlay's foreground service is alive.
    private const val OVERLAY_MEDIA_TAG = "neko/notch_media"

    @Volatile
    private var controlBoundEngine: FlutterEngine? = null

    private val handler = Handler(Looper.getMainLooper())

    /// Binds the media-control channel on the overlay engine (idempotent per
    /// engine). Safe to call often; it no-ops once bound.
    fun bindOverlayControls(context: Context) {
        val engine = FlutterEngineCache.getInstance().get(OVERLAY_ENGINE_TAG) ?: return
        if (engine === controlBoundEngine) return
        handler.post {
            try {
                MethodChannel(engine.dartExecutor.binaryMessenger, OVERLAY_MEDIA_TAG)
                    .setMethodCallHandler { call, result ->
                        if (call.method == "control") {
                            NekoNotificationListenerService.instance
                                ?.control(call.argument<String>("action") ?: "")
                            result.success(true)
                        } else {
                            result.notImplemented()
                        }
                    }
                controlBoundEngine = engine
            } catch (_: Exception) {
            }
        }
    }

    fun send(context: Context, event: Map<String, Any?>) {
        bindOverlayControls(context)
        val target = sink
        if (target != null) {
            // App engine handles gating (the notch enabled flag) itself.
            handler.post {
                try {
                    target.success(event)
                } catch (_: Exception) {
                }
            }
            return
        }
        // App not listening: only drive the overlay if the notch is enabled.
        if (!isEnabled(context)) return
        val command = buildCommand(event) ?: return
        if (deliverToOverlay(command)) return
        // App killed and overlay down: stash + cold-start the overlay.
        persistPending(context, command)
        startBootService(context)
    }

    private fun isEnabled(context: Context): Boolean {
        return try {
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .getBoolean("flutter.notch_enabled", false)
        } catch (_: Exception) {
            false
        }
    }

    /// Pushes a NotchCommand JSON string onto the overlay engine's messenger.
    /// Returns false if the overlay engine isn't currently alive.
    private fun deliverToOverlay(command: String): Boolean {
        val engine = FlutterEngineCache.getInstance().get(OVERLAY_ENGINE_TAG)
            ?: return false
        handler.post {
            try {
                BasicMessageChannel<Any>(
                    engine.dartExecutor.binaryMessenger,
                    OVERLAY_MESSENGER_TAG,
                    JSONMessageCodec.INSTANCE,
                ).send(command)
            } catch (_: Exception) {
            }
        }
        return true
    }

    private fun persistPending(context: Context, command: String) {
        try {
            context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putString("flutter.notch_pending", command)
                .commit()
        } catch (_: Exception) {
        }
    }

    private fun startBootService(context: Context) {
        try {
            ContextCompat.startForegroundService(
                context,
                Intent(context, NotchBootService::class.java),
            )
        } catch (_: Exception) {
        }
    }

    private fun buildCommand(event: Map<String, Any?>): String? {
        return when (event["kind"]) {
            "notification" -> {
                val category = (event["category"] as? String) ?: ""
                val ongoing = event["ongoing"] == true
                val progress = (event["progress"] as? Number)?.toDouble() ?: -1.0
                val type = when {
                    category == "call" -> "call"
                    category == "navigation" -> "navigation"
                    progress >= 0.0 && ongoing -> "download"
                    else -> "notification"
                }
                val activity = JSONObject()
                    .put("type", type)
                    .put("id", event["key"] ?: "")
                    .put("appName", event["package"] ?: "")
                    .put("title", event["title"] ?: "")
                    .put("body", event["body"] ?: "")
                    .put("ongoing", ongoing || type != "notification")
                if (progress >= 0.0) activity.put("progress", progress)
                JSONObject().put("cmd", "push").put("activity", activity).toString()
            }
            "media" -> {
                // Paused music stays on the island; it only leaves on
                // 'mediaStopped' (the session ending).
                val cmd = if (mediaShownDirect) "update" else {
                    mediaShownDirect = true
                    "push"
                }
                val durMs = (event["duration"] as? Number)?.toLong() ?: 0L
                val posMs = (event["position"] as? Number)?.toLong() ?: 0L
                val progress =
                    if (durMs > 0) (posMs.toDouble() / durMs).coerceIn(0.0, 1.0) else 0.0
                val activity = JSONObject()
                    .put("type", "music")
                    .put("songTitle", event["title"] ?: "")
                    .put("artistName", event["artist"] ?: "")
                    .put("isPlaying", event["playing"] == true)
                    .put("progress", progress)
                    .put("durationMs", if (durMs > 0) durMs else JSONObject.NULL)
                    .put("albumArt", event["art"] ?: "")
                    .put("source", "system")
                JSONObject().put("cmd", cmd).put("activity", activity).toString()
            }
            "mediaStopped" -> {
                mediaShownDirect = false
                JSONObject().put("cmd", "remove").put("removeType", "music").toString()
            }
            else -> null
        }
    }
}
