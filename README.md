# 🐱 Neko — Your AI Cat Assistant

> Built for #hackthekitty 2026

Neko reimagines your Android phone's notch as a live, AI-powered cat assistant —
part Dynamic Island, part cat health hub, part document vault. This repository
contains the Flutter app: a polished, Duolingo-inspired experience built on a
clean, feature-first architecture.

## ✨ Features

**Shipping in this build**
- **Animated splash & auth** — email/password and Google sign-in, with
  friendly, mapped error messages (never raw Firebase codes)
- **Seven-step onboarding** — a bouncy, staggered cat-setup wizard (name, breed,
  age, weight, coat color, activity) that saves to Firestore atomically
- **Home** — the signature amber screen with pill-shaped cat banners, an
  add-cat flow, and a custom bottom nav pill
- **Motion everywhere** — spring presses, staggered card entrances, and
  slide page transitions throughout

**Planned (architecture in place)**
- Individual cat profile screen, document upload + OCR, AI chat assistant,
  feeding tracker, and the notch overlay widget

## 🛠 Tech Stack

| Layer | Technology |
|---|---|
| UI | Flutter / Material 3 (Nunito via google_fonts) |
| State | Riverpod 2.x (`@riverpod` code generation) |
| Navigation | GoRouter 14.x (reactive auth redirect) |
| Models | Freezed + json_serializable |
| Backend | Firebase Auth + Cloud Firestore + Storage |
| Logging | `logger` (suppressed below warning in release) |

## 🚀 Setup

### Prerequisites
- Flutter (Dart 3.x), Android Studio or a device on API 26+
- A Firebase project
- A Hack Club AI API key (for upcoming AI features)

### Install
```bash
git clone https://github.com/dhruvin-sarkar/Neko
cd Neko
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

### Environment
```bash
cp .env.example .env
# add your HACKCLUB_API_KEY to .env
```

### Firebase
`google-services.json` is **not** committed (it's git-ignored). To run the app:
1. Create a Firebase project at console.firebase.google.com
2. Add an Android app with package `com.example.neko`
3. Download `google-services.json` into `android/app/`
4. Enable **Email/Password** and **Google** sign-in
5. Deploy the rules in this repo:
   ```bash
   firebase deploy --only firestore:rules,storage
   ```

### Run
```bash
flutter run
```

### Verify
```bash
flutter analyze   # zero issues
flutter test
```

## 🔒 Security
- Secrets live in `.env` (git-ignored); `.env.example` documents the keys
- `google-services.json` is git-ignored — judges add their own
- `firestore.rules` / `storage.rules` restrict every user to their own data,
  with cat-name validation and a 10MB image/PDF cap on uploads
- All sign-in errors are mapped to safe messages; no secrets are logged

## 🏗 Architecture
See [ARCHITECTURE.md](./ARCHITECTURE.md). Feature-first layout, Riverpod
repositories and notifiers, and a single GoRouter redirect as the source of
truth for auth gating.

## 👥 Team
- **Dhruvin Sarkar** — Onboarding, Home, Profiles, AI integration, Notch widget
- **Akshat** — Firebase Auth, startup screen, Settings, tutorial

## 📄 License
MIT — see [LICENSE](./LICENSE).
