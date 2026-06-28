# Neko

A cat companion app built for #hackthekitty 2026.

## What it does

Neko keeps everything about your cat in one warm, playful place. You onboard your
cat through a short guided flow — name, breed, coat colour, age, weight, and
activity — and the app builds a profile from it. Choosing your cat's coat colour
re-themes the entire app to match (12 themes drawn from real cat coats). From
Home you can open each cat's profile to see their stats and store documents
(vaccination records, passports) locally on device. A built-in assistant tab
answers cat-care questions, and Settings lets you switch themes at any time.

## Getting started

1. Clone the repo
2. `flutter pub get`
3. `dart run build_runner build --delete-conflicting-outputs`
4. Copy `.env.example` to `.env` and fill in your Firebase values and Hack Club AI key
5. Add your `android/app/google-services.json` from the Firebase console
6. Enable Email/Password and Google sign-in in Firebase Authentication
7. Publish the Firestore rules in `firestore.rules`
8. `flutter run`

## Requirements

- Flutter 3.x / Dart 3.x
- Android SDK 21+ (built and tested on a Pixel 8)
- A Firebase project with Firestore and Authentication enabled
- A Hack Club AI API key for the assistant tab (https://ai.hackclub.com)

## Architecture

- State management: Riverpod (with code generation)
- Routing: GoRouter
- Models: Freezed + json_serializable
- Local storage: Hive + path_provider (profile pictures, documents, preferences)
- Remote: Firebase Firestore (cat profiles) + Firebase Auth
- Animation: Lottie, flutter_staggered_animations, flutter_animate, and a custom
  spring-physics button (NekoButton)
- Theming: a single `NekoPalette`/`AppColors` engine; every widget reads theme
  tokens, so swapping the palette re-skins the whole app

## Theme system

Twelve coat-inspired themes — Ginger Tabby, Midnight Black, Snow White, Russian
Blue, Cream & Honey, Calico, Tortoiseshell, Siamese Dreams, Havana Espresso,
Silver Chinchilla, Lilac Whisper, and Tuxedo. The theme is chosen automatically
when you pick your cat's coat during onboarding, and can be changed any time in
Settings.

## Security

- Firestore rules restrict every read and write to the signed-in user's own
  `users/{uid}` tree; everything else is denied (see `firestore.rules`).
- No API keys are committed. Secrets load from `.env` at runtime (see
  `.env.example`); `.env` and `google-services.json` are gitignored.
- See `SECURITY_SCAN.md` for the security scan instructions and manual measures.

## Team

- Dhruvin — home screen, cat profiles, onboarding, animations, design system, assistant tab
- Akshat — auth, Firebase setup, settings, guided tutorial
