package com.example.neko

import android.app.Notification
import android.content.ComponentName
import android.graphics.Bitmap
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Base64
import java.io.ByteArrayOutputStream

/// Mirrors real system notifications and now-playing media into the notch.
/// Requires the user to grant notification access (Settings → Notification
/// access). Media is read from active MediaSessions rather than the media
/// notification itself.
class NekoNotificationListenerService : NotificationListenerService() {

    private var sessionManager: MediaSessionManager? = null
    private var activeController: MediaController? = null
    private var controllerCallback: MediaController.Callback? = null

    private val sessionsListener =
        MediaSessionManager.OnActiveSessionsChangedListener { controllers ->
            bindMediaController(controllers)
        }

    override fun onListenerConnected() {
        instance = this
        NotchBridge.listenerConnected = true
        try {
            val msm = getSystemService(MEDIA_SESSION_SERVICE) as MediaSessionManager
            sessionManager = msm
            val component = ComponentName(this, NekoNotificationListenerService::class.java)
            msm.addOnActiveSessionsChangedListener(sessionsListener, component)
            bindMediaController(msm.getActiveSessions(component))
        } catch (_: Exception) {
            // Media mirroring unavailable — notifications still work.
        }
    }

    override fun onListenerDisconnected() {
        instance = null
        NotchBridge.listenerConnected = false
        try {
            sessionManager?.removeOnActiveSessionsChangedListener(sessionsListener)
        } catch (_: Exception) {
        }
        detachController()
    }

    /// Re-emits the current live state on demand — called when the notch is
    /// switched on so already-playing music and in-progress calls/navigation
    /// appear immediately, without waiting for the next change event (media and
    /// notification callbacks are edge-triggered).
    fun resync() {
        try {
            val msm = sessionManager
                ?: (getSystemService(MEDIA_SESSION_SERVICE) as MediaSessionManager)
            val component = ComponentName(this, NekoNotificationListenerService::class.java)
            bindMediaController(msm.getActiveSessions(component))
        } catch (_: Exception) {
        }
        try {
            for (sbn in activeNotifications ?: emptyArray()) {
                val n = sbn.notification ?: continue
                // Only re-surface persistent activities (calls, navigation,
                // downloads); replaying every old transient notification would
                // flood the notch.
                if ((n.flags and Notification.FLAG_ONGOING_EVENT) == 0) continue
                emitNotification(sbn)
            }
        } catch (_: Exception) {
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        emitNotification(sbn)
    }

    private fun emitNotification(sbn: StatusBarNotification?) {
        sbn ?: return
        if (sbn.packageName == packageName) return
        val n = sbn.notification ?: return
        if ((n.flags and Notification.FLAG_GROUP_SUMMARY) != 0) return
        val extras = n.extras ?: return
        // Media notifications are surfaced via the session listener instead.
        if (extras.containsKey(Notification.EXTRA_MEDIA_SESSION)) return

        val ongoing = (n.flags and Notification.FLAG_ONGOING_EVENT) != 0

        // Navigation apps (Maps) post custom RemoteViews notifications that
        // often omit EXTRA_TITLE, so fall back through the other text fields and
        // finally the ticker / app name — otherwise turn-by-turn never shows.
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_TITLE_BIG)?.toString()
            ?: n.tickerText?.toString()
            ?: appLabel(sbn.packageName)
        if (title.isBlank()) return
        val body = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
            ?: ""

        // Category drives the typed presentation (call / navigation / …).
        val isMaps = sbn.packageName == "com.google.android.apps.maps"
        val category = when {
            isMaps -> "navigation"
            else -> n.category ?: ""
        }

        // Determinate progress (downloads, uploads, nav ETA bars).
        val progressMax = extras.getInt(Notification.EXTRA_PROGRESS_MAX, 0)
        val progressCur = extras.getInt(Notification.EXTRA_PROGRESS, 0)
        val indeterminate = extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE, false)
        val progress =
            if (progressMax > 0 && !indeterminate) {
                (progressCur.toDouble() / progressMax).coerceIn(0.0, 1.0)
            } else {
                -1.0
            }

        NotchBridge.send(
            applicationContext,
            mapOf(
                "kind" to "notification",
                "key" to sbn.key,
                "package" to appLabel(sbn.packageName),
                "title" to title,
                "body" to body,
                "category" to category,
                "ongoing" to ongoing,
                "progress" to progress,
            ),
        )
    }

    /// Human-readable app name (e.g. "WhatsApp") rather than a raw package id.
    private fun appLabel(packageName: String): String {
        return try {
            val pm = applicationContext.packageManager
            pm.getApplicationLabel(pm.getApplicationInfo(packageName, 0)).toString()
        } catch (_: Exception) {
            packageName
        }
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification?) {
        sbn ?: return
        NotchBridge.send(applicationContext, mapOf("kind" to "notificationRemoved", "key" to sbn.key))
    }

    private fun bindMediaController(controllers: List<MediaController>?) {
        val controller = controllers?.firstOrNull { it.playbackState != null }
            ?: controllers?.firstOrNull()
        if (controller == null) {
            detachController()
            NotchBridge.send(applicationContext, mapOf("kind" to "mediaStopped"))
            return
        }
        if (controller.sessionToken == activeController?.sessionToken) {
            emitMedia(controller)
            return
        }
        detachController()
        activeController = controller
        val callback = object : MediaController.Callback() {
            override fun onMetadataChanged(metadata: MediaMetadata?) = emitMedia(controller)
            override fun onPlaybackStateChanged(state: PlaybackState?) = emitMedia(controller)
            override fun onSessionDestroyed() {
                detachController()
                NotchBridge.send(applicationContext, mapOf("kind" to "mediaStopped"))
            }
        }
        controllerCallback = callback
        controller.registerCallback(callback)
        emitMedia(controller)
    }

    private fun detachController() {
        controllerCallback?.let { cb -> activeController?.unregisterCallback(cb) }
        controllerCallback = null
        activeController = null
    }

    private fun emitMedia(controller: MediaController) {
        val metadata = controller.metadata
        val state = controller.playbackState
        val title = metadata?.getString(MediaMetadata.METADATA_KEY_TITLE)
        if (title.isNullOrBlank()) return
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
            ?: metadata.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
            ?: ""
        val art = metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
            ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_ART)
            ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON)
        NotchBridge.send(applicationContext,
            mapOf(
                "kind" to "media",
                "title" to title,
                "artist" to artist,
                "playing" to (state?.state == PlaybackState.STATE_PLAYING),
                "position" to (state?.position ?: 0L),
                "duration" to metadata.getLong(MediaMetadata.METADATA_KEY_DURATION),
                "art" to encodeArt(art),
            ),
        )
    }

    /// Scales the album art down and returns it as a base64 JPEG so it can ride
    /// the JSON channel to the overlay. Empty string when there's no art.
    private fun encodeArt(bitmap: Bitmap?): String {
        bitmap ?: return ""
        return try {
            val max = 160
            val scale = max.toFloat() / maxOf(bitmap.width, bitmap.height)
            val scaled = if (scale < 1f) {
                Bitmap.createScaledBitmap(
                    bitmap,
                    (bitmap.width * scale).toInt().coerceAtLeast(1),
                    (bitmap.height * scale).toInt().coerceAtLeast(1),
                    true,
                )
            } else {
                bitmap
            }
            val out = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, 80, out)
            Base64.encodeToString(out.toByteArray(), Base64.NO_WRAP)
        } catch (_: Exception) {
            ""
        }
    }

    /// Performs a media transport action on the active session — the notch's
    /// play / pause / skip buttons route here.
    fun control(action: String) {
        val controls = activeController?.transportControls ?: return
        try {
            when (action) {
                "play" -> controls.play()
                "pause" -> controls.pause()
                "next" -> controls.skipToNext()
                "previous" -> controls.skipToPrevious()
            }
        } catch (_: Exception) {
        }
    }

    companion object {
        /// The live service instance, used by MainActivity to trigger a resync
        /// when the notch is switched on.
        @Volatile
        var instance: NekoNotificationListenerService? = null
    }
}
