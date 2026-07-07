<h1 align="center">
  <br>
  <img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/Neko.gif?raw=true" width=90%>
  <br>
  <br>
  Neko
  <br>
</h1>
<div align="center">
  
![Flutter](https://img.shields.io/badge/Made%20with-Flutter-2ec4b6)
![Firebase](https://img.shields.io/badge/Made%20with-Firebase-FFCA28)
 
Neko is the purr-fect (and honestly, the only) cat owner companion app you'll need. Feeding schedules or vet records, all wrapped up with an AI cat companion and an Apple-inspired Dynamic Island overlay, because your cat deserves nothing less pawsome.
 
### Overview
</div>
Neko was born out of pure cat-astrophe, juggling five different apps just to remember feeding times or vet visits something was actually wrong. So this app was created to bring it all together in one meow-nificent place, complete with an AI companion who talks back and guides you through it all.

<div align='center'>
  
## Features
 
</div>

<div align='center'>

  ### The Dynamic Island
 
</div>

Turns your phone's punch hole cutout into an always-on activity pill, Dynamic Island, but with claws.
 
- ***Music Playback*** album art, track info, playback controls
- ***Calls & Navigation*** incoming calls, active directions, no cat-terruptions missed
- ***Downloads & Notifications*** mirrors system notifications live
- ***Feeding Timers*** countdowns so mealtime's never a cat-astrophe
- ***Voice Assistant*** voice chat, right in the notch
- ***Dual-Engine Machina*** *(/ref)* separate overlay engine, keeps purring after app close

<div align='center'>

  ### Core Features
 
</div>

- ***AI Chat*** purr-sonal chats with full history
- ***Voice Recognition*** "Hey Neko" wake word, background listening
- ***Cat Profiles*** purr-files for as many cats as you can herd
- ***Document Management*** vet records, digital pet passports
- ***Photo Capture & Gallery*** fur-tographs, synced via Firebase
- ***Guided Onboarding*** Duolingo-style walkthrough
- ***Animations*** Lottie cat states + custom NekoMotion transitions
- ***Keyboard Cat*** a little easter egg, because why not
- ***Settings*** themes, sounds, feature toggles, Notch on/off
  
<table align="center">
  <tr>
    <th>Cat Profile</th>
    <th>Adding a New Cat</th>
  </tr>
  <tr>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/CatProfile.gif?raw=true" width=300px></td>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/NewCat.gif?raw=true" width=300px></td>
  </tr>
</table>
<table align="center">
  <tr>
    <th>AI Capabilities</th>
    <th>The Dynamic Island</th>
  </tr>
  <tr>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/AI%20Chat.gif?raw=true" width=300px></td>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/Notch.gif?raw=true" width=300px></td>
  </tr>
</table>
<table align="center">
  <tr>
    <th>Themes</th>
    <th>Voice Assistant</th>
  </tr>
  <tr>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/Themes.gif?raw=true" width=300px></td>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/readmeAssets/Notch.gif?raw=true" width=300px></td>
  </tr>
</table>

<div align='center'>
  
### Tech Stack
 
</div>

- ***Flutter*** the framework holding this whole cat-tastrophe together
- ***Firebase*** Authentication, Firestore, and Storage
- ***Android native overlay service*** dual-engine implementation powering the Dynamic Island
- ***Lottie*** in-app animations
- ***Material 3*** component system

<div align='center'>
  
## Prerequisites

</div>

Before you can let the cat out of the bag, make sure you have:
 
- ***Flutter SDK*** (3.x or later, Dart ≥ 3.11) — [installation guide](https://docs.flutter.dev/get-started/install)
- ***Dart SDK*** (included with Flutter)
- ***Android Studio***, with:
  - Android SDK (API level 26 or higher; the app's minSdk is 24)
  - An emulator or physical Android device — a physical device is strongly recommended for testing the Notch overlay
- ***A Firebase project***, with the following enabled:
  - Authentication (Email/Password + Google Sign-In)
  - Cloud Firestore

## Running the Project
 
1. Clone the repo, no cat-burglary required:
```sh
git clone https://github.com/dhruvin-sarkar/Neko.git
cd neko
```
2. Install dependencies:
```sh
flutter pub get
```
3. Add your config (see **Configuration** below): `android/app/google-services.json` and a `.env` file at the project root (copy `.env.example`).
4. Run the app on a connected device or emulator. Config is injected **at build time** via `--dart-define-from-file`, so it's never bundled as a readable file inside the APK:
```sh
flutter run --dart-define-from-file=.env
```
5. To build a release APK (Dart obfuscation on; keep the symbols directory out of version control — it's what decodes a release stack trace and must never ship):
```sh
flutter build apk --release --dart-define-from-file=.env \
  --obfuscate --split-debug-info=build/debug-symbols
```

> A build run **without** `--dart-define-from-file=.env` shows a clear "configuration missing" screen rather than crashing — that's expected, just add the flag.
 
## Configuration
 
A few things need to be set up before the app will actually purr to life. Copy `.env.example` to `.env` and fill it in — every value is injected at build time by the `--dart-define-from-file=.env` flag above (nothing is read from a bundled asset at runtime):
 
| Configuration | Purpose | Where to set it |
|---|---|---|
| `google-services.json` | Firebase project credentials for Android | Place in `android/app/` (gitignored) |
| Firebase values | Auth + Firestore (`FIREBASE_API_KEY`, `FIREBASE_PROJECT_ID`, app IDs, …) | In `.env`; see `.env.example` |
| `HACKCLUB_API_KEY` | Powers the AI chat and voice assistant — free at <https://ai.hackclub.com/dashboard> | In `.env` |
| `SEARCH_API_KEY` | *Optional.* In-app web-results list for "best…/which…" queries; without it, those offer a one-tap Google search instead | In `.env` |
| Google Sign-In | Required for Google auth | Enable in the Firebase console (Authentication → Sign-in method) and register your signing SHA-1 there. Email/Password works without this |
| Dynamic Island overlay permission | Enables the system-level overlay | Requested at runtime; toggle on/off in Settings (off by default) |
| Notification & microphone permissions | Notification mirroring + "Hey Neko" voice | Requested at runtime (both features off by default) |

## Trying the headline features

Both are **off by default** — each needs a sensitive permission, so the user opts in:

1. **Notch**: Settings → *Neko notch* → grant "Display over other apps" and Notification access. Play music or start a timer and watch the status bar.
2. **Hey Neko**: with the notch on, Settings → *Hey Neko voice* → grant the microphone. Say "Hey Neko" — a persistent notification shows whenever the mic is listening, on purpose.

## Security

- Firestore rules (`firestore.rules`): each user can only reach their own `users/{uid}` tree; everything else is default-deny.
- No secrets in the repo or the APK — config is injected at build time via `--dart-define-from-file`, never bundled as a readable asset. Path-traversal hardening on local storage, per-account chat isolation, a locked-down manifest (HTTPS-only, backup-excluded, unexported receivers), and R8 + Dart release obfuscation round out the security pass.
- Chat transcripts are stored per account and cleared on sign-out; app data is excluded from Android backup and device-to-device transfer.

<div align='center'>

# Thanks fur checking out Neko!
 
</div>
