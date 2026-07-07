<h1 align="center">
  <br>
  <img src="https://github.com/dhruvin-sarkar/Neko/blob/main/Documentation/readmeAssets/Neko.gif?raw=true" width=90%>
  <br>
  <br>
  Neko
  <br>
</h1>

<div align="center">

[![Made with Flutter](https://img.shields.io/badge/Made%20with-Flutter-2ec4b6?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-%E2%89%A5%203.11-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Made%20with-Firebase-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android-3ddc84?logo=android&logoColor=white)](#prerequisites)
[![Design](https://img.shields.io/badge/Design-Material%203-757575?logo=materialdesign&logoColor=white)](https://m3.material.io)

Neko is the purr-fect (and honestly, the only) cat owner companion app you'll need. Feeding schedules or vet records, all wrapped up with an AI cat companion and an Apple-inspired Dynamic Island overlay, because your cat deserves nothing less pawsome.

</div>



## Contents

- [Overview](#overview)
- [Features](#features)
  - [The Dynamic Island](#the-dynamic-island)
  - [Core Features](#core-features)
- [Tech Stack](#tech-stack)
- [Architecture at a glance](#architecture-at-a-glance)
- [Prerequisites](#prerequisites)
- [Running the Project](#running-the-project)
- [Configuration](#configuration)
- [Trying the headline features](#trying-the-headline-features)
- [Security](#security)

<br clear="all"/>

## Features

### The Dynamic Island

Turns your phone's punch hole cutout into an always-on activity pill, Dynamic Island.

<table align="center">
  <tr><th>Live activity</th><th>What it surfaces</th></tr>
  <tr><td><b>Music Playback</b></td><td>Album art, track info, playback controls</td></tr>
  <tr><td><b>Calls &amp; Navigation</b></td><td>Incoming calls, active directions, no interruptions missed</td></tr>
  <tr><td><b>Downloads &amp; Notifications</b></td><td>Mirrors system notifications live</td></tr>
  <tr><td><b>Feeding Timers</b></td><td>Countdowns so mealtime's never a cat-astrophe</td></tr>
  <tr><td><b>Voice Assistant</b></td><td>Voice chat, right in the notch</td></tr>
</table>

```mermaid
stateDiagram-v2
    [*] --> Idle: notch enabled
    Idle --> Compact: activity arrives
    Compact --> Expanded: tap / swipe down
    Expanded --> Compact: swipe up
    Compact --> Minimized: after a short peek
    Minimized --> Compact: tap to bring back
    Compact --> Idle: activity ends
    note right of Minimized
      Music and alerts recede after their peek.
      Live activities — maps, timers, calls —
      stay pinned until you dismiss them.
    end note
```

### Core Features

<table align="center">
  <tr><th>Feature</th><th>What it does</th></tr>
  <tr><td><b>AI Chat</b></td><td>Purr-sonal chats with full history</td></tr>
  <tr><td><b>Voice Recognition</b></td><td>"Hey Neko" wake word, background listening</td></tr>
  <tr><td><b>Cat Profiles</b></td><td>Purr-files for as many cats as you can herd</td></tr>
  <tr><td><b>Document Management</b></td><td>Vet records, digital pet passports</td></tr>
  <tr><td><b>Photo Capture &amp; Gallery</b></td><td>Fur-tographs, synced via Firebase</td></tr>
  <tr><td><b>Guided Onboarding</b></td><td>Duolingo-style walkthrough</td></tr>
  <tr><td><b>Animations</b></td><td>Lottie cat states + custom NekoMotion transitions</td></tr>
  <tr><td><b>Settings</b></td><td>Themes, sounds, feature toggles, Notch on/off</td></tr>
</table>

<table align="center">
  <tr>
    <th>Cat Profile</th>
    <th>Adding a New Cat</th>
  </tr>
  <tr>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/Documentation/readmeAssets/CatProfile.gif?raw=true" width=300px></td>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/Documentation/readmeAssets/NewCat.gif?raw=true" width=300px></td>
  </tr>
</table>
<table align="center">
  <tr>
    <th>AI Capabilities</th>
    <th>The Dynamic Island</th>
  </tr>
  <tr>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/Documentation/readmeAssets/AI%20Chat.gif?raw=true" width=300px></td>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/Documentation/readmeAssets/Notch.gif?raw=true" width=300px></td>
  </tr>
</table>
<table align="center">
  <tr>
    <th>Themes</th>
    <th>Voice Assistant</th>
  </tr>
  <tr>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/Documentation/readmeAssets/Themes.gif?raw=true" width=300px></td>
    <td><img src="https://github.com/dhruvin-sarkar/Neko/blob/main/Documentation/readmeAssets/Voice.gif?raw=true" width=300px></td>
  </tr>
</table>

## Tech Stack

<table align="center">
  <tr><th>Technology</th><th>Role</th></tr>
  <tr><td><b>Flutter</b></td><td>The framework holding this whole cat-tastrophe together</td></tr>
  <tr><td><b>Firebase</b></td><td>Authentication, Firestore, and Storage</td></tr>
  <tr><td><b>Android native overlay service</b></td><td>Dual-engine implementation powering the Dynamic Island</td></tr>
  <tr><td><b>Lottie</b></td><td>In-app animations</td></tr>
  <tr><td><b>Material 3</b></td><td>Component system</td></tr>
</table>

## Architecture at a glance

The Flutter app is the main surface; a native Android overlay service draws the Dynamic Island and keeps it alive over other apps, talking to Flutter over a platform channel. Firebase is the shared backend for auth, data, and files.

```mermaid
flowchart LR
    You([" You "])

    subgraph app[" Flutter App"]
        UI["Chat · Profiles<br/>Onboarding · Settings"]
        Voice["Hey Neko<br/>wake word + STT"]
    end

    subgraph native[" Android Native"]
        Overlay["Dynamic Island<br/>overlay engine"]
        Listener["Notification &<br/>media listener"]
    end

    subgraph cloud[" Firebase"]
        Auth["Auth"]
        Store["Firestore"]
        Files["Storage"]
    end

    AI[" AI proxy"]

    You --> UI
    You -.->|"Hey Neko"| Voice
    Voice --> AI
    UI -->|platform channel| Overlay
    Listener --> Overlay
    UI --> Auth
    UI --> Store
    UI --> Files

    classDef appcls fill:#ff6f61,stroke:#e0523f,color:#ffffff
    classDef natcls fill:#2ec4b6,stroke:#1f9c90,color:#ffffff
    classDef cloudcls fill:#f4a340,stroke:#d4842a,color:#ffffff
    classDef aicls fill:#7c6bff,stroke:#5f4fd6,color:#ffffff
    class UI,Voice appcls
    class Overlay,Listener natcls
    class Auth,Store,Files cloudcls
    class AI aicls
```

Ask it something out loud and the answer comes back up top — not three taps deep in a menu:

```mermaid
sequenceDiagram
    actor You
    participant Neko as Neko app
    participant STT as Speech-to-text
    participant AI as AI assistant
    participant Notch as Dynamic Island
    You->>Neko: "Hey Neko, when did I last feed her?"
    Neko->>STT: wake word detected
    STT-->>Neko: transcript
    Neko->>AI: question + cat context
    AI-->>Neko: answer
    Neko->>Notch: surface the reply
    Notch-->>You: glanceable answer
```

## Prerequisites

Before you can let the cat out of the bag, make sure you have:

- **Flutter SDK** (3.x or later, Dart ≥ 3.11) — [installation guide](https://docs.flutter.dev/get-started/install)
- **Dart SDK** (included with Flutter)
- **Android Studio**, with:
  - Android SDK (API level 26 or higher; the app's minSdk is 24)
  - An emulator or physical Android device

> [!IMPORTANT]
> A physical Android device is strongly recommended for testing the Notch overlay — it depends on OS-level draw-over-other-apps behaviour that emulators don't reproduce reliably.

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
3. Add your config (see [Configuration](#configuration) below): `android/app/google-services.json` and a `.env` file at the project root (copy `.env.example`).
4. Run the app on a connected device or emulator:
   ```sh
   flutter run --dart-define-from-file=.env
   ```

> [!TIP]
> Config is injected **at build time** via `--dart-define-from-file`, so it's never bundled as a readable file inside the APK. Always pass the flag — without it, the app starts without its configuration.

## Configuration

A few things need to be set up before the app will actually purr to life. Copy `.env.example` to `.env` and fill it in — every value is injected at build time by the `--dart-define-from-file=.env` flag above (nothing is read from a bundled asset at runtime):

<table align="center">
  <tr><th>Configuration</th><th>Purpose</th><th>Where to set it</th></tr>
  <tr><td><code>google-services.json</code></td><td>Firebase project credentials for Android</td><td>Place in <code>android/app/</code> (gitignored)</td></tr>
  <tr><td><code>HACKCLUB_API_KEY</code></td><td>Powers the AI chat and voice assistant — free at <a href="https://ai.hackclub.com/dashboard">ai.hackclub.com/dashboard</a></td><td>In <code>.env</code></td></tr>
  <tr><td>Google Sign-In</td><td>Required for Google auth</td><td>Enable in the Firebase console (Authentication → Sign-in method) and register your signing SHA-1 there. Email/Password works without this</td></tr>
  <tr><td>Dynamic Island overlay permission</td><td>Enables the system-level overlay</td><td>Requested at runtime; toggle on/off in Settings (off by default)</td></tr>
  <tr><td>Notification &amp; microphone permissions</td><td>Notification mirroring + "Hey Neko" voice</td><td>Requested at runtime (both features off by default)</td></tr>
</table>

## Trying the headline features

> [!NOTE]
> Both are **off by default** — each needs a sensitive permission, so the user opts in.

1. **Notch**: Settings → *Neko notch* → grant "Display over other apps" and Notification access. Play music or start a timer and watch the status bar.
2. **Hey Neko**: with the notch on, Settings → *Hey Neko voice* → grant the microphone. Say "Hey Neko" — a persistent notification shows whenever the mic is listening, on purpose.

## Security

> [!NOTE]
> No secrets in the repo or the APK — config is injected at build time via `--dart-define-from-file`, never bundled as a readable asset.

- **Firestore rules** (`firestore.rules`): each user can only reach their own `users/{uid}` tree; everything else is default-deny.
- **Hardening**: path-traversal hardening on local storage, per-account chat isolation, a locked-down manifest (HTTPS-only, backup-excluded, unexported receivers), and R8 + Dart release obfuscation round out the security pass.
- **Data handling**: chat transcripts are stored per account and cleared on sign-out; app data is excluded from Android backup and device-to-device transfer.

<div align='center'>

# Thanks fur checking out Neko!

</div>
