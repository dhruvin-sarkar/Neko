package com.example.neko

import android.app.Notification
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import com.istornz.live_activities.LiveActivityManager

/// Builds the Neko Notch system notification (Layer 2) from the data map that
/// [NotchController._syncSystemActivity] sends. One shared RemoteViews layout is
/// populated with a primary + secondary line per activity type — the keys here
/// mirror each `NotchActivity.toLiveActivityData()` on the Dart side.
class NekoLiveActivityManager(context: Context) : LiveActivityManager(context) {

    private val appContext: Context = context.applicationContext

    private val tapIntent: PendingIntent = PendingIntent.getActivity(
        appContext,
        0,
        Intent(appContext, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
        },
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
    )

    override suspend fun buildNotification(
        notification: Notification.Builder,
        event: String,
        data: Map<String, Any>
    ): Notification {
        val type = data["type"] as? String ?: "notification"
        val remoteViews = RemoteViews(appContext.packageName, R.layout.neko_notch_generic)

        val (primary, secondary) = when (type) {
            "music" -> (data.str("songTitle")) to (data.str("artistName"))
            "timer" -> data.str("label", "Timer") to formatTimer(data)
            "nav" -> data.str("instruction") to data.str("etaLabel")
            "call" -> data.str("callerName", "Unknown") to "Incoming Call"
            "workout" -> data.str("workoutType", "Workout") to data.str("durationLabel")
            "order" -> data.str("restaurantName") to data.str("statusLabel")
            "battery" -> data.str("title") to data.str("body")
            else -> data.str("title", "Neko") to data.str("body")
        }

        remoteViews.setTextViewText(R.id.neko_primary_text, primary)
        remoteViews.setTextViewText(R.id.neko_secondary_text, secondary)

        return notification
            .setSmallIcon(R.mipmap.ic_launcher) // TODO: swap for a monochrome cat glyph
            .setOngoing(true)
            .setContentIntent(tapIntent)
            .setStyle(Notification.DecoratedCustomViewStyle())
            .setCustomContentView(remoteViews)
            .setCustomBigContentView(remoteViews)
            .setPriority(Notification.PRIORITY_LOW)
            .setCategory(Notification.CATEGORY_STATUS)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .build()
    }

    private fun formatTimer(data: Map<String, Any>): String {
        val secs = (data["secondsLeft"] as? Number)?.toInt() ?: 0
        val h = secs / 3600
        val m = (secs % 3600) / 60
        val s = secs % 60
        return if (h > 0) String.format("%d:%02d:%02d", h, m, s)
        else String.format("%02d:%02d", m, s)
    }

    private fun Map<String, Any>.str(key: String, fallback: String = ""): String =
        (this[key] as? String) ?: fallback
}
