# Neko Notch — Dynamic Island + AI Notch

Neko turns the phone's punch-hole camera cutout into an interactive, cat-themed
Dynamic Island: a live-activity pill that shows music, calls, navigation,
downloads, notifications, a feeding countdown, and Neko's own voice assistant —
all rendered as Neko the cat (ears around the cutout, a whiskered muzzle as the
audio indicator, a paw motif behind the expanded card).

This document covers how it's built and how the pieces fit. For the AI request
paths (chat, voice, safety scan) see [AI_INTEGRATION.md](AI_INTEGRATION.md).

## Two engines

The notch is a real Android system overlay (`SYSTEM_ALERT_WINDOW`) drawn by
`flutter_overlay_window`, which runs it in a **separate Flutter engine** so the
pill survives the app being closed. So there are two Dart worlds:

- **App engine** — the normal app. Hosts `NotchController` (the brain), the chat
  / voice / safety controllers, STT, and TTS.
- **Overlay engine** — just the pill UI (`NotchPill`) plus a tiny sound helper
  (`NotchSfx`). It receives commands and renders; it owns no business logic.

They never share memory. Everything crosses as JSON.

```
 app engine                         overlay engine
 ┌─────────────────────────┐        ┌────────────────────────┐
 │ NotchController         │ shareData (push/update/remove/   │
 │  • showActivity()       │─theme)──────────────▶ NotchPill  │
 │  • updateActivity()     │        │              (renders)  │
 │  • removeActivity()     │◀──control (play/pause/next)──────│
 │  • startTimer()         │        └────────────────────────┘
 │  • syncTheme()          │
 └─────────┬───────────────┘
           │ EventChannel (neko/notch_events)
 ┌─────────▼───────────────────────────────────┐
 │ NekoNotificationListenerService (native)     │
 │  • mirrors notifications                      │
 │  • mirrors MediaSession now-playing + art     │
 │  • classifies call / navigation / download    │
 └───────────────────────────────────────────────┘
```

## The activity model

Everything on the island is a `NotchActivity` (`core/notch/model/notch_activity.dart`):
one immutable record with a `type` (`music`, `notification`, `timer`, `call`,
`navigation`, `download`, `assistant`, `generic`), title/subtitle, optional
progress, album art, and — for countdowns — an **absolute** `endsAtMs`.

Two design choices matter:

- **Absolute end time for timers.** A countdown carries the wall-clock epoch it
  ends at, so the overlay ticks it down locally (`_Countdown`) with no
  per-second messages from the app, and it stays correct across restarts and
  reboots.
- **`isRestorable` is narrow.** Only `music` and `timer` persist to the boot
  restore payload. Transient things (a voice `assistant` session, a safety-scan
  result) never get restored after a kill — they'd be stale.

## Command flow

`NotchController` sends a sealed `NotchCommand` (`push` / `update` / `remove` /
`clear` / `theme`) via `shareData`. `NotchPill._onMessage` parses and applies it.
Ongoing activities are also written to `SharedPreferences` (`notch_restore`) so a
reboot can bring them back.

## Native bridge (`NotchBridge.kt`) — three-tier delivery

When a real notification or media event arrives, `NotchBridge.send` delivers it
by whichever path is alive:

1. **App engine listening** (`sink` set) → `NotchController`, which adds the
   theme and boot-restore persistence.
2. **App killed, overlay alive** → push the command straight onto the overlay
   engine's messenger. Play/pause/skip still work because the transport
   `MethodChannel` (`neko/notch_media`) is bound directly on the overlay engine
   (`bindOverlayControls`), re-bound on every event so it survives a new engine
   after reboot.
3. **Both down** → stash the event in prefs and cold-start `NotchBootService`,
   which shows the overlay and flushes the pending command.

## Boot restore

`BootReceiver` → `NotchBootService` runs a short-lived engine (`notchBootMain`)
that re-shows the overlay from the persisted `notch_restore` payload. Expired
timers are dropped on the way back in (both in the boot path and in
`NotchController._ensureShown`) so a countdown that ended while the phone was off
doesn't flash up just to vanish.

## Theming — always dark under the camera

The island sits under the punch-hole, so it must stay near-black in every coat
palette. `NotchThemeMapper.fromPalette` forces the background dark (lerping a
leaked-light palette toward ink), the foreground light, and picks a readable
accent. `NotchController.syncTheme` re-pushes the theme when the palette changes
(id-diffed to avoid spam) and force-pushes on enable.

## The cat, everywhere

- **Ears** (`_CatEarsPainter`) perk up around the cutout whenever the island is
  awake, warming to the accent colour while Hey Neko is live.
- **Muzzle waveform** (`NekoMuzzleWaves`, in `shared/widgets/`) is the single
  audio indicator used by *both* the overlay and the in-app voice sheet — a nose
  with three whiskers per side that twitch while audio happens. One widget, so
  the cat reads as the same character on every surface.
- **Paw drift** (`_NotchPawPainter`) tiles the paw faintly behind the expanded
  card.
- **Sound** (`NotchSfx`) chirps as the island wakes/expands and trills when a
  timer ends, honouring the saved sound preferences.

The pill widens as it expands (Apple-style): compact 212 dp → expanded 316 dp,
with the visual pill animating across the wider window.

## Feature surfaces that drive the island

| Surface | Pushes | Where |
|---|---|---|
| Feeding timer | `timer` countdown | cat profile screen |
| Hey Neko voice | `assistant` (listening → thinking → speaking) | chat composer mic |
| Cat safety scan | `notification` verdict | chat attach menu |
| System media / calls / nav / downloads / notifications | typed activities | native listener |
| System / Clock timers | `timer` countdown (via `EXTRA_CHRONOMETER_COUNT_DOWN`) | native listener |

The audio indicator is a clean three-bar `_EqualizerBars` (music + assistant),
not a whiskered muzzle — the pill's cat identity rides the ears, the per-icon
Neko chip (`_Artwork`), the paw drift, and warmer copy instead. Album art falls
back to an art **URI** (fetched + cached) when a session ships no bitmap, so
YouTube/Chrome thumbnails resolve. `HeyNekoPage` renders the same island palette
full-screen as the "AI notch" takeover.

## Deliberate non-goals

- **No quick-settings tile** for Hey Neko — a separate native surface, not worth
  the risk before the deadline. Voice is launched from the in-app mic.
- **Media control before the app is first opened after a cold reboot** may not
  route until the overlay's cached engine exists; it binds automatically once
  the overlay re-shows.
