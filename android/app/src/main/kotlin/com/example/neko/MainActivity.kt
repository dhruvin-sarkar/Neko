package com.example.neko

import com.istornz.live_activities.LiveActivityManagerHolder
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register Neko's custom manager so the live_activities plugin builds our
        // styled notch notification (the out-of-app Layer 2).
        LiveActivityManagerHolder.instance = NekoLiveActivityManager(this)
    }
}
