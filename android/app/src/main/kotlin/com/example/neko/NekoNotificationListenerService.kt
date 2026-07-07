package com.example.neko

import android.app.Notification
import android.content.ComponentName
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.net.Uri
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Base64
import java.io.ByteArrayOutputStream
import java.net.HttpURLConnection
import java.net.URI

/// Mirrors real system notifications and now-playing media into the notch.
/// Requires the user to grant notification access (Settings → Notification
/// access). Media is read from active MediaSessions rather than the media
/// notification itself.
class NekoNotificationListenerService : NotificationListenerService() {

    private var sessionManager: MediaSessionManager? = null
    private var activeController: MediaController? = null
    private var controllerCallback: MediaController.Callback? = null

    // Album-art loaded from a URI (YouTube etc. ship art as an http/content URI,
    // not an embedded bitmap). Cached by URI so we fetch each thumbnail once —
    // `lastArtUri` is set on success AND failure so a dead URL isn't retried.
    private var lastArtUri: String? = null
    private var lastArtBitmap: Bitmap? = null
    private var downloadingArtUri: String? = null

    // Identifies the currently-playing track so a late background art download
    // for a track the user already skipped past is dropped, not re-emitted.
    private var currentTrackKey: String? = null

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
            // Already unregistered / listener access revoked — nothing to undo.
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
            // Media resync is best-effort; notifications below still resync.
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
            // activeNotifications can throw if the listener just disconnected;
            // the next posted notification repopulates the island anyway.
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

        // Calls: only surface an ANSWERED call. A ringing incoming call posts a
        // full-screen-intent / heads-up notification that Android itself makes
        // loud and prominent (there's no CallKit-style suppression on Android),
        // so our own notch card there would be redundant. Ringing is not ongoing;
        // the moment the call is answered the notification flips to ongoing and
        // the notch becomes the glanceable "still on a call" indicator.
        // (Caveat: relies on the app using the modern call-notification pattern —
        // correct for the native dialer; verify third-party VoIP apps on-device.)
        if (n.category == Notification.CATEGORY_CALL && !ongoing) return

        // Any ongoing Clock notification (timer / stopwatch / alarm) is a live
        // activity we want to surface, not a plain bell notification.
        val isClockActivity = sbn.packageName in CLOCK_PACKAGES && ongoing
        val timerEndsAt = n.`when`
        val isCountdown = isCountdown(extras, timerEndsAt, isClockActivity)

        val category = resolveCategory(n, sbn.packageName, ongoing, isCountdown, isClockActivity)
        val progress = resolveProgress(extras)
        // A live activity (turn-by-turn, an answered call, a countdown, a
        // download) is worth surfacing even when the app posts it via custom
        // RemoteViews with a blank EXTRA_TITLE — Google Maps navigation does
        // exactly that, and dropping it on an empty title is why a started route
        // never reached the notch. A plain, title-less notification is chrome.
        val isLive = category == "navigation" || category == "call" ||
            category == "timer" || (ongoing && progress >= 0.0)
        var title = resolveTitle(extras, n)
        if (title.isBlank()) {
            if (!isLive) return
            title = appLabel(sbn.packageName)
        }
        if (shouldIgnoreNotification(sbn.packageName, title, n.category)) return

        NotchBridge.send(
            applicationContext,
            mapOf(
                "kind" to "notification",
                "key" to sbn.key,
                "package" to appLabel(sbn.packageName),
                "packageId" to sbn.packageName,
                "title" to title,
                "body" to resolveBody(extras),
                "category" to category,
                "ongoing" to ongoing,
                "progress" to progress,
                "endsAtMs" to if (isCountdown) timerEndsAt else 0L,
            ),
        )
    }

    /// A count-down chronometer (the Clock app's timer, and most timer apps)
    /// exposes its end time through the notification's `when`. Detecting it
    /// lets a running timer show as a real Dynamic-Island countdown instead of
    /// a plain "Clock" notification: the standard chronometer flags, or a Clock
    /// activity whose `when` is in the future (some Clock apps drive the
    /// countdown via custom RemoteViews and never set the chronometer extras).
    private fun isCountdown(
        extras: Bundle,
        timerEndsAt: Long,
        isClockActivity: Boolean,
    ): Boolean {
        val showChrono = extras.getBoolean(Notification.EXTRA_SHOW_CHRONOMETER, false)
        val countDown = extras.getBoolean(Notification.EXTRA_CHRONOMETER_COUNT_DOWN, false)
        return (showChrono && countDown && timerEndsAt > 0L) ||
            (isClockActivity && timerEndsAt > System.currentTimeMillis())
    }

    /// Navigation apps (Maps) post custom RemoteViews notifications that often
    /// omit OR blank EXTRA_TITLE, so skip blank candidates and fall through the
    /// other text fields — otherwise a present-but-empty title short-circuits
    /// the chain and turn-by-turn never shows. Returns "" when no real text is
    /// found; the caller supplies the app name for a live activity and drops a
    /// plain notification that has none.
    private fun resolveTitle(extras: Bundle, n: Notification): String =
        extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.takeIf { it.isNotBlank() }
            ?: extras.getCharSequence(Notification.EXTRA_TITLE_BIG)?.toString()?.takeIf { it.isNotBlank() }
            ?: n.tickerText?.toString()?.takeIf { it.isNotBlank() }
            ?: ""

    private fun resolveBody(extras: Bundle): String =
        extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()
            ?: extras.getCharSequence(Notification.EXTRA_SUB_TEXT)?.toString()
            ?: ""

    /// Category drives the typed presentation (call / navigation / …).
    /// Turn-by-turn is only the *ongoing* notification from a nav app (or one
    /// that declares Android's navigation category). Gating the package match
    /// on `ongoing` keeps transient posts from those same apps (Maps "rate
    /// your visit", Waze promos) as normal, auto-dismissing notifications
    /// instead of a stuck turn-by-turn card.
    private fun resolveCategory(
        n: Notification,
        packageId: String,
        ongoing: Boolean,
        isCountdown: Boolean,
        isClockActivity: Boolean,
    ): String = when {
        // Countdown timer, or any other ongoing clock activity (stopwatch /
        // alarm / paused timer) — all shown with the timer treatment.
        isCountdown || isClockActivity -> "timer"
        n.category == "navigation" -> "navigation"
        ongoing && packageId in NAV_PACKAGES -> "navigation"
        else -> n.category ?: ""
    }

    /// Determinate progress (downloads, uploads, nav ETA bars); -1 when absent.
    private fun resolveProgress(extras: Bundle): Double {
        val progressMax = extras.getInt(Notification.EXTRA_PROGRESS_MAX, 0)
        val progressCur = extras.getInt(Notification.EXTRA_PROGRESS, 0)
        val indeterminate = extras.getBoolean(Notification.EXTRA_PROGRESS_INDETERMINATE, false)
        return if (progressMax > 0 && !indeterminate) {
            (progressCur.toDouble() / progressMax).coerceIn(0.0, 1.0)
        } else {
            -1.0
        }
    }

    /// Drops Android's overlay-permission nag and other system chrome that would
    /// otherwise expand the idle pill after a disable/re-enable cycle.
    private fun shouldIgnoreNotification(
        packageName: String,
        title: String,
        category: String?,
    ): Boolean {
        // A Clock timer/alarm is a wanted live activity even though the AOSP
        // Clock (com.android.deskclock) posts it as a service notification —
        // never drop it via the com.android.* service filter below.
        if (packageName in CLOCK_PACKAGES) return false
        if (packageName == "android" || packageName == "com.android.systemui") {
            return true
        }
        val lower = title.lowercase()
        if (lower.contains("displaying over") ||
            lower.contains("draw over") ||
            lower.contains("display over")
        ) {
            return true
        }
        // System/service posts from non-user apps (e.g. overlay FGS nags).
        val systemCategory = category == Notification.CATEGORY_SYSTEM ||
            category == Notification.CATEGORY_SERVICE
        val systemPackage = packageName.startsWith("com.android.") ||
            packageName.startsWith("android.")
        return systemCategory && systemPackage
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
        // Prefer the session that's actually playing (so YouTube wins over a
        // paused Spotify), then any session with playback state, then anything.
        val controller = controllers?.firstOrNull {
            it.playbackState?.state == PlaybackState.STATE_PLAYING
        }
            ?: controllers?.firstOrNull { it.playbackState != null }
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
        lastArtUri = null
        lastArtBitmap = null
    }

    private fun emitMedia(controller: MediaController) {
        val metadata = controller.metadata
        val state = controller.playbackState
        val title = metadata?.getString(MediaMetadata.METADATA_KEY_TITLE)
        if (title.isNullOrBlank()) return
        val artist = metadata.getString(MediaMetadata.METADATA_KEY_ARTIST)
            ?: metadata.getString(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
            ?: ""
        val playing = state?.state == PlaybackState.STATE_PLAYING
        val position = state?.position ?: 0L
        val duration = metadata.getLong(MediaMetadata.METADATA_KEY_DURATION)

        // Prefer an embedded bitmap; otherwise fall back to an art URI (YouTube,
        // Chrome, and others ship the thumbnail as an http/content URI instead
        // of a bitmap). URI art is fetched once, cached, and re-sent as an update.
        val bitmap = metadata.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
            ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_ART)
            ?: metadata.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON)
        val artUri = metadata.getString(MediaMetadata.METADATA_KEY_ALBUM_ART_URI)
            ?: metadata.getString(MediaMetadata.METADATA_KEY_ART_URI)
            ?: metadata.getString(MediaMetadata.METADATA_KEY_DISPLAY_ICON_URI)

        val trackKey = "$title|$artist"
        currentTrackKey = trackKey

        val immediate = bitmap
            ?: if (artUri != null && artUri == lastArtUri) lastArtBitmap else null

        sendMedia(
            title,
            artist,
            controller.packageName,
            playing,
            position,
            duration,
            immediate,
        )

        // Only fetch a URI we haven't tried yet (lastArtUri is set on success and
        // failure), so a dead/404 thumbnail isn't re-downloaded on every tick.
        if (bitmap == null && artUri != null && artUri != lastArtUri) {
            fetchArt(artUri) { loaded ->
                lastArtUri = artUri
                lastArtBitmap = loaded
                // Drop a late download for a track we've already skipped past.
                if (loaded != null && currentTrackKey == trackKey) {
                    sendMedia(
                        title,
                        artist,
                        controller.packageName,
                        playing,
                        position,
                        duration,
                        loaded,
                    )
                }
            }
        }
    }

    private fun sendMedia(
        title: String,
        artist: String,
        packageId: String,
        playing: Boolean,
        position: Long,
        duration: Long,
        art: Bitmap?,
    ) {
        NotchBridge.send(
            applicationContext,
            mapOf(
                "kind" to "media",
                "title" to title,
                "artist" to artist,
                "packageId" to packageId,
                "playing" to playing,
                "position" to position,
                "duration" to duration,
                "art" to encodeArt(art),
            ),
        )
    }

    /// Loads album art from a URI: content/file synchronously, http(s) on a
    /// background thread. Best-effort; the callback simply never fires on
    /// failure and the island keeps its icon fallback. Guarded so the same
    /// remote thumbnail isn't downloaded repeatedly.
    private fun fetchArt(uri: String, cb: (Bitmap?) -> Unit) {
        if (uri == downloadingArtUri) return
        val parsed = try {
            Uri.parse(uri)
        } catch (_: Exception) {
            return
        }
        when (parsed.scheme) {
            "content", "file", "android.resource" -> {
                try {
                    contentResolver.openInputStream(parsed)?.use {
                        cb(BitmapFactory.decodeStream(it))
                    }
                } catch (_: Exception) {
                    // Unreadable local art — the island keeps its icon fallback.
                }
            }
            "http", "https" -> {
                downloadingArtUri = uri
                Thread {
                    val bmp = try {
                        // URI.toURL() replaces the deprecated URL(String) ctor.
                        val conn = (URI(uri).toURL().openConnection() as HttpURLConnection)
                            .apply {
                                connectTimeout = 4000
                                readTimeout = 4000
                                doInput = true
                            }
                        conn.inputStream.use { BitmapFactory.decodeStream(it) }
                    } catch (_: Exception) {
                        null
                    }
                    // Only clear the guard if it's still ours — a newer track's
                    // in-flight download must keep its own guard.
                    if (downloadingArtUri == uri) downloadingArtUri = null
                    cb(bmp)
                }.start()
            }
        }
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
            // Session died between tap and dispatch — the next media event
            // rebinds; a lost button press is the correct outcome here.
        }
    }

    companion object {
        /// The live service instance, used by MainActivity to trigger a resync
        /// when the notch is switched on.
        @Volatile
        var instance: NekoNotificationListenerService? = null

        /// Turn-by-turn navigation apps that don't always set the navigation
        /// category on their ongoing notification.
        private val NAV_PACKAGES = setOf(
            "com.google.android.apps.maps",
            "com.google.android.apps.mapslite",
            "com.waze",
        )

        /// Clock / timer apps whose running countdown should show as a timer.
        private val CLOCK_PACKAGES = setOf(
            "com.google.android.deskclock",
            "com.android.deskclock",
            "com.sec.android.app.clockpackage", // Samsung
            "com.oneplus.deskclock",
            "com.oplus.alarmclock", // Oppo/Realme
            "com.miui.clock", // Xiaomi
            "com.coloros.alarmclock",
        )
    }
}
