# Neko — Defect Register

Findings from the continuous audit. Status reflects the current tree.
Verification baseline: `flutter analyze` 0 issues · `flutter test` 4/4 · release APK builds (21.6MB).

## Critical (crash / data loss / security)
| ID | Location | Description | Status |
|---|---|---|---|
| C001 | release-key.jks | Private signing keystore tracked in git (and pushed) | FIXED (untracked + gitignored); **key must be rotated — see SECURITY_SCAN.md** |
| C002 | android/gradle/wrapper | AGP 8.11.1 requires Gradle ≥8.13; wrapper pinned to 8.9 → release build failed | FIXED (→8.13) |

## High (broken feature / user-visible error / corruption)
| ID | Location | Description | Status |
|---|---|---|---|
| H001 | features/chat | AI assistant never received the cat profile → only generic answers | FIXED (catContext injected via CatProfile.toAIContext) |
| H002 | onboarding/data/onboarding_options.dart | 6/12 coats shared duplicate `colorType` values → wrong data saved | FIXED (unique values = themeId; catColorFor extended) |
| H003 | onboarding/ui/onboarding_flow_view.dart | First-run step-1 back button was a dead no-op; system back exited app | FIXED (confirm-exit + sign-out; PopScope intercept) |
| H004 | core+features media | Dead `LocalStorageService` vs live Firebase Storage (two media systems) | FIXED (went local; Firebase Storage removed) |

## Medium (incorrect behavior, not a crash)
| ID | Location | Description | Status |
|---|---|---|---|
| M001 | onboarding/ui/steps/age_step.dart | Months accepted 0–99 → "99 months" stored as ~8 years | FIXED (clamp 0–11 / years 0–30) |
| M002 | onboarding/providers/onboarding_provider.dart | `save()` could write state after disposal | FIXED (`_disposed` guard — riverpod 2.x) |
| M003 | app/theme/app_theme.dart | Form error borders used coral (primaryDark), not red | FIXED (→ AppColors.danger) |
| M004 | features/chat/data/chat_service.dart | Non-2xx logged the full upstream body | FIXED (status only in release; debug snippet) |
| M005 | core/services/audio_service.dart | ~22 SoundIds mapped to missing files → mostly silent | FIXED (fallbacks to shipping clips) |
| M006 | cat_avatar, photo_step, chat_* | Local images decoded at full resolution into memory | FIXED (cacheWidth/cacheHeight downsampling) |

## Low (polish / correctness)
| ID | Location | Description | Status |
|---|---|---|---|
| L001 | README.md / SECURITY_SCAN.md | Storage + "no committed secrets" claims were false | FIXED |
| L002 | assets/ | Unreferenced .lottie / neko.riv / audio .wav inflated the bundle | FIXED (removed) |
| L003 | cat_profile.toAIContext | Weight rendered as "4.0kg" into the prompt | FIXED (formatted) |
| L004 | chat_screen.dart | `MediaQuery.of` where `sizeOf` suffices | FIXED |
| L005 | onboarding_state.dart | Default step 0 vs notifier start step 1 | FIXED (→1, dead case removed) |
| L006 | weight_step / age_step | Inconsistent autofocus vs name step | FIXED |
| L007 | edit_cat_screen.dart | AppBar title re-read live controller each build | FIXED (captured original name) |
| L008 | onboarding_repository.dart | `avatarPreset: null` written explicitly | FIXED (omit when null) |

## Open — require a decision or are deliberately deferred
| ID | Location | Description | Status |
|---|---|---|---|
| O001 | core/widgets/neko_button.dart | Two competing CTA button systems | FIXED — unified to one Chiclet-based `NekoButton` (primary/secondary/ghost); `NekoPrimaryButton` + `NekoPillButton` retired; `NekoTextButton` kept for text links |
| O002 | ~34 files | `SizedBox` literal spacing vs `AppSpacing` tokens (low-risk, high-churn) | DEFERRED — cosmetic; mechanical sweep |
| O003 | app_colors + 6 sites | Hardcoded `Colors.black12/26/38` shadows invisible on the Midnight Black dark palette | FIXED — theme-aware `AppColors.shadowSoft/Medium/Strong` |
| O004 | onboarding | Draft/step not persisted across process death | FIXED — `OnboardingDraft` JSON + `saveDraft`/`loadDraft`/`clearDraft`; restore on build, clear on save/reset |

## Verified NON-issues (investigated, not defects)
- Nav pill "clips scroll content": false positive — the pill is a real `Scaffold.bottomNavigationBar` that reserves its slot; adding padding would only create dead space.
- `dart fix` const sweep: "Nothing to fix" — the tree is already const-clean.
- No `ElevatedButton`/`FilledButton`/`OutlinedButton`/`CupertinoButton` instances exist (only `.styleFrom` theme defaults).
- No `print()` in lib; no `Navigator.push` (only `Navigator.pop` for dialogs/sheets — correct with GoRouter).
