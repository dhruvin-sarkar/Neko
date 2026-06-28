# Decisions

A running log of the architectural decisions made on Neko. Newest first.

---

## 2026-06-28 — Draft persistence, shadow tokens, motion tokens

- **Onboarding draft persistence (O004):** `OnboardingDraft` is now JSON-
  serialisable; `OnboardingPersistence.saveDraft/loadDraft/clearDraft` store the
  draft + step under `onboarding_draft_<uid>`. The notifier restores on build,
  persists on every step change, and clears on completion / "add another cat", so
  onboarding resumes at the right step after process death.
- **Theme-aware shadow tokens (O003):** added `AppColors.shadowSoft/Medium/Strong`
  (deeper alpha on dark palettes) and replaced the hardcoded `Colors.black12/26/38`
  shadows that were invisible on the Midnight Black theme.
- **Motion tokens (`lib/core/neko_motion.dart`):** centralises the *repeated*
  durations + curves (press / selection / entry + the elastic pop). Adopted by the
  design-system widgets (Pressable, choice/coat cards, selection check, nav pill,
  continue button), the `flutter_animate` default, and screen entry animations.
  Bespoke one-off timings (page-transition curtains, shimmer periods, coach-mark
  choreography, audio fades) intentionally stay local to their widget.

---

## 2026-06-28 — Deliberate deviations from the "enterprise audit" protocol

An audit protocol specified some items that do not match this codebase's reality.
Recorded here so the deviations are intentional, not oversights:

- **HTTP, not Dio, for the AI layer.** The protocol/CLAUDE.md mention Dio, but
  `chat_service.dart` uses `package:http` with working SSE streaming. Rewriting a
  working stream to Dio adds risk with no functional gain, so http stays.
- **Persistence is SharedPreferences + a single Hive `neko_media` box** — not the
  protocol's `neko_preferences`/`neko_ai_context`/`neko_cats`/`neko_calories`
  boxes (those don't exist). The AI context is built on demand from
  `CatProfile.toAIContext()`, not a Hive `ai_context` blob. No restructuring done.
- **No `docs/` folder** exists; the canonical docs are the root `*.md` files.

## 2026-06-28 — One button system (Chiclet `NekoButton`)

**Context:** Four CTA button widgets coexisted — `NekoPrimaryButton` (Chiclet,
the dominant CTA), `NekoPillButton`, `NekoTextButton`, and a hand-built
`NekoButton`.

**Decision:** Consolidate to a single Chiclet-based `NekoButton` with
`.primary` / `.secondary` / `.ghost` factories (carrying `isLoading`/`enabled`/
`icon`). Migrated all 8 `NekoPrimaryButton` + 2 `NekoPillButton` + the hand-built
`NekoButton` usages; deleted `neko_primary_button.dart` and `neko_pill_button.dart`.
Kept `NekoTextButton` for low-emphasis inline text links.

**Scope note:** `AlertDialog` actions (`TextButton`) and icon affordances
(`IconButton`: send, back, password-toggle) are intentionally left as platform
idioms — forcing chiclets into dialog/icon slots degrades UX without benefit.

**Trade-offs:** "Try again" and "Sign out" change from a pill to the chiclet look
— a deliberate consistency gain. Verified: analyze 0, tests 4/4 (test now covers
`NekoButton`).

---

## 2026-06-28 — Image decode downsampling

**Decision:** All local/remote image loads (`cat_avatar`, `photo_step`, chat
attachment previews) pass `cacheWidth`/`cacheHeight` sized to ~3× their display
box, so a 1024px source never decodes at full resolution into memory.

---

## 2026-06-28 — Media storage is on-device only (no Firebase Storage)

**Context:** The codebase had drifted into two competing media systems — a fully
built but completely unused on-device store (`LocalStorageService`, Hive index +
files) and a live Firebase Storage path used by the avatar, document, and profile
repositories. This contradicted the standing "Firebase Storage excluded — cost
decision" and left one whole subsystem orphaned.

**Decision:** Honour the cost decision and go fully local. All media bytes (cat
photos, documents) live on-device via `LocalStorageService`; Firestore keeps only
profile data and document-less cat records. Removed the `firebase_storage`
dependency, `firebaseStorageProvider`, and `storage.rules`. Added `open_filex` to
open stored documents in the platform viewer. Cat photos resolve by `catId`
(`CatAvatar` loads `Image.file`); `CatDocument` is now a local model
(`path`/`name`/`type`/`sizeBytes`/`savedAt`); the documents provider became a
refreshable `FutureProvider`.

**Alternatives considered:** Keep Firebase Storage and delete the dead local
service (lower risk, cross-device sync, but reverses the cost decision).

**Trade-offs:** No cross-device sync and media does not survive a reinstall; in
exchange there is no Storage bill, it works offline, and there is a single, clear
media path. Acceptable for the single-device hackathon target.

---

## 2026-06-28 — Coat `colorType` values made unique

**Context:** 6 of the 12 coat options shared duplicate `value` strings
(`ginger`/`grey`/`tabby`/`black`), so choosing e.g. "Cream" stored `colorType:
ginger` in Firestore — a silent data-integrity bug feeding the avatar fallback
colour.

**Decision:** Each `CoatOption.value` is now unique and equals its `themeId`
(e.g. `creamBeige`, `silverTabby`). `AppColors.catColorFor` maps all 12 (plus the
legacy family keys for backward compatibility) to representative avatar colours.

**Trade-offs:** None meaningful — labels are unchanged, and the AI prompt never
used `colorType`, so only the (previously wrong) avatar fallback colour changes.

---

## 2026-06-28 — AI chat model stays `google/gemini-3-flash-preview`

**Context:** A quality pass suggested pinning a non-preview model.

**Decision:** Keep `google/gemini-3-flash-preview` as the `AI_MODEL` default — the
team's deliberate choice for the Hack Club proxy. Overridable via `.env`.

**Trade-offs:** A preview model can change behaviour upstream; accepted on purpose.

---

## 2026-06-28 — Single consolidated sound engine

**Context:** Two sound layers coexisted — a working static `AudioService` and a
no-op Riverpod `SoundService` that `FeedbackService` called (so feedback was
silent).

**Decision:** `AudioService` is the one engine: a `SoundId` set, defensive
preload with graceful fallback to the three shipping clips, mute/volume, and an
ambient purr. `FeedbackService` routes through it; the no-op `SoundService` was
removed. Mute/volume persist via a `SoundSettingsController`.

**Trade-offs:** Most cat-vocal/purr clips are silent until the real audio pack is
added; the feedback layer (tap/select/success) is audible today.

---

## 2026-06-28 — Build & security hygiene

- **Gradle wrapper → 8.13** because AGP 8.11.1 requires it; the wrapper was pinned
  to 8.9 and the release build failed the version check.
- **Release keystore untracked** (`git rm --cached release-key.jks`) and `*.jks`
  added to `.gitignore`. The key was committed and pushed; it must be **rotated**
  out-of-band (see SECURITY_SCAN.md / README outstanding items).
