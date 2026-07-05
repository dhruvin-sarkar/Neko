# Hey Neko: The Interaction Script

Third in the set, alongside `HEY_NEKO_DYNAMIC_ISLAND_PROMPT.md` (what the notch
does — the engineering) and `NOTCH_CAT_IDENTITY_PROMPT.md` (how the shell
looks everywhere, in general). This one is the actual choreography for the AI
notch specifically — what plays, in what order, keyed to what.

**This supersedes one thing in the identity prompt.** That doc proposed an
abstract ears-perk / slow-blink / whisker-flutter gesture system for
listening/thinking/speaking, since nothing more specific existed yet. You now
have two actual chosen animations with a specific intended sequence — that
becomes the real answer for listening and output. Keep that doc's restraint
principle (no permanent cartoon face plastered over someone's home screen the
whole time) — the two Lottie cats appear during the AI exchange only, then
go away, which is exactly in that spirit.

**Attach the two sketches when you paste this in.** I'm describing them
below in enough detail to work from, but a coding agent that can actually see
the geometry will get the spacing and proportions right faster than any
amount of my prose.

## The two animations, checked before you build around them

**Listening — [Cat Movement](https://lottiefiles.com/free-animation/cat-movement-J2Rpkvoh5J).**
2.5 KB Lottie JSON, tagged "cat," "look," "cute pet." Small, simple, vector-based.

**Output — [Le Petit Chat "Cat" Noir](https://lottiefiles.com/free-animation/le-petit-chat-cat-noir-NY18MEMwbZ).**
2 KB Lottie JSON, tagged eye / ojos / regarde / noir / gato — confirms this is
a small black cat whose whole character is its eyes, matching what you
described.

Both are covered by the Lottie Simple License, which explicitly permits
commercial use with no attribution required (credit is welcomed, not
mandatory) — one less thing to worry about for submission. That covers
downloading the JSON and bundling it as an asset exactly like your existing
Lottie files; you're not using LottieFiles' hosted embed player, so this is
the license that actually applies to you.

**One real risk to check on a device before you commit to the sequence:**
every one of your twelve notch themes renders its background as either
`primaryDark` or `surfaceElevated` — both are always dark, by design, so the
pill stays legible over any backdrop (see the identity prompt). The output
cat is *also* black. Black on a dark brick-red or dark navy pill might read
fine, or it might wash out and lose its silhouette. Preview it for real
before wiring the rest of the flow — if it disappears, give it a small
lighter platform or a soft rim-light behind it rather than changing the
character.

**Don't try to frame-sync a pre-baked Lottie to individual words.** These are
small, fixed animations, not a rig you can drive frame by frame from token
events. "Syncs with how the text appears" is achievable and looks right if
you loop the animation for the whole time a reply is actively streaming in
and let it settle (freeze on a resting frame, or fade) the moment it's done —
which conveniently is a state you already track. `ChatMessage` already has an
`isStreaming` bool that flips false when a reply finishes (`chat_provider.dart`).
Key the output cat's loop directly off that same flag rather than inventing
a second one.

`lottie: ^3.1.0` is already a dependency, already used in four other places
in the app (`settings_screen.dart`, `add_cat_section.dart`, `keyboard_cat.dart`,
and `NekoLoader` for loading states). This is two new asset files, not new
plumbing.

## The sequence

Tap the mic (per the tap-to-talk decision in the other prompt) → the notch
expands into the AI state.

**1. Listening.** The Cat Movement animation slides up into view from the
*bottom* edge of the panel — not a hard cut, an actual entrance motion, using
whatever spring curve the rest of the notch already expands with. It loops
while the mic is actively capturing. When the transcript finalizes, it exits
the way it came — slide back down out of frame. Entrance and exit should
mirror each other; don't build one and hard-cut the other.

**2. Route the query.** One decision, three outcomes — covered below. This
determines what fills the panel next: plain answer, a short results list, or
the camera.

**3a. Plain answer or results — the output cat appears.** Small, centered,
matches your first sketch: a text area above (several lines, left-aligned,
however many the answer needs) with the little cat sitting anchored at the
bottom of that panel, not overlapping the text. Loop the animation while
`isStreaming`, let it rest once the reply is complete. If the router decided
this is a *results* query, the same panel shows a short list — two or three
items, a title line and one short line each, tappable — instead of prose.
Same cat, same loop-while-loading behavior, different content underneath.
Don't build a second cat treatment for this case.

**3b. Camera intent — the panel becomes a viewfinder.** Matches your second
sketch: the outer panel stays, but the content area becomes a camera preview
(your hatch-marks are the standard sketch shorthand for "image goes here,"
which is exactly right — that's the live camera feed). A capture affordance
sits in or under that preview. If the camera was already open from a moment
ago and the new utterance is a follow-up about the same thing ("what about
this one," "does she like it") rather than a fresh "look at this," reuse the
current or last-captured frame instead of forcing another explicit capture —
don't make someone take the same photo twice for one conversation.

## The router: one decision, three outcomes

Don't build three separate ad hoc checks for this — one function, on the
final transcript, deciding camera / results / plain-answer, in that priority
order (camera first, since "look at this, is it safe" should never get
mis-routed into a results list just because it also contains a comparative
word).

For a hackathon build, a keyword heuristic on the transcript is the actual
answer here, not a placeholder for something fancier — it's deterministic,
it's instant, and it's easy to debug live during a demo, which matters more
than marginal recall on phrasing you won't hit anyway in a five-minute video.

- **Camera**: "look at this," "is this safe," "can [name] have this," "check
  this," "what is this," "does this look okay," "is this poisonous," "scan
  this" — anything implying a physical object needs eyes on it.
- **Results**: "best," "top," "recommend," "which," "compare," "cheapest,"
  "find me," "should I buy," "what's a good" — anything asking for a small
  set of options rather than one answer.
- **Everything else** falls through to a plain conversational answer —
  that's most personal/factual questions ("did I feed Luna," "when's her
  next vaccine," "why is she sneezing").

Treat this list as a starting point to refine once you hear real phrasing
during testing, not a final spec. A smarter model-based version of this
router is a reasonable thing to come back to after submission — not
something to build in parallel with the heuristic now. Ship one version.

## Results mode is real search, not a reformatted answer

Worth doing properly rather than faking: Hack Club runs a separate, free
search proxy alongside the AI proxy — a Brave Search API pass-through at
`search.hackclub.com`, with a plain `GET /res/v1/web/search?q=...` endpoint,
authenticated with a Bearer token the same way as the AI proxy. This is
"popular results" in the sense you actually meant — genuine current search
results, not the model's own guess dressed up as a list.

Two things to confirm before you build on it, since I can't verify them from
here: whether it needs its own separate key from Hack Club (likely signed up
the same way as your existing `AI_API_KEY`, but check
`search.hackclub.com`/its docs directly rather than assuming the same token
works) and its actual rate limit for a free account. Once confirmed, this is
a single GET call and a small JSON parse — no new dependency, since whatever
HTTP client `chat_service.dart` already uses covers it.

This is the first outbound call in the app to something other than
`ai.hackclub.com` — give it the same restraint the existing service already
has around error bodies (don't log full response payloads outside debug
builds), and fail into the plain-conversational path if the search call
errors, rather than showing a broken results panel.

## The camera pop-up, specifically

A live camera preview embedded inside an Android overlay window is a real,
solved pattern — there's a whole plugin category built around exactly this
(`camera_overlay_window` on pub.dev is one example, purpose-built for "a
floating camera preview that remains on top of other apps"). That's good
evidence this is achievable, not a guess.

What I can't verify from here is whether the official `camera` plugin drops
cleanly into your *specific* existing overlay — the notch runs in its own
secondary Flutter engine (`notch_overlay_entry.dart`), and camera texture
registration inside a secondary engine hosted by `flutter_overlay_window`
specifically is the one piece of this whole pass genuinely worth a fast,
throwaway spike before committing: get a bare `CameraPreview` rendering
inside the existing overlay engine, fifteen minutes, before you build the
capture flow, permission handling, and result UI around it.

If it renders cleanly, build the real thing. If it fights you — texture
issues, lifecycle conflicts with the overlay's own engine, whatever — don't
burn a day forcing it. Fall back to: tapping the camera affordance in the
notch briefly hands off to the system camera (the same `image_picker`
capture flow from the other prompt), which returns you straight back to the
notch with the photo already in hand. The entry and the result both still
live in the notch; only the capture itself borrows the system camera for a
second. Pick one of these two after the spike and build only that one — not
both "just in case."

Either way, once a photo exists, it goes through the exact same
vision-capable pipeline from the engineering prompt — `ChatService` with an
image `ChatAttachment` and the cat-safety system prompt. The camera pop-up is
a new *entry point* into that pipeline, not a second analysis path.

## Guardrails

- Don't build a second cat-loading treatment for the results-list case —
  same output cat, same loop-while-loading behavior, the content underneath
  is what changes.
- Don't build the router as three independent checks that can disagree with
  each other — one function, one ordered decision, three outcomes.
- Don't skip the black-cat-on-dark-pill contrast check — confirm it on
  device across at least a couple of the darker-hued themes before calling
  the sequence done.
- Don't build both camera approaches. Spike, decide, build one.

## Definition of done

- Listening cat slides in from the bottom on trigger, slides back out on
  final transcript, no hard cuts either direction.
- Output cat is centered, sized, and positioned per the first sketch, loops
  while `isStreaming`, settles when done, and is legible against every coat
  theme's pill background.
- One router function correctly sends "is this lily safe for my cat" to
  camera, "what's the best wet food for indoor cats" to results, and "did I
  feed Luna today" to a plain answer.
- Results mode shows real Brave-search-backed results, not a relabeled model
  answer.
- The camera state matches the second sketch, and you've made the
  spike-then-commit call on embedded preview vs. system-camera handoff
  rather than half-building both.
