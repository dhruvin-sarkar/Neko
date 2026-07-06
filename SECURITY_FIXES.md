# Security Fixes — Aikido Scan Remediation

Companion to the Aikido security scan. Each finding was investigated against
the actual code (not fixed blind from the report), root-caused, and either
fixed or documented as an accepted risk with reasoning. File references are to
the state of the repo at the time of the fix commits.

---

## High

### 1. Path traversal — `local_storage_service.dart` / `document_repository.dart`

**Root cause found.** Document filenames were character-sanitised
(`[^\w.\- ]` → `_`) but never reduced to a basename, and the `catId` /
`docType` segments were interpolated into directory paths raw. Separately,
`deleteDocument()` deleted whatever absolute path the Hive index handed it —
a tampered index entry could aim that delete at any file the app can touch.

**Fix** (`lib/core/services/local_storage_service.dart`):
- `_safeId()` — ids (`catId`, `docType`) collapse to `[A-Za-z0-9_-]` before
  they touch a path, so they can never introduce separators or dot-segments.
- `_safeName()` — externally supplied filenames are stripped to a basename
  (any `/` or `\` components dropped), character-filtered, and dot-only names
  (`.`, `..`) refused.
- `_isInsideRoot()` — before any file delete, the fully normalised path
  (`..` segments resolved) must still live under `<appDocuments>/neko/`;
  otherwise the delete is refused and logged.

### 2. Improper SSL certificate validation — `AndroidManifest.xml`

**Root cause found.** Grepped the whole repo for `TrustManager`,
`HostnameVerifier`, and `badCertificateCallback`: **no custom trust code
exists anywhere**. The finding is about *absence of policy* — no
`networkSecurityConfig`, and `usesCleartextTraffic` implicitly enabled on
older Android.

**Fix** (`android/app/src/main/AndroidManifest.xml` +
`res/xml/network_security_config.xml`):
- `android:usesCleartextTraffic="false"` set explicitly.
- New `network_security_config.xml`: `cleartextTrafficPermitted="false"`
  base config, system trust anchors only, no per-domain overrides, no debug
  relaxations. All Neko traffic (Hack Club AI proxy, Hack Club search,
  Firebase) is HTTPS against the platform trust store.

---

## Medium

### 3. Client-shipped `.env` exposes a reusable AI proxy bearer token — `pubspec.yaml`

**Root cause found.** `.env` was correctly gitignored (verified: `git log
--all -- .env` is empty — the token never entered git history), **but**
`pubspec.yaml` listed `.env` under `flutter: assets:`. flutter_dotenv reads it
at runtime from the asset bundle — meaning every APK shipped the complete
`.env`, plaintext-readable by anyone who unzips it.

**Fix:**
- Removed `.env` from assets and dropped `flutter_dotenv` entirely.
- All config now arrives at **compile time** via
  `--dart-define-from-file=.env` (new `lib/core/config/app_env.dart` using
  `String.fromEnvironment`). Values compile into the Dart snapshot; the raw
  file never ships.
- `firebase_options.dart`, `chat_service.dart`, `search_service.dart`, and
  `main.dart` migrated. A build made without the flag shows a clear
  "configuration missing" screen instead of crashing.
- Build/run now: `flutter run --dart-define-from-file=.env`.

**Remaining action (manual):** the token from any previously distributed APK
should be treated as burned — rotate the Hack Club API key at
https://ai.hackclub.com/dashboard before submission.

### 4. Unsafe deserialization — kotlin-stdlib (SCA)

**Root cause investigated.** The project's own Kotlin is **2.2.20**
(`android/settings.gradle.kts`), far past the kotlin-stdlib deserialization
CVEs (fixed in the 1.4/1.6 line). The flag targets transitive stdlib versions
that older plugin toolchains can pin lower.

**Fix** (`android/app/build.gradle.kts`): added
`force("org.jetbrains.kotlin:kotlin-stdlib:2.2.20")` to the existing
`resolutionStrategy`, so no dependency can drag a vulnerable 1.x stdlib into
the APK. To the extent the flag referred to the already-current stdlib, it is
an accepted false positive: the app performs no Java serialization of
untrusted input anywhere.

### 5. Exported components / backup configuration — `AndroidManifest.xml`

**Audit result:** `MainActivity` is exported (required — launcher activity,
the one legitimate exception). Both overlay services and the notification
listener were already `exported="false"` (the listener additionally guarded by
the `BIND_NOTIFICATION_LISTENER_SERVICE` system permission). The one genuine
issue was `BootReceiver` (see #6). Backup was implicitly enabled.

**Fix:**
- `android:allowBackup="false"` — nothing local (chat transcripts, cat
  documents, prefs) may leave the device via backup.
- `android:dataExtractionRules="@xml/data_extraction_rules"` — Android 12+
  cloud backup **and** device-to-device transfer both fully excluded.

### 6. Global SharedPreferences chat history leaks across accounts — `chat_history_provider.dart`

**Root cause found.** History was stored under one global key
(`chat_history_v1`); a second Firebase account signing in on the same device
saw the first account's transcripts.

**Fix:**
- Keys are now namespaced per account: `chat_history_v1_<uid>`. The provider
  watches auth state, so an account switch immediately swaps to (only) that
  account's history. Signed out → no reads, no writes.
- The legacy global key is purged on sight (it can't be attributed to an
  account, so it must not survive).
- Sign-out (`AuthController.signOut`) explicitly deletes the signing-out
  user's history key: transcripts never outlive the account session on a
  shared device.

---

## Low

### 7. Exported BootReceiver accepts spoofed QUICKBOOT_POWERON — `BootReceiver.kt`

**Root cause found.** The receiver already had an exact action allow-list
(`BOOT_COMPLETED` / `LOCKED_BOOT_COMPLETED` / `QUICKBOOT_POWERON`) plus two
gates (overlay permission granted, restorable state present) — but it was
`android:exported="true"`, so any app could fire `QUICKBOOT_POWERON` at it.

**Fix:** `android:exported="false"`. Real boot broadcasts come from the
system, which always reaches non-exported receivers; other apps can no longer
trigger the restore flow. The action allow-list stays as defence in depth.

### 8. Registered-email enumeration — `register_screen.dart`

**Root cause found.** `auth_repository.dart` mapped `email-already-in-use` to
"An account already exists with that email." — a free enumeration oracle on
the public sign-up form.

**Fix:** the message no longer confirms registration status ("We couldn't
create your account with those details. Try signing in instead.").

**Remaining action (manual, Firebase console):** enable **Email Enumeration
Protection** (Authentication → Settings) so the backend stops returning
distinguishable error codes at the API level. Console access: Akshat.

### 9. Chat content leaking into production logs on JSON parse failure — `chat_service.dart`

**Root cause found.** The release logger emits `warning` and above. In the two
JSON-parse catch blocks (SSE chunk parse, non-streaming body parse) the raw
exception was logged — and a Dart `FormatException` carries its **source
string** (the chunk / full response body, i.e. conversation content) into the
log.

**Fix:** both sites now log only the exception *type* in release; the full
exception stays available behind `kDebugMode`. (The HTTP-error path already
had this restraint — body snippet in debug, status code only in release.)

---

## Accepted risks (SonarQube)

- **Gradle dependency lock file not added.** Enabling Gradle's strict
  dependency locking within 24h of the deadline would break teammates' builds
  the moment their Flutter SDK resolves slightly different plugin versions
  (locking fails the build on any drift). Versions are already effectively
  pinned: `pubspec.lock` is committed (pins every Dart/Flutter plugin, which
  in turn pins their Android artifacts), and the only direct native
  dependencies are exact-versioned with `resolutionStrategy.force` for the two
  known conflicts. Revisit after the hackathon.
- **BootReceiver intent-filter warning (xml:S5322).** The rule flags any
  receiver with an intent-filter. This receiver is now `exported="false"`,
  keeps an exact action allow-list, and gates on overlay permission +
  persisted state — the spoofing vector the rule targets is closed.

## Out-of-band items for submission

- [ ] Rotate the Hack Club AI key (any previously distributed APK bundled it).
- [ ] Enable Email Enumeration Protection in the Firebase Auth console.
- [ ] Re-run the Aikido scan after these commits and attach the fresh report.
