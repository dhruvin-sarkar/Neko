# R8 rules for the release build (minify + shrink enabled in build.gradle.kts).
#
# Flutter's own R8 config already keeps the engine, the plugin registrant, and
# everything referenced from the AndroidManifest (MainActivity, the
# notification listener, BootReceiver, the overlay services). Only genuinely
# reflective gaps need rules here.

# Flutter's embedding references Play Core deferred-components classes that
# Neko doesn't ship; silence the missing-class warnings instead of failing.
-dontwarn com.google.android.play.core.**
