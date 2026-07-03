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
