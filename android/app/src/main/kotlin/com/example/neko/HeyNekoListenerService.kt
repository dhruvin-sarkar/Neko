package com.example.neko

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

/// Foreground service that keeps the "Hey Neko" wake word listening while the
/// app is backgrounded.
///
/// The actual recognition loop lives in the main Flutter engine
/// (speech_to_text in WakeWordController); this service holds the
/// microphone-type foreground grant so Android keeps the process and its mic
/// access alive when the user switches apps. Android forbids starting a mic
/// foreground service FROM the background, so it is only ever started from a
/// foreground context — the Settings toggle or app resume (MainActivity's
/// method channel) — never from a boot receiver or notification event.
///
/// The persistent notification is deliberately honest about the open mic; it
/// is required by the platform anyway, so it doubles as the indicator that
/// hands-free listening is on.
class HeyNekoListenerService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startListeningForeground()
        // Never auto-restart: a restart without the app in the foreground
        // would be an illegal background mic-service start anyway. The app
        // re-starts the service itself on next resume if the toggle is on.
        // (Deliberately NOT START_STICKY: a system-restarted sticky service
        // would show a "listening" notification with the Flutter engine — the
        // thing that actually listens — dead.)
        return START_NOT_STICKY
    }

    override fun onTaskRemoved(rootIntent: Intent?) {
        // Swiping the task away kills the Flutter engine that actually holds
        // the recogniser; without this, the notification would keep claiming
        // an open mic with nothing behind it. The next foreground launch
        // re-starts the service when the toggle is still on.
        stopSelf()
        super.onTaskRemoved(rootIntent)
    }

    private fun startListeningForeground() {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Hey Neko voice",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "Shown while Neko listens for the “Hey Neko” wake word."
                },
            )
        }

        val tapIntent = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )

        val notification: Notification =
            (
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Notification.Builder(this, CHANNEL_ID)
                } else {
                    @Suppress("DEPRECATION")
                    Notification.Builder(this)
                }
                )
                .setContentTitle("Listening for “Hey Neko”")
                .setContentText("Mic is on for hands-free Neko. Turn off in Settings.")
                .setSmallIcon(android.R.drawable.ic_btn_speak_now)
                .setContentIntent(tapIntent)
                .setOngoing(true)
                .build()

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                NOTIFICATION_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE,
            )
        } else {
            startForeground(NOTIFICATION_ID, notification)
        }
    }

    companion object {
        private const val CHANNEL_ID = "hey_neko_listener"
        private const val NOTIFICATION_ID = 7331
    }
}
