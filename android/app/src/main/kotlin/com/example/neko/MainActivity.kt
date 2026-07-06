package com.example.neko

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // Stream of real notification / now-playing events from the listener.
        EventChannel(messenger, "neko/notch_events").setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                    NotchBridge.sink = events
                }

                override fun onCancel(arguments: Any?) {
                    NotchBridge.sink = null
                }
            },
        )

        MethodChannel(messenger, "neko/notch").setMethodCallHandler { call, result ->
            when (call.method) {
                "hasNotificationAccess" -> result.success(hasNotificationAccess())
                "openNotificationAccessSettings" -> {
                    startActivity(
                        Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                    )
                    result.success(true)
                }
                "resyncNotch" -> {
                    // Re-emit current media + ongoing activities so an already
                    // playing song / active call shows the moment the notch is on.
                    NekoNotificationListenerService.instance?.resync()
                    result.success(true)
                }
                "mediaControl" -> {
                    // Play / pause / skip from the notch's transport buttons.
                    val action = call.argument<String>("action") ?: ""
                    NekoNotificationListenerService.instance?.control(action)
                    result.success(true)
                }
                // Hey Neko wake word: the mic foreground service may only be
                // started while the app is in the foreground — which is exactly
                // when these calls arrive (Settings toggle / app resume).
                "startHeyNekoListener" -> {
                    // Android 14+ crashes a microphone-typed startForeground
                    // when the mic permission has been revoked — never start
                    // the service without it (the Dart side also checks; this
                    // is the last line of defence).
                    val micGranted = checkSelfPermission(
                        android.Manifest.permission.RECORD_AUDIO,
                    ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                    if (micGranted) {
                        androidx.core.content.ContextCompat.startForegroundService(
                            this,
                            Intent(this, HeyNekoListenerService::class.java),
                        )
                    }
                    result.success(micGranted)
                }
                "stopHeyNekoListener" -> {
                    stopService(Intent(this, HeyNekoListenerService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        // App/Activity is going away (but the overlay's foreground service may
        // keep the process alive) — drop the sink so listener events route
        // straight to the overlay engine instead of a dead channel.
        NotchBridge.sink = null
        super.onDestroy()
    }

    private fun hasNotificationAccess(): Boolean {
        val enabled = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val component = "$packageName/${NekoNotificationListenerService::class.java.name}"
        return enabled.split(":").any { it.equals(component, ignoreCase = true) }
    }
}
