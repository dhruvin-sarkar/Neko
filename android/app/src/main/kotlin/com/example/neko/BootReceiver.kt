package com.example.neko

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import androidx.core.content.ContextCompat

/// Restarts the Neko notch overlay after the device reboots.
///
/// Gated on two conditions so we never surprise the user: the "display over
/// other apps" permission must already be granted, and there must be persisted
/// ongoing activity to restore (written by NotchController). When both hold, it
/// starts [NotchBootService], which spins up a short-lived Flutter engine to
/// re-show the overlay.
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val action = intent.action ?: return
        if (action != Intent.ACTION_BOOT_COMPLETED &&
            action != Intent.ACTION_LOCKED_BOOT_COMPLETED &&
            action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }

        if (!canDrawOverlays(context) || !hasRestorableState(context)) return

        val serviceIntent = Intent(context, NotchBootService::class.java)
        ContextCompat.startForegroundService(context, serviceIntent)
    }

    private fun canDrawOverlays(context: Context): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)

    /// Mirrors NotchController: the restore payload lives under the Flutter
    /// SharedPreferences key "flutter.notch_restore".
    private fun hasRestorableState(context: Context): Boolean {
        val prefs = context.getSharedPreferences(
            "FlutterSharedPreferences",
            Context.MODE_PRIVATE,
        )
        return !prefs.getString("flutter.notch_restore", null).isNullOrEmpty()
    }
}
