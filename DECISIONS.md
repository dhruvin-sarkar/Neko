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

## Session 4 — cat photo + richer profile

- Added an optional cat-photo step to onboarding (now 7 question steps; photo is step 2, right after the name). It uses `image_picker` (camera or gallery) via an `ImagePickerService` that returns a path or null (failures logged, never thrown).
- Photo upload is best-effort and wired end to end: photo path lives in the onboarding draft → on final save the `OnboardingRepository` uploads it to `users/{uid}/cats/{catId}/avatar.jpg`, stores the download URL as `photoUrl`, and the existing `CatAvatar` renders it on the banner and profile. A failed upload still saves the cat (no photo) rather than blocking onboarding.
- Cat profile detail screen fleshed out: avatar, name, breed, Age/Weight/Activity/Daily-target stat cards, and a Documents section with a "coming soon" upload affordance — deliberately reserving the bottom area for the future document feature.
- Nav pill active tab now highlights in coral (brand accent) on a white pill, rather than black — ties the navigation to the app's primary color.
- No Android manifest changes needed: `image_picker` ships its own FileProvider and uses the system photo picker (no runtime storage permission on modern Android); Storage rules already permit image uploads under the user's path.

## Session 5 — Failsafes, preset avatars, profile editing, document uploads

- Re-entrancy failsafes across the flow: `AuthController` methods and `OnboardingNotifier.save()` now early-return while a previous action is in flight (`isLoading`/`isSaving` guards), so double-taps can't fire duplicate sign-ins or duplicate cat writes. Async controllers (`ProfileEditController`, `DocumentActionController`) apply the same `state.isLoading` guard.
- Preset avatars: when the user skips taking/uploading a photo ("Maybe later"), the photo step opens `AvatarPickerSheet` — a grid of six bundled presets (`avatar_1`..`avatar_6`). The chosen id is stored on the draft as `avatarPreset` and persisted on `CatProfile`. Photo and preset are mutually exclusive: `setPhotoPath` clears `avatarPreset` and vice-versa, so "Remove" cleanly resets either. `CatAvatar` resolution order is photoUrl → preset asset → coat-color circle, and every asset falls back via `errorBuilder`, so the placeholder PNGs (1×1 for now) never crash the UI. The `assets/images/avatars/` dir is registered in pubspec.
- Profile editing: tapping a cat banner opens the detail screen, which now has an Edit action (`/profile/:catId/edit`). `EditCatScreen` pre-fills from the live profile and saves via `ProfileEditController` → `ProfileRepository.update()` (never overwrites `id`/`createdAt`). The daily calorie target is recomputed on save using the shared `CalorieCalculator.dailyTarget()` (extracted from `OnboardingNotifier` so onboarding and editing stay in sync). The edit form uses local `setState` for ephemeral field state only (text controllers + breed/coat/activity dropdown selections) — justified view state, not domain state.
- Document uploads: the Documents section on the profile lists a cat's stored documents (Firestore `users/{uid}/cats/{catId}/documents`) and supports add/delete. Flow: pick a file (`file_picker`) → name it and choose a type (passport/vaccination/microchip/license/other) in `UploadDocumentSheet` → upload to Storage and record metadata. Deletes confirm first and tolerate a missing Storage object (metadata removal still succeeds). All errors surface as snackbars via `AsyncError` listeners; repositories throw `AppException` only.
- `file_picker` needs no Android manifest changes — it uses the system document picker (Storage Access Framework), so no runtime storage permission is required.

## Session 5 (cont.) — Full-flow audit & hardening

Walked the whole flow (cold launch → splash gate → auth → onboarding → home → profile → edit → documents → logout) looking for ways to break or fool it. Findings and outcomes:

**Verified sound (no change needed):**
- Auth gating is centralized in `RouterNotifier.redirect`; no screen self-navigates on auth. The redirect holds on splash until (a) the 800ms gate elapses, (b) auth resolves, and (c) onboarding status resolves — so there's never a flash or a premature route.
- Logout is race-safe: `catProfiles`, `catById`, `documents`, and `onboardingComplete` all watch `authStateChanges` first and return empty/false streams when signed out, so they drop their dependency on `currentUser` (which throws when signed out) before it can error. Logging out cleanly streams home/profile to empty and the redirect lands on login.
- Onboarding completion is not bounced back: the atomic batch write flips `onboardingComplete` with Firestore latency compensation emitting the new value locally before `commit()` resolves, so `context.go(home)` after `save()` sees `complete == true`. The `/onboarding` route stays intentionally reachable so a returning user can add another cat (Home "+" calls `reset()` then pushes it).
- Double-save/double-submit guarded everywhere via `isLoading`/`isSaving` early-returns.
- Pickers (image + file) never throw into the UI — cancel or failure returns `null`. Avatar/photo upload is best-effort and never blocks the cat save. Document delete tolerates a missing Storage object.
- Offline: Firestore's cached `onboardingComplete` keeps a returning user out of a redundant onboarding loop; a save attempted offline fails with a friendly message rather than a partial write.

**Hardened this pass:**
- `EditCatScreen` no longer reads the cat once in `initState` (which stranded on a misleading "can't find that cat" if the profile list hadn't loaded yet — e.g. deep link or hot restart on the edit route). It now resolves the cat reactively, shows a spinner while the list is still loading, fills the form once via `_initFrom` (idempotent), and only shows "not found" when the list has loaded and the cat genuinely isn't there.
- Sign-out is now guarded by a confirmation dialog (prevents an accidental one-tap logout) and surfaces failures via a snackbar through an `authController` `AsyncError` listener (previously a failed sign-out was silent and left the user signed in with no feedback).

## Session 5 (cont.) — Document viewing

- Tapping a document tile now opens it in the device's default viewer/browser via `url_launcher` (`LaunchMode.externalApplication`) against the stored Firebase download URL. The tile uses the shared `Pressable` for the same springy press feel as the cat banners; the delete icon button keeps its own tap target.
- Chose `url_launcher` over bundling an in-app PDF/image viewer: the download URLs are already https and self-authenticating (token in URL), so handing off to the OS viewer is the lightest robust option and handles every file type (PDF/JPG/PNG/HEIC/WEBP) for free.
- Failure handling: a malformed URL or a failed launch is logged and surfaced as a snackbar ("We couldn't open that document.") — never an unhandled exception.
- Android 11+ package visibility: added an `<intent>` for `VIEW`/`https` to the manifest's existing `<queries>` block so the launch resolves in release builds. No new runtime permissions.

## Session 5 (cont.) — Cohesion & polish pass

Filled the remaining gaps to make the current scope feel like a finished product:

- **Cat deletion (completes CRUD).** You could create (onboarding), read (detail), and update (edit) a cat but not remove one. Added a "Remove this cat" action at the bottom of the edit screen, behind a confirmation dialog. `ProfileRepository.delete()` removes the cat's `documents` subcollection records and the cat document in a single atomic batch, then best-effort deletes the cat's Storage folder (avatar + document files via `listAll`) — Storage failures are logged, never surfaced, since the metadata is already gone. After a delete the screen routes to Home (the detail screen would otherwise show "not found"). If it was the last cat, Home shows its empty state with the add-cat affordance (onboarding stays complete, so the user isn't dumped back into onboarding).
- **Settings, fleshed out.** Was just an email line + sign-out. Now leads with an account card (monogram avatar from the display name/email, name, email), an "About Neko" card (name, tagline, version), and the sign-out button, all with the staggered fade/slide intro used elsewhere. App metadata lives in `lib/app/app_info.dart` (`AppInfo.version` kept in sync with pubspec) rather than scattered string literals.
- **Profile detail** now shows an "Added 12 Jun 2026" line under the breed when `createdAt` is present, giving the page a sense of history.
- **Housekeeping:** fixed the stale nav-pill doc comment (it described a black selected circle; it's coral), and removed four empty legacy scaffold directories (`lib/screens`, `lib/services`, `lib/theme`, `lib/widgets`) left over from the pre-Riverpod structure.

The full journey is now cohesive end to end: launch → splash (min 800ms, gated) → login/register (email + Google, reset, validation) → 7-step onboarding → Home (cat banners + add) ↔ Settings (account + about + sign-out) → cat detail (avatar, stats, added-date, documents) → edit (update + remove) → document upload/open/delete. Every screen shares the same tokens, Nunito type, coral accent, chiclet buttons, springy press feedback, and AsyncValue loading/error/empty handling.

## Session 6 — APK build fix (rive removed)

- **Removed the `rive` dependency.** It provided zero user-visible functionality at this stage — there is no real `.riv` animation file yet (the bundled `neko.riv` is a placeholder), and `NekoMascot` always rendered its icon/PNG fallback. Rive's native (NDK) build chain was the only thing requiring an NDK at all and was the sole source of the release-build failures (`rive_common` pinned NDK 25.1.8937393 which was a broken/partial download on this machine, and NDK 28 then rejected rive's declared `minSdk 19` with CXX1110).
- `NekoMascot` is now a plain `StatelessWidget` that renders the caller-supplied `fallback`, keeping its `({size, fallback})` API so no callers changed. The Rive-animated version will be wired back in here once a real `.riv` file with known state-machine names exists.
- With rive gone the project has **no native code at all** (Firebase/image_picker/file_picker/audioplayers are pure Java/Kotlin/Dart), so no NDK is needed and the build is far more portable. Both `flutter build apk --debug` and `--release` succeed cleanly. `flutter analyze` → no issues.
- Left the NDK workarounds in `android/gradle.properties` (`rive.ndk.version`, `android.ndk.suppressMinSdkVersionError=21`) in place as harmless no-ops; they cost nothing now and will smooth the path if/when rive returns alongside an explicit `minSdk 21`.
- **Rive re-add is deferred to a later milestone** and gated on (a) a real `.riv` asset existing and (b) an on-device run confirming no regressions. The Pixel 8 was not connected to the build machine this session (`flutter devices` saw only Windows/Chrome/Edge), so the on-device walkthrough is pending hardware.

## Session 7 — Duolingo design system

Adopted the full design system across the app, with one override: the page background is the warm amber everywhere (not white) — white is kept for the cards and fields that sit on top.

- Colours rebuilt around the new tokens (coral brand + primaryDark/primaryLight, the green success family, danger/info/warning, and the Duolingo neutrals — almostBlack text instead of pure black, graphite/silver/cloudGray/snowWhite). Older token names (textPrimary, surfaceCard, border, etc.) are kept as aliases pointing at the canonical values so every existing widget keeps working.
- Typography moved to Fredoka for headlines and Nunito for everything else. Google Fonts ships "Fredoka" as a variable family now (the old "Fredoka One" was merged in), so I use `GoogleFonts.fredoka` at weight 600 for the plump look. Button labels render uppercase with wide tracking.
- Added `AppSpacing`/`AppRadius` on a 4px grid.
- The primary CTA is now a real 3D press button: a coral face resting 4px above a darker platform that slides down on press. I reimplemented `NekoPrimaryButton` in place (same API) so every CTA picked it up, and dropped the chiclet dependency from the button. The onboarding final step uses the green success variant.
- All onboarding choice cards (breed/coat/activity) share one look: white with a soft flat shadow, snapping to a coral border + tint with a checkmark popping in.
- Progress bar is the thin 8px coral-on-cloudGray bar.
- Feedback map filled out to the five moments — tap (light), select (selectionClick), advance (medium + whoosh), success (heavy, 50ms gap, medium — the rewarding double tap), and error (vibrate). Sounds stay optional/no-op until real clips land in `assets/sounds/`.
