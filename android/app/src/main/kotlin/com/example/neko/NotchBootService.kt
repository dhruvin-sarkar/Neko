package com.example.neko

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugins.GeneratedPluginRegistrant

/// A foreground service that keeps the notch overlay bootstrap alive so the
/// overlay can remain available even when the main app process is no longer
/// running. It starts a small Flutter engine once, runs `notchBootMain` to show
/// and restore the overlay, then stays alive as the host for that bootstrap path.
class NotchBootService : Service() {
    private var engine: FlutterEngine? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        startForegroundNotification()

        val eng = FlutterEngine(this)
        GeneratedPluginRegistrant.registerWith(eng)
        MethodChannel(eng.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "stop") {
                result.success(true)
                stopSelf()
            } else {
                result.notImplemented()
            }
        }
        eng.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(
                FlutterInjector.instance().flutterLoader().findAppBundlePath(),
                "notchBootMain",
            ),
        )
        engine = eng
    }

    // NOT sticky: every legitimate start comes from an explicit trigger (boot
    // receiver / bridge), and the Dart bootstrap now stops this service on
    // every path — a sticky restart would only resurrect an empty host with
    // its "Restoring notch…" notification.
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int =
        START_NOT_STICKY

    private fun startForegroundNotification() {
        val manager = getSystemService(NotificationManager::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Neko notch",
                    NotificationManager.IMPORTANCE_MIN,
                ),
            )
        }
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        val notification = builder
            .setContentTitle("Neko")
            .setContentText("Restoring notch…")
            .setSmallIcon(R.mipmap.ic_launcher)
            .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    override fun onDestroy() {
        engine?.destroy()
        engine = null
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL = "neko/notch_boot"
        private const val CHANNEL_ID = "neko_notch_boot"
        private const val NOTIFICATION_ID = 4580
    }
}
