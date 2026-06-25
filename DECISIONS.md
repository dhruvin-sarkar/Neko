# Autonomous Decisions

One line per significant judgment call made while building, for review.

- Context7/MCP was not actually available in this environment, so the GoRouter + Riverpod redirect pattern was validated via web search and the `dart-flutter-patterns` skill instead.
- Skill files live outside the workspace sandbox; `dart-flutter-patterns` was read via shell, the rest applied from knowledge plus the explicit design spec.
- Kept Firebase on the v2/v4 line per instruction; added `firebase_storage ^11.6.x` as the compatible version.
- Treated STARTING_PROMPT design tokens as source of truth over UI_GUIDELINES where they conflicted (white onboarding, `#F5C275` home, coral, Nunito).
- Auth precedes onboarding (per the explicit redirect rules); Akshat's Hero "welcome" craft was folded into the onboarding Step 0 welcome rather than a separate route.
- `/auth/login` is the unauthenticated landing; its "New to Neko? Get started" links to register (honors "not authed → /auth/login").
- Used flat GoRoutes instead of a ShellRoute, because the home screen owns its custom nav pill per the design (a shell would duplicate chrome).
- Dropped the "personalities" concept from the old onboarding; it is not in the Firestore schema.
- Derived the user display name from the email local-part on email registration (onboarding collects the cat's name, not the owner's); Google sign-in uses the real name.
- `dailyCalorieTarget` is computed at save time from weight and activity (RER × activity factor), giving the home calorie features real data later.
- Banner stagger uses stable `ValueKey(cat.id)` so the entrance never replays on Firestore updates, instead of a separate "hasAnimated" flag.
- The flat "Duolingo depth" button shadow lives in the custom button widgets (zero-blur offset shadow), since Material elevation cannot express it.
- Generated `*.g.dart` / `*.freezed.dart` files are committed so the project compiles for judges without a build_runner step.
- Local, ephemeral view state (focus glow, press scale, password visibility) is driven by listenables/controllers, keeping Riverpod for app state only.
- `shared_preferences` was removed once the SharedPreferences-based onboarding/login flags were replaced by Firestore + Firebase auth state.
- The sleeping-cat and logo assets are 1×1 placeholders; the add-cat section falls back to a Material icon until real art is dropped in.

## Session 2 — polish pass (flutter_animate, chiclet, audio, haptics, rive)

- `chiclet ^0.0.5` does not exist; used `^1.2.1`. Verified its real API from the pub cache (`backgroundColor`, `buttonColor`, `buttonHeight`, `borderRadius`, `disabledBackgroundColor`) and centralized it in one `NekoPrimaryButton` wrapper.
- Migrated every animation to `flutter_animate`; deleted `springs.dart` and `staggered_entrance.dart`. Manual `AnimationController`/`SpringSimulation` are gone — spring feel now comes from `Curves.elasticOut` (per the spec's guidance, since flutter_animate has no built-in spring).
- Primary CTAs (Get started / Continue / Let's go / Sign in / Create account) are now `ChicletAnimatedButton` via `NekoPrimaryButton`. `NekoPillButton` is kept for secondary actions (sign out, retry) and the error card.
- Exactly two justified `setState` usages remain: local press state in `NekoPillButton` and `Pressable` (ephemeral, not app state). Everything else is listenable/controller/`flutter_animate` target driven.
- `SoundService` ships with placeholder (invalid) MP3s; `init()` is resilient — pools stay null on load failure and playback is a silent no-op. Drop real CC0 clips into `assets/sounds/` to enable sound. Haptics work regardless.
- `NekoMascot` scaffolds Rive via `RiveFile.asset` + `FutureBuilder`, falling back to the icon when the placeholder `neko.riv` fails to parse. Wiring a `StateMachineController` is deferred until a real `.riv` (with known state-machine names) exists.
- Added `SplashGate` (800ms minimum) so the splash never flashes; the router holds on `/splash` until both auth resolves and the gate elapses.
- Home banner stagger uses `flutter_animate` per-item delay with stable `ValueKey(cat.id)` (no `_hasAnimated` flag needed — element identity prevents replay on Firestore updates).
- Home rebuilt as `CustomScrollView` + `SliverList.builder` for banners (Phase 6 lazy-list rule); added a friendly empty-cats state.
- The loading-button unit test became a disabled-button test, because a `CircularProgressIndicator` never settles under `pumpAndSettle`; the `_interactive` guard it verifies is identical.

## Session 3 — home/profile/settings shell

- Home and Settings are now a persistent `StatefulShellRoute.indexedStack` (`MainShell`) sharing one bottom nav pill; splash, auth, onboarding, and cat-profile detail are pushed over the shell as full screens.
- `NekoNavPill` restyled to match the reference: a white pill where the active tab sits in a filled black circle (was a black pill with dimmed icons). It now reports taps via `onSelect(index)` → `goBranch`.
- Built the real cat profile detail screen (large avatar, name, breed, and Age/Weight/Activity/Daily-target stat cards) backed by a new `catById` family provider; handles loading and not-found states.
- The add-cat "+" now overlays the sleeping-cat mat on its lower-left (whole illustration tappable), matching the reference, with a Material-icon mat fallback until real art lands.
- Per the user, the reference image is inspiration only; colors follow the UI_GUIDELINES tokens (amber home, coral primary, dark-teal banners, Nunito) rather than copying the mockup's exact palette.
