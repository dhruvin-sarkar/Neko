# AI Integration

Neko talks to the Hack Club AI proxy (OpenAI-compatible) at
`https://ai.hackclub.com/proxy/v1`. There is **one** request path — the streaming
chat service — and every AI feature (text chat, Hey Neko voice, the cat safety
scan) rides it. Features differ only by a conditional line added to the single
system prompt and, for the scan, an attached image. No feature has its own
endpoint, HTTP client, or forked prompt.

## The one service

`HackClubChatService` (`features/chat/data/chat_service.dart`) implements:

```dart
Stream<String> streamReply(
  List<ChatMessage> history, {
  String? catContext,   // the owner's cat profile(s), folded into the system prompt
  bool spoken = false,  // Hey Neko: keep the reply short + speech-friendly
  bool safety = false,  // safety scan: cautious feline-safety verdict on the photo
});
```

- Streams Server-Sent Events; falls back to a single JSON completion if the
  proxy doesn't stream.
- Model: `google/gemini-3-flash-preview` (multimodal — needed for the safety
  scan's image input). Overridable via `AI_MODEL` in `.env`.
- Auth: `Authorization: Bearer $HACKCLUB_API_KEY` from `.env` (never hard-coded).

### The system prompt is layered, not forked

The base prompt scopes Neko to cat care and forbids markdown/emoji. `catContext`,
`spoken`, and `safety` each **append one instruction** to that same prompt:

- `spoken` → "read aloud by TTS, keep it to one or two short spoken sentences,
  no formatting."
- `safety` → the safety directive: identify the item, begin with `SAFE` /
  `CAUTION` / `DANGER`, and **err firmly toward caution** — anything ambiguous,
  possibly-ingested, or a known hazard (lilies, onion, garlic, chocolate,
  grapes, xylitol, meds, cleaners) is never `SAFE`; every `DANGER` tells the
  owner to call a vet or poison control.

### Images (vision)

A user `ChatMessage` carrying image `ChatAttachment`s is encoded as a multi-part
`content` array with `image_url` data-URLs (base64), which the vision model
reads directly. This is how the safety scan sends its photo — no separate upload.

## Feature paths

### Text chat — `ChatController`
Appends the user message, streams the reply into a placeholder bubble, persists
finished conversations to history. Personalises with `catContext`.

### Hey Neko voice — `HeyNekoController` (`features/voice/`)
Two entry points, both in the app engine: the composer **mic**, and an optional
**wake word** (`WakeWordController`, Settings → Hey Neko voice) that keeps a
`speech_to_text` session looping while the app is foregrounded and opens the page
when it hears "neko". Both open the dedicated **AI-notch page** (`HeyNekoPage`) —
a dark island takeover themed with the same `NotchThemeMapper` palette as the
physical pill, with the listening / Cat-Noir Lottie cats.

```
mic / wake word → transcript
   → _route()  ─ camera cue?   → image_picker photo → streamReply(safety, spoken)
               ├ results cue?  → SearchService (Brave via Hack Club) → tappable list
               └ otherwise     → streamReply(spoken)                 → reply
      → text-to-speech (flutter_tts)
```

`_route` decides once on the final transcript, in priority order: a
"look at this / is this safe / is this poisonous" request snaps a photo and runs
the **same** safety-vision path as the attach-menu scan; a "best / top / which /
recommend" request runs a real web search (`SearchService` →
`search.hackclub.com`, Bearer-auth, Brave `web.results[]`) and shows a tappable
list (the cat-in-a-box animation loops while searching); everything else is a
plain spoken answer. Results mode is **fail-soft** — any missing `SEARCH_API_KEY`,
HTTP error, or empty result falls back to a plain spoken answer rather than a
broken panel, and the query/response bodies are never logged outside debug. Each step mirrors
to the island as an `assistant` activity (listening → thinking → speaking). The
finished exchange is written into the chat transcript via
`ChatController.appendVoiceTurn`. Failure modes fall back gracefully: mic denied →
"type instead"; nothing heard → "tap to retry"; no photo → plain answer. The wake
loop and the command session share one `SpeechService`, coordinated by
pause/resume so only one holds the mic at a time.

### Cat safety scan — `SafetyScanController` (`features/safety/`)
From the composer's attach menu → "Cat safety scan":

```
camera (image_picker) → photo
   → streamReply(safety: true, image attached) → reply
      → SafetyVerdict.parse() → colour-coded chip (safe / caution / danger)
```

The verdict headline is mirrored to the island as a transient notification. The
photo is used for the single request and then dropped — **never persisted** to
history or storage. "Discuss in chat" appends the text verdict (no image) to the
transcript for follow-up.

## Privacy / logging

Matching the restraint already in `chat_service.dart`: transcripts, photos, and
AI response bodies are **never logged outside debug builds**. HTTP error bodies
are drained (to free the connection) but only a short snippet is logged, in debug
only. `RECORD_AUDIO` and `CAMERA` are requested with clear rationale strings and
denial is handled, never crashed.
