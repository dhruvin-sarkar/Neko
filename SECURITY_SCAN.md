# Security

## Aikido scan

The #hackthekitty rules include an Aikido security scan. To run it on this repo:

1. Sign in at https://app.aikido.dev with the team account.
2. Connect this GitHub repository (or run the Aikido CLI against a local clone).
3. Start a scan and let it complete (dependencies, secrets, SAST, IaC).
4. Export the report and paste the summary below before submission.

### Scan results

_To be filled in by the team after running the scan:_

- Date:
- Critical:
- High:
- Medium / Low:
- Link to report:

## Manual security measures in place

- **Firestore rules** (`firestore.rules`): every read/write is restricted to the
  signed-in user's own `users/{uid}` tree. A catch-all rule denies everything
  else, for authenticated and unauthenticated requests alike. No public reads.
- **No committed secrets**: Firebase config and the Hack Club AI key load from
  `.env` at runtime via `flutter_dotenv`. `.env` and `google-services.json` are
  gitignored; `.env.example` ships placeholders only.
- **No secrets in source**: a grep of `lib/` for keys/tokens returns no hardcoded
  values — the only references read from `dotenv`.
- **No PII in logs**: there are no raw `print`/`debugPrint` calls; logging goes
  through `AppLogger`, which is documented to never receive secrets or PII and
  only runs in debug.
- **Input handling**: text inputs are trimmed and length-capped before save, and
  stored text is only ever rendered as plain text (no HTML/web view).

## Recommended before submission

- Run the Aikido scan and fill in the results above.
- For sensitive document screens, consider `zo_screenshot` to block screen
  capture (not yet wired — see notes in the project plan).
