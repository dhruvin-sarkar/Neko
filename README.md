# Neko 🐾

**Your phone's notch becomes a cat.** Neko is a cat-care companion app for Android that reimagines the camera cutout as a Dynamic-Island-style live surface — music, calls, navigation, timers, and a voice-activated AI assistant all live up top, styled as a cat that runs your household's feline affairs.

Built in Flutter for **#hackthekitty 2026** by Dhruvin & Akshat.

## What it does

- **The Neko notch** — a true draw-over-other-apps overlay (its own Flutter engine, survives the app closing) that mirrors live activities into the status-bar area: now-playing music with transport controls, ongoing calls, turn-by-turn navigation, running timers with live countdowns, downloads, and notifications. Tap to expand, drag to cycle, long-press to jump to the source app.
- **Hey Neko voice** — say *"Hey Neko"* (even with the app backgrounded, via a microphone foreground service) and the notch becomes an AI listening surface. Ask anything cat-related; answers stream into the island. Results-style questions ("best kitten food…") return tappable web results.
- **Cat profiles** — each cat gets a profile (breed, age, weight, activity, daily calorie target) whose **coat color re-themes the entire app** to one of twelve palettes.
- **Neko AI chat** — a cat-personality assistant (Hack Club AI) that knows your cats by name and tailors advice to them. Attach a photo of a plant/food for a cautious **safety verdict** (SAFE / CAUTION / DANGER).
- **Documents** — vaccination cards, passports, and vet records stored on-device.
- **Feeding timer** — a feeding countdown that lives in the notch.
- **First-run guided tour** — coach-marks across Home, a cat profile, and Settings.

## Setup

Prerequisites: a recent **Flutter stable** (Dart SDK ≥ 3.11), an Android device/emulator (**Android 7.0+**, minSdk 24). The notch is Android-only by nature.

**1. Firebase config** — `android/app/google-services.json` is gitignored. If it's missing from your copy (e.g. a fresh clone), add your own Firebase Android app's file there. The submission ZIP ships with it in place.

**2. Environment** — copy `.env.example` to `.env` and fill in:

- the Firebase values (from your Firebase project settings),
- `HACKCLUB_API_KEY` — free at <https://ai.hackclub.com/dashboard> (powers the AI chat + voice answers),
- `SEARCH_API_KEY` — optional; without it, results-style queries offer a one-tap Google search instead of an in-app list.

Secrets are injected **at build time** and never ship inside the APK as readable files:

```sh
flutter pub get
flutter run --dart-define-from-file=.env          # debug, on a connected device

# release build (Dart obfuscation on; keep the symbols dir out of the repo —
# it's what decodes a release stack trace, and must never ship):
flutter build apk --release --dart-define-from-file=.env \
  --obfuscate --split-debug-info=build/debug-symbols
```

A build made without the flag shows a clear "configuration missing" screen rather than crashing.

**3. Sign in** — register with any email + password (6+ chars) or use Google Sign-In, then follow onboarding to add your first cat.

## Trying the headline features

Both are **off by default** (deliberate — each needs a sensitive permission):

1. **Notch**: Settings → *Neko notch* → grant "Display over other apps" and Notification access. Play some music or start a timer and watch the status bar.
2. **Hey Neko**: with the notch on, Settings → *Hey Neko voice* → grant the microphone. Say "Hey Neko" — a persistent notification is shown whenever the mic is listening, on purpose.

## Security

- Firestore rules (`firestore.rules`): each user can only reach their own `users/{uid}` tree; everything else is default-deny.
- No secrets in the repo or the APK — see `SECURITY_FIXES.md` for the full Aikido remediation log (path-traversal hardening, per-account chat isolation, locked-down manifest, R8 release obfuscation, and more).
- Chat transcripts are stored per account and cleared on sign-out; app data is excluded from Android backup and device-to-device transfer.

## Docs

- `docs/AI_INTEGRATION.md` — Hack Club AI integration patterns
- `docs/NOTCH_IMPLEMENTATION.md` — how the overlay engine + activity pipeline work
- `SECURITY_FIXES.md` — security audit findings and fixes
