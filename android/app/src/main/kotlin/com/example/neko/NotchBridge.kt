package com.example.neko

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
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
                        when (call.method) {
                            "control" -> {
                                NekoNotificationListenerService.instance
                                    ?.control(call.argument<String>("action") ?: "")
                                result.success(true)
                            }
                            "haptic" -> {
                                vibrate(context, call.argument<String>("type") ?: "light")
                                result.success(true)
                            }
                            "launchApp" -> {
                                launchApp(context, call.argument<String>("package"))
                                result.success(true)
                            }
                            "launchUrl" -> {
                                launchUrl(context, call.argument<String>("url"))
                                result.success(true)
                            }
                            else -> result.notImplemented()
                        }
                    }
                controlBoundEngine = engine
            } catch (_: Exception) {
            }
        }
    }

    /// A short native haptic, driven from the overlay (Flutter's HapticFeedback
    /// is a no-op in the overlay engine). Best-effort — silently ignored if the
    /// device has no vibrator or the user has haptics off system-wide.
    private fun vibrate(context: Context, type: String) {
        try {
            val ms = when (type) {
                "success" -> 28L
                "selection" -> 12L
                else -> 10L
            }
            val amp = when (type) {
                "success" -> 140
                "selection" -> 80
                else -> 55
            }
            val ctx = context.applicationContext
            when {
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
                    val vm = ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE)
                        as VibratorManager
                    vm.defaultVibrator.vibrate(VibrationEffect.createOneShot(ms, amp))
                }
                Build.VERSION.SDK_INT >= Build.VERSION_CODES.O -> {
                    val v = ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    v.vibrate(VibrationEffect.createOneShot(ms, amp))
                }
                else -> {
                    @Suppress("DEPRECATION")
                    (ctx.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator).vibrate(ms)
                }
            }
        } catch (_: Exception) {
        }
    }

    /// Opens the source app for a notch activity (long-press). Best-effort:
    /// null/blank package or no launcher intent just does nothing.
    private fun launchApp(context: Context, pkg: String?) {
        if (pkg.isNullOrBlank()) return
        try {
            val ctx = context.applicationContext
            val intent = ctx.packageManager.getLaunchIntentForPackage(pkg) ?: return
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            ctx.startActivity(intent)
        } catch (_: Exception) {
        }
    }

    /// Opens a web URL in the browser (an AI-notch result tap). Best-effort.
    private fun launchUrl(context: Context, url: String?) {
        if (url.isNullOrBlank()) return
        try {
            val ctx = context.applicationContext
            val intent = Intent(Intent.ACTION_VIEW, android.net.Uri.parse(url))
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            ctx.startActivity(intent)
        } catch (_: Exception) {
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
        // App not listening: drive the overlay when the notch is enabled or when
        // there is persisted restore/pending state to recover.
        if (!shouldBootstrap(context)) return
        val command = buildCommand(event) ?: return
        if (deliverToOverlay(command)) return
        // App killed and overlay down: stash + cold-start the overlay.
        persistPending(context, command)
        startBootService(context)
    }

    private fun shouldBootstrap(context: Context): Boolean {
        return try {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val enabled = NotchPreferencesCompat.getBoolean(prefs, "flutter.notch_enabled", false)
            enabled || hasPersistedRestore(prefs) || hasPending(prefs)
        } catch (_: Exception) {
            false
        }
    }

    private fun hasPersistedRestore(prefs: android.content.SharedPreferences): Boolean {
        return !NotchPreferencesCompat.getString(prefs, "flutter.notch_restore", null).isNullOrEmpty()
    }

    private fun hasPending(prefs: android.content.SharedPreferences): Boolean {
        return !NotchPreferencesCompat.getString(prefs, "flutter.notch_pending", null).isNullOrEmpty()
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
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            NotchPreferencesCompat.putString(prefs, "flutter.notch_pending", command)
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
                val endsAtMs = (event["endsAtMs"] as? Number)?.toLong() ?: 0L
                val type = when {
                    category == "timer" -> "timer"
                    category == "call" -> "call"
                    category == "navigation" -> "navigation"
                    progress >= 0.0 && ongoing -> "download"
                    else -> "notification"
                }
                val activity = JSONObject()
                    .put("type", type)
                    .put("id", event["key"] ?: "")
                    .put("appName", event["package"] ?: "")
                    .put("packageId", event["packageId"] ?: "")
                    .put("title", event["title"] ?: "")
                    .put("body", event["body"] ?: "")
                    .put("ongoing", ongoing || type != "notification")
                if (progress >= 0.0) activity.put("progress", progress)
                if (type == "timer" && endsAtMs > 0L) activity.put("endsAtMs", endsAtMs)
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
                    .put("packageId", event["packageId"] ?: "")
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
