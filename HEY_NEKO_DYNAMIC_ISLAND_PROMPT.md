# Hey Neko: AI Voice + Cam Detection + Full Dynamic Island Pass

Paste this whole thing in as-is. It's written from a real audit of the current
GitHub state (`dhruvin-sarkar/Neko`, main branch, pulled today), not from the
original planning docs — so treat the section below as ground truth over your
own memory of what "barebones" meant. If your local working tree has
uncommitted changes on top of this, trust what's actually on disk over these
notes, but the architecture and decisions below should still hold.

Submission closes July 7, 23:59 BST. That's the real constraint on everything
that follows — this prompt is ordered so that if you run out of runway, you
stop on a phase boundary with nothing half-wired.

## 0. Read first

Open, in this order: `CLAUDE.md`, `ARCHITECTURE.md`, `NOTCH_IMPLEMENTATION.md`,
`AI_INTEGRATION.md`, `SECURITY_GUIDE.md`. Then open the actual files this
prompt touches:

```
lib/core/notch/controller/notch_controller.dart
lib/core/notch/model/notch_activity.dart
lib/core/notch/model/notch_command.dart
lib/core/notch/notch_channels.dart
lib/core/notch/overlay/notch_overlay_entry.dart
lib/core/notch/overlay/widgets/notch_pill.dart
lib/core/notch/service/notch_overlay_service.dart
lib/core/notch/service/notch_theme_mapper.dart
android/app/src/main/kotlin/com/example/neko/NekoNotificationListenerService.kt
android/app/src/main/kotlin/com/example/neko/NotchBridge.kt
lib/features/chat/data/chat_service.dart
lib/features/chat/providers/chat_provider.dart
lib/features/chat/models/chat_attachment.dart
```

Do a fast pass, confirm the claims in section 1 still hold, then move on. You
don't need to re-derive any of this from scratch — it's already verified.

## 1. Where the notch actually stands right now

This is more built than "barebones setup" suggests. Here's the honest state,
capability by capability:

**Foundation (working).** `flutter_overlay_window` runs the notch in its own
Flutter engine, separate from the main app engine — that's why it survives
the app closing. Three window states, each an actual OS-level resize via
`FlutterOverlayWindow.resizeOverlay`: idle (80×5dp content), compact (212×40dp),
expanded (212×124dp), all plus a status-bar inset computed from the real
device padding. When there's no active activity (`_primary == null`), the
overlay flips to `OverlayFlag.clickThrough` — invisible to touch, so it can't
block the apps underneath it. Multi-activity stacking already works too:
`_stack` holds several activities at once, `_cycle()` swipes between them, and
there's already a page-dot indicator (`_PageDots`) for when more than one is
queued.

**This is also the exact cause of the sizing/touch problem from your notch
chat with Akshat.** The idle state is deliberately tiny and click-through so
it isn't "annoying" — but that also means there is currently no way to tap
the notch when idle, because there's nothing rendered there to tap. That
wasn't a bug you left unsolved; it's a real structural tension, and it's why
section 3 below matters before you touch any AI wiring.

**Theme persistence (working, needs hardening).** `NotchController.syncTheme()`
reads `AppColors.palette` and pushes a `NotchThemeCommand` into the overlay,
cached against `_lastSyncedThemeId` so it doesn't resend on every rebuild.
Mechanism is sound. "Needs polishing" here most likely means: force a resync
when the notch is re-enabled after being off, and double check the very first
frame before the theme command arrives doesn't flash the hardcoded
`NotchTheme.fallback` colors in an ugly way.

**Music extraction (working, genuinely good).** Native side
(`NekoNotificationListenerService.kt`) binds to `MediaSessionManager`, reads
title/artist/duration/position/playing state, and ships album art as a
base64 JPEG (downscaled to 160px, quality 80) over the event channel. This
already does what Apple's Dynamic Island does for now-playing. Polish target:
edge cases when the active session changes rapidly, and whatever the Dart
side (`_Artwork` in `notch_pill.dart`) does when art is missing or corrupt.

**Media control (working).** Play/pause/next/previous round-trip from the
overlay's buttons through `_sendControl` → `NotchBridge` → the native
`MediaController.transportControls`. Confirm this survives the notch being
resynced after a reboot (`NotchBootService.kt`, `BootReceiver.kt`).

**Notifications, calls, downloads, navigation (working, more than you may
realize).** The listener classifies by category: Google Maps notifications
(`com.google.android.apps.maps`) are hardcoded to `"navigation"`, calls ride
Android's own `Notification.category`, and anything with determinate progress
while ongoing gets inferred as a download on the Dart side. **This means
"Maps integration" is not a build-from-scratch task.** The pipe already
exists and already tags navigation notifications correctly. What's actually
missing is a dedicated compact/expanded visual treatment for
`NotchActivityType.navigation` — right now it likely falls through to the
generic notification layout. Give it its own look (next-turn text, ETA as
the progress bar, a maps-flavored icon) and you're done. No Maps SDK, no API
key, no new permission.

**Timer (barely started, cheap to finish).** `NotchActivityType.timer`
already exists in the enum, `isRestorable` already includes it, and
`notch_pill.dart` already maps it to `Icons.timer_rounded`. Nothing anywhere
creates one. This needs: a UI entry point (a feeding-reminder countdown is
the obvious cat-relevant hook, but a generic timer works too), a
`Timer.periodic` that calls `updateActivity` with shrinking progress, and
`removeActivity` at zero. No native code required — this is a pure Dart
feature hiding behind a data model that's already done. Do this one early;
it's nearly free.

**AI voice ("Hey Neko") — permission staged, nothing wired.**
`RECORD_AUDIO` is already declared in the manifest with a comment reading
"wired in a later pass" — this prompt is that pass.
`speech_to_text: ^7.4.0` and `flutter_tts: ^4.2.5` are already in
`pubspec.yaml`. Nothing in `lib/` uses either yet. Separately, and this is
important: `lib/features/chat/` is a fully working AI tab already —
`HackClubChatService` streams SSE from `https://ai.hackclub.com/proxy/v1`,
folds a `catContext` string into the system prompt so answers are personalized
per-cat, and keeps Neko locked to cat-care topics only. **Don't build a
second AI pipeline for the notch. Reuse this one.**

**Camera detection — nothing exists yet.** No `CAMERA` permission, no camera
plugin, no code. But — and this changes the shape of the work —
`chat_service.dart` already builds fully correct OpenAI-style multipart
messages with `image_url` content parts whenever a `ChatMessage` carries an
image `ChatAttachment`. Vision is not new work on the AI side at all; it's
already there and already correct. Confirmed independently: the Hack Club
proxy serves several vision-capable models (the Gemini family the app
already targets, plus explicitly vision-tagged models like
`qwen/qwen3-vl-235b-a22b-instruct`), and the app's `image_url` data-URL
approach is the right OpenAI-compatible shape for that proxy. What's missing
is entirely on the capture side: permission, a camera flow, and a
purpose-built prompt.

## 2. The reframe

The to-do list makes this feel like a mountain of work. It isn't, once you
separate "things that are basically done" from "things that are actually
new." Foundation, theming, music, media control, notifications, calls,
downloads, and navigation are all live pipelines already — what's left there
is visual polish and hardening, not new plumbing. Timer is a data model
waiting for a UI. That's most of "all the features of Apple's Dynamic
Island" already sitting in the repo.

The two genuinely new things — Hey Neko and cam detection — are also the two
things Apple's Dynamic Island doesn't have. That's your actual differentiation
for Innovation and Theme Relevance scoring, and it's exactly what you flagged
as "my turn now." Don't let the parity checklist steal time from the two
features that are actually unique to this project.

## 3. The one decision this whole pass hinges on: tap-to-talk, not a wake word

"Hey Neko" should be the phrase the product is branded around — not a literal
always-listening wake word. Three independent pieces of evidence point the
same way:

- `speech_to_text`'s own docs are explicit: it targets "commands and short
  phrases, not continuous spoken conversion or always on listening." That's
  not a workaround you're missing, that's the package telling you what it's
  for.
- The idle notch is click-through and near-zero-size by design, and that
  design is correct — it's what stopped the notch from being "annoying" in
  the first place. Reversing it to make it a permanent tappable target
  regresses a UX decision that already works.
- True always-on wake-word detection needs a dedicated engine (Picovoice
  Porcupine is the real option here — it showed up independently in the
  research), a persistent foreground audio service, a custom trained wake
  model, and real battery/privacy tradeoffs. That's a multi-day feature on
  its own, not a slot in a 3-day pass.

So: **the mic entry point lives in the app, not in the idle overlay.** A
clearly tappable mic button — on the home screen and/or inside the existing
chat screen, your call on placement once you can see it rendered — starts a
listening session. The overlay's job stays exactly what it already is for
music and notifications: a presentation surface fed by commands, not a place
where new logic lives. Concretely:

- STT, the actual Hack Club API call, and TTS playback all run in the **main
  app engine**, reusing `chatServiceProvider` and whatever `catContext`
  construction `chat_provider.dart` already does. This sidesteps any question
  about whether `speech_to_text`/`flutter_tts` behave correctly inside the
  overlay's separate engine, because they never run there.
- The overlay only ever receives activity pushes, exactly like it does today
  for a song changing. Add `NotchActivityType.aiAssistant` (or `assistant` —
  match whatever naming convention the enum already uses) to the enum, and
  drive it through the existing `showActivity` / `updateActivity` /
  `removeActivity` calls on `NotchController` as the exchange moves through
  listening → thinking → speaking → done. No new command type is strictly
  needed on the main→overlay side; `PushActivityCommand`/`UpdateActivityCommand`
  already do this job for music.
- For visual feedback while listening: `speech_to_text` exposes live mic
  amplitude via its sound-level callback, and the package's own example app
  uses exactly this to drive a pulsing indicator. `notch_pill.dart` already
  has `_AudioWaves`, a four-bar phase-animated waveform used for music. Don't
  build a second thing from nothing — either generalize `_AudioWaves` to
  accept an externally driven amplitude value, or add a sibling widget that
  shares its structure. Turn the bars into whiskers or a small tail-flick;
  that's your cat-theming hook for this feature, and it's cheap because the
  animation plumbing already exists.
- Getting a *live* amplitude value from the main engine into the overlay
  engine means relaying ticks across the existing shareData bridge while
  listening. That's a nice-to-have. If time is short, fall back to the same
  fake-pulse animation `_AudioWaves` already does for music and only make it
  amplitude-reactive if Phase 3 finishes early. Ship the simple version
  first.
- Keep spoken answers short. Add one line to the existing system prompt for
  this path only — something like telling the model its reply will be read
  aloud by TTS, so it should answer in two or three sentences — rather than
  forking a second system prompt. One prompt, one small conditional addition,
  not a parallel copy.
- Handle the predictable failure modes without drama: mic permission denied
  → fall back to the existing text input in the chat screen, don't dead-end
  the user. STT returns nothing recognizable → same fallback. This mirrors
  what `chat_service.dart` already does when the API key is missing — a
  friendly `ChatException`, not a crash.

Don't build a quick-settings tile or any OS-level always-available entry
point in this pass. It's a reasonable v2 idea if you want push-button summon
without opening the app, but it's native Android service work you don't have
runway for right now. Note it in `DECISIONS.md` as deferred, not forgotten.

## 4. Build order

Ordered by leverage and risk given the time left. Each phase should leave the
app in a demoable state — don't start a phase you can't finish today.

### Phase 1 — Fix the notch's look, catify the foundation
This is the item both your messages led with, and it's the base every later
phase renders on top of, so it goes first.

- Fix whatever specifically looks off about current sizing/spacing at each of
  the three states. Look at real proportions on the Pixel 8 at each state,
  not just the numbers — 80×5dp idle next to a 212×124dp expanded state is a
  big jump, make sure the expand/collapse motion (already using a nice
  `Cubic(0.22, 1.0, 0.36, 1.0)` curve) doesn't look like it's popping rather
  than growing.
- Audit every hardcoded color/icon/shape in the notch overlay tree against
  `NekoColors`/the six coat palettes. The notch has its own `NotchTheme`
  (background/foreground/subdued/accent) mapped from the app palette via
  `NotchThemeMapper` — make sure that mapping actually reads right for all
  six coat themes, not just whichever one was open during development.
  `NotchThemeMapper` is only 21 lines right now; that's a strong signal it's
  underbuilt relative to how much it's responsible for.
- The paw-print drift (`_NotchPawPainter`, tiling `assets/images/paw.png` at
  low opacity while expanded) is a nice existing cat-theming touch — extend
  that same instinct to anything new you add in this pass rather than
  inventing a fresh visual language per feature. One family of motifs, not
  five.
- Reuse the existing sfx set (`sfx_cat_chirp`, `sfx_cat_meow_notif`,
  `sfx_cat_purr_loop`, `sfx_cat_trill`, etc.) for notch moments instead of
  silence or a generic system sound — a soft chirp on expand, for instance.

### Phase 2 — Timer
Cheap, as established above. UI entry point (feeding-reminder framing fits
the app better than a generic stopwatch, but either is fine), a
`Timer.periodic` ticking `updateActivity`, cleanup at zero. Make it
restorable across app restarts the same way music already is — the model
already supports this via `isRestorable`.

### Phase 3 — Hey Neko
Build exactly per section 3. In order: mic entry point in the app → STT
session → push a listening `NotchActivity` → on final transcript, call
`chatServiceProvider` with the real `catContext` → push a thinking state →
accumulate the stream → push the answer text and call `flutter_tts.speak` →
remove after speaking finishes or a fixed TTL. Test with the notch enabled
*and* disabled — the AI feature in the main chat screen should keep working
identically either way, since the notch is a bonus display layer, not a
dependency.

### Phase 4 — Cam detection
Camera capture (reuse `image_picker`'s camera source before reaching for a
new `camera` package dependency — check whether a live viewfinder is actually
needed or whether snap-a-photo-then-analyze covers the real use case; the
latter is simpler and matches how a phone camera safety-check would actually
get used). Add the `CAMERA` permission. Build a photo into a `ChatAttachment`
and send it through the existing `ChatService`, with a dedicated prompt
variant — not the general cat-care system prompt verbatim, but the same
family of instructions with the addition that it's now judging whether
something in a photo is safe for a cat.

This one carries real stakes, not just product polish: cats and toxic
plants/foods is a genuine welfare issue (lilies, for one, are severely toxic
to cats, and that's exactly the kind of question this feature will get
asked). The system prompt for this path needs to explicitly err toward
caution on anything ambiguous or already-ingested, and always suggest a vet
or animal poison control rather than a confident guess when uncertain — the
same pattern the existing system prompt already uses for medical questions,
just carried over here deliberately rather than assumed.

Show the verdict as a clear card in the app, and mirror a short version to
the notch via the same activity pipeline (a compact safe/caution/unsafe badge
for a few seconds) so it feels like part of the same live-activity family as
everything else, not a bolted-on separate flow.

### Phase 5 — Harden what already works
Theme resync on re-enable, album art edge cases, media control across
reboot, and the dedicated navigation/maps presentation layout described in
section 1. This is bug-fixing and visual-treatment work on pipelines that
already function, so it's lower risk than it sounds — budget it after the
two AI features, not before, since it doesn't carry the same theme-relevance
and innovation upside.

### Phase 6 — Final cohesion pass
Walk every notch state end to end, on a real device, with each of the six
coat themes active. Nothing should look like a different app pasted into the
top of the screen. Check the quality bar below before calling this done.

## 5. Cross-cutting rules for every phase above

- Reuse before you build: `chatServiceProvider` for any AI call, the
  existing `_AudioWaves` pattern for anything audio-reactive, the existing
  sfx/Lottie assets before adding new ones, the six coat palettes for any new
  color, the `PushActivityCommand`/`UpdateActivityCommand`/`RemoveActivityCommand`
  pipeline for anything new that should show up in the notch. If you catch
  yourself building a second version of something that already exists,
  stop and reuse instead.
- One way to do things: don't add a second AI request path, a second
  waveform widget, or a second system prompt when extending the existing one
  with a conditional would do.
- Security: don't log raw transcripts, photos, or AI response bodies outside
  debug builds — match the restraint `chat_service.dart` already shows around
  logging HTTP error bodies. Request `RECORD_AUDIO`/`CAMERA` with a clear
  rationale string, handle denial gracefully rather than crashing, and don't
  persist camera-scan photos by default unless that's a deliberate feature
  decision you write down.
- Update `NOTCH_IMPLEMENTATION.md` and `AI_INTEGRATION.md` as you go, not at
  the end. Documentation is a scored category on its own — don't leave it for
  the last hour.

## 6. Quality bar

- `flutter analyze` at zero issues before moving to the next phase, not just
  zero errors.
- Every new `StatefulWidget` disposed correctly; `mounted` checked after
  every async gap that touches `BuildContext`.
- Every new async state (listening/thinking/speaking, camera analysis)
  handled explicitly — a stuck spinner or a silent failure is worse than a
  visible error state.
- Nothing in this pass may regress music, media control, notifications, or
  theme sync. Re-test all four after you're done, not just the features you
  added.

## 7. When you hit a genuinely ambiguous call

Check the actual codebase for the existing convention first. If there truly
isn't one, pick whichever option keeps the codebase to one pattern rather
than two, and log the call in `DECISIONS.md` with a one-line reason. Keep
moving — there's no one watching this run live, and asking-and-waiting costs
more than a documented, reversible judgment call.

## 8. If you're running short on time

Ship, in this order, and stop cleanly at whichever point you run out of
runway: Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6. Phases 1
through 3 are the ones that most affect UX/UI, Innovation, and Theme
Relevance scoring, and they're also the ones with the least native-Android
risk. If Phase 4 or 5 don't fit, that's a fine place to stop — a tight,
polished Hey Neko beats a half-working camera feature and an untouched
navigation layout.

## 9. Definition of done

- All six phases above either shipped or explicitly deferred with a reason
  in `DECISIONS.md`.
- The notch, the main chat tab, and the new voice/camera flows all read as
  one product in one visual language, in every coat theme.
- `flutter analyze`: zero issues. App installs and runs on the Pixel 8 from a
  clean `flutter pub get` + reboot, notch survives the app being closed, and
  survives a device reboot without needing the app reopened first.
- `NOTCH_IMPLEMENTATION.md` and `AI_INTEGRATION.md` reflect what's actually
  in the repo, not what was planned before this pass.
