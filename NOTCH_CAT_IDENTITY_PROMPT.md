# Notch Cat Identity: Making It Read as Neko, Not a Generic Overlay

This is a companion to `HEY_NEKO_DYNAMIC_ISLAND_PROMPT.md`, narrower on purpose.
That one specifies what the notch *does* — the listening/thinking/speaking
state machine, timer, cam detection. This one specifies what it *looks and
feels like* while doing it. Read them together; nothing here contradicts that
one, it just goes deeper on identity than that prompt had room for.

One correction to make before you start: that earlier prompt said "six coat
palettes." There are actually twelve, in `neko_palette.dart` — nine light,
three dark. Worth knowing up front since it changes how much surface "test
every theme" actually covers.

## The actual diagnosis

The fear behind this prompt — that the notch reads as a Dynamic Island clone
with a cat sticker on it, not something Neko actually made — is worth taking
seriously, because the evidence in the current code backs it up. Here's
exactly where the cat identity is missing, and it's narrower than "everything
needs more cat":

**The icon set is 100% stock Android.** `_iconFor()` in `notch_pill.dart`
maps every named activity type to a plain Material glyph — music note, bell,
timer, phone, navigation arrow, download arrow. The *only* cat icon anywhere
in that function is `Icons.pets_rounded`, and it's the `generic` fallback
case — the one type that shows up when nothing more specific matched. The one
cat touch in the whole icon language is hiding behind a case nobody
deliberately triggers.

**The copy sounds like a system toggle, not like Neko.** The exact string
shown when someone turns the notch on, verbatim from
`notch_controller.dart`, is:

```
title: 'Neko notch is on'
subtitle: 'Play music or get a call to see it live'
```

That's accurate and that's the whole problem — it reads like a permissions
dialog, not like the same app that wrote the rest of your onboarding copy.

**The shape is a plain capsule.** Three window states, all just rounded
rectangles at different sizes. Nothing about the outline says "cat" before
you've read a single icon or word inside it.

**Color is rich, but it can't be the thing carrying the identity.** The
twelve-palette system is genuinely well built — `NotchThemeMapper` derives
the notch's background from `primaryDark` on light themes and
`surfaceElevated` on dark ones, which already keeps every single palette dark
enough to stay legible over an arbitrary backdrop. That's correct and you
don't need to touch it. But look at how much the actual hue swings
theme-to-theme: Ginger & Coral's pill background is a deep brick red
(`0xFF8F2A22`), Snow White's is deep navy (`0xFF36419E`), Lilac Whisper's is
deep purple (`0xFF4D2F8A`), Russian Blue's is a deep teal-slate
(`0xFF243F4C`). Four completely different-looking pills, all "correct." If
color is the main thing signaling "this is Neko," it's an unreliable signal,
because it's *supposed* to change constantly by design. Something has to stay
constant across all twelve palettes for the notch to read as one product —
and right now the things that stay constant (shape, icons, motion, copy) are
also the least cat-specific parts of it.

**What already exists and is underused:** the drifting paw-print pattern
(`_NotchPawPainter`, tinted with the palette's `pawPattern` color) only shows
up in the expanded state, so most glances at the notch never see it. That's
your one working cat-identity element today, and it's nearly invisible.

## Fix the silhouette, not just the fill

The single highest-leverage move here: give the pill's *outline* a cat tell,
not just its color. You already have exactly the asset for this —
`CatEaredIcon` / `_CatEarsPainter` in
`lib/features/profiles/ui/widgets/cat_eared_icon.dart` draws two clean
triangular ears and animates them in with `NekoMotion.pop`, already shipping
today on the nav bar's selected icon. Adapt that same path geometry onto the
notch pill's own top edge in the compact and expanded states — small ear-nubs
breaking the top corners of the capsule. This is worth more than any amount
of internal re-icon-ing, because silhouette reads before color or content
does, and it survives both contexts you asked about: it doesn't depend on
matching a home screen background or a third-party app's colors, only on its
own outline against whatever's behind it.

Leave the idle sliver mostly alone — at 80×5dp there isn't room for ears to
read as ears, and that size is deliberately minimal for good reason (see
guardrails below). If you want one small idle-state touch, taper the ends
instead of a plain rounded-rect cap — something closer to a closed eye or a
whisker tip than a generic pill end. Subtle, not a redesign.

## Fix the icon language without sacrificing clarity

Don't replace the six activity icons with cat glyphs wholesale — a call still
needs to unambiguously look like a call, a download still needs to look like
a download. Legibility matters more than theming here; nobody should have to
guess what a control does. The achievable fix: give each icon a consistent
Neko backing treatment — a small rounded chip behind the glyph, in the same
corner-radius language as the chiclet buttons elsewhere in the app — so even
a stock phone icon sits inside something that visibly belongs to Neko's
chrome instead of floating as a bare Material glyph. Augment, don't replace.

## Home screen vs. third-party apps: different problems, different fixes

**On the home screen**, you control the whole canvas, but don't overbuild
this — `HomeGreeting` is intentionally minimal, just a time-of-day line and
one subtitle on the page background, no header chrome to merge into. The
actual fix here is smaller than it sounds: make sure the system status bar's
icon brightness (light vs. dark icons) is set to match whichever palette is
active, so the strip right around the notch doesn't clash with it. That's the
one place home-screen-specific work is actually needed. Don't invent an
elaborate connective header — there's nothing there to connect to yet, and
building one is a bigger, riskier task than this pass calls for.

**In third-party apps**, you have zero control over what's behind the pill,
which is exactly where the silhouette and consistent icon chip earn their
keep — they're the only things that don't depend on the backdrop cooperating.
On top of that, add a soft shadow or glow in the active `accent` color under
the pill. Apple's own Dynamic Island uses exactly this kind of soft
separation to lift itself off arbitrary content without needing a hard
border. You already have the accent color available on `NotchTheme` — this
is a small addition, not new plumbing.

## Special focus: the AI notch's identity

This is where restraint matters most, because it's the one part of the notch
with genuine personality to express, and it's easy to overdo.

**Give each AI state its own cat gesture, not a generic spinner.** Listening,
thinking, and speaking should look distinguishable from across the room, not
just readable up close:

- **Listening** — ears perk up. Reuse `CatEaredIcon`'s ear geometry and
  `NekoMotion.pop` directly, the same spring that already plays when someone
  taps a nav item. This isn't a new interaction language, it's the existing
  one showing up somewhere new — which is exactly what makes it feel like one
  coherent app instead of a bolted-on feature.
- **Thinking** — something slower and more deliberate than listening. A slow
  blink or a gentle pulse works; the point is the *pacing* has to read as
  different from listening at a glance, since both could otherwise look like
  "the same wobble."
- **Speaking** — the whisker-flutter waveform (already specified in the
  engineering prompt as an extension of `_AudioWaves`). Here, frame it for
  what it's actually doing: this is what makes it read as a cat reacting,
  not a chat bubble that happens to sit in a pill.

**Don't give it a permanent face.** There's a real temptation to draw a
little cat face for the AI state and call it done, but there's nothing to be
consistent with if you do — `NekoMascot` is, in its own doc comment, an
unfinished placeholder with no illustrated version yet. Inventing a face
right now, only for this one surface, risks becoming a second visual
language instead of a solution to the first one. Ears, whiskers, and paws as
*gestures tied to specific moments* will read as more considered than a
cartoon face sitting over someone's Instagram feed the whole time Neko is
listening. Less, applied precisely, beats more.

**Fix the voice, not just the visuals.** Whatever status text shows during
listening/thinking/speaking needs to sound like the app that wrote your
onboarding copy — warm, plain, a little playful — not like the
"Neko notch is on / Play music or get a call to see it live" line quoted
above. You don't need me to write the final strings; you can see them
rendered and I can't. But hold every new line up against that existing
generic one as the thing you're deliberately not writing again.

## The actual test: does it hold up everywhere?

"Looks cat-themed" only means something if it survives contexts you don't
control. Before calling this done, look at idle/compact/expanded, across
every activity type you support, in all of these:

- Neko's own home screen, in at least one light palette and one dark one
  (say, Ginger & Coral and Midnight Black) — confirm the status-bar
  coordination actually lands.
- A photo-heavy app (camera roll, Instagram) — busiest realistic backdrop.
- A plain white app (Notes, Messages) — checks the shadow/lift-off treatment
  isn't only doing work against colorful backgrounds.
- A dark-mode app (a video player, for instance) — confirms the pill doesn't
  disappear against another dark surface.

If it looks like the same considered object in all four, the identity work
is doing its job. If it only looks intentional on the home screen, it isn't
done yet.

## Guardrails: what not to touch

- **Don't rework the color mapping.** `NotchThemeMapper` already keeps every
  palette dark enough to stay legible on any backdrop — that's solved,
  correctly, today. Spend the time on shape/icon/motion/copy instead.
- **Don't add a mascot face.** Covered above — there's no established
  illustrated character to be consistent with, so this pass shouldn't
  introduce one.
- **Don't enlarge or decorate the idle state.** 80×5dp and click-through was
  a hard-won fix to a real "this is annoying" complaint. Adding visual
  weight there to make it "look more cat" undoes that fix for the sake of
  branding — not a trade worth making.
- **Don't fork a separate notch-only color palette.** The identity should
  still ride the same twelve palettes everyone else in the app uses,
  expressed through shape and motion rather than a parallel color system
  nobody else sees.

## Definition of done

- The pill's silhouette reads as cat-shaped at a glance, in compact and
  expanded states, independent of which of the twelve palettes is active.
- Every icon sits in a consistent Neko-branded chip, not bare as a stock
  Material glyph.
- Listening, thinking, and speaking are visually distinguishable from each
  other without reading any text.
- The exact "Neko notch is on" style copy is gone, replaced with lines that
  sound like the rest of the app.
- It's been checked against all four backdrop types above, not just the home
  screen.
