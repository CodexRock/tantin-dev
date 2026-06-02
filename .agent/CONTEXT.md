# Tant'in Context

**Current Sprint:** S1 complete (audited + remediated) → S2 next

## Project Status
Flutter app (`tantin_flutter`) scaffolded and connected to the `tantin-dev` Firebase project.
- **Firebase Auth (S2):** Implemented for phone sign-in. Use test numbers to avoid SMS costs during development:
  - `+212 6 00 00 00 00` (code `123456`)
  - `+212 6 11 11 11 11` (code `111111`)

The app boots to a placeholder 5-tab shell; a dev-only gallery route renders every component. S1 design system & component library are built and golden-tested.

## Architecture & Folder Map
- `lib/core/`: Application-wide concerns (routing, formatting, tokens, theme, providers, motion).
- `lib/core/firebase/`: Exposes Firebase services via Riverpod providers.
- `lib/core/motion/`: Reveal, FadeIn, Pressable, StaggeredReveal, page transitions, confetti — all reduced-motion aware via `MediaQuery.disableAnimationsOf`.
- `lib/design_system/`: `components/` (Avatar, Button, Card, CountUp, EmptyBlock, ProgressRing, ScreenHeader, Segmented, Sheet, Skel, StateBadge, Toast), `icons/` (TnIcons), `art/` (TnArt zellige), `gallery/` (dev route), and `design_system.dart` barrel. Components reference `core/theme` tokens only — no literal hex/spacing.
- `lib/l10n/`: French localization (ARB files).
- `lib/main.dart`: Entrypoint, Firebase init, App Check, Crashlytics, Analytics, `SystemUiOverlayStyle`.
- `test/`: unit + widget tests, golden tests (`design_system_test.dart`), goldens in `test/goldens/ci/`.

## Key Conventions
- **Feature-first architecture:** Upcoming sprints will organize by feature (e.g. `lib/features/daret/`).
- **State Management:** Riverpod 2 with codegen (`riverpod_annotation`, `riverpod_generator`).
- **Models:** `freezed` + `json_serializable`.
- **Language:** French only (`app_fr.arb`).
- **Currency:** Dirham, formatted via `TantinFormat.fmtDH` with spaces (e.g. `1 500 DH`).

## Environment / Setup Commands
- `flutter pub get`: Fetch dependencies.
- `dart run build_runner build --delete-conflicting-outputs`: Generate Riverpod providers, Freezed models, JSON serialization, and GoRouter routes.
- `flutter gen-l10n`: Generate localizations.

## Testing & CI
- **Canonical gate: `dart run tool/verify.dart`** — the single source of truth for "is it green?".
  Runs pub get, gen-l10n, build_runner, `dart format --set-exit-if-changed`, `flutter analyze
  --fatal-infos`, `dart run custom_lint`, and `flutter test`; prints `GATE: PASS`/`GATE: FAIL`.
  Use `--fast` to skip pub/codegen for quick re-checks, `--ci` to also build the APK.
- **Never check a Definition-of-Done box without pasting this gate's output** (see the Operating
  Manual's Prime Directive). CI runs the exact same script (`dart run tool/verify.dart --ci`), so
  local-green == CI-green.
- **After pushing, prove CI is actually green: `dart run tool/check_ci.dart`** — it finds the Actions
  run for HEAD, waits for it to finish, and exits non-zero unless it's `success`. A sprint is not done
  until this prints `CI: GREEN`. (Set `GITHUB_TOKEN` to avoid the 60/hour unauthenticated rate limit.)
- Forbidden: `any` version constraints (the gate rejects them) — pin everything (D004).

## Golden-test workflow (D008)
- Goldens use **alchemist**; only CI goldens run (deterministic block-text) → identical on Windows & Linux CI. Baselines committed in `test/goldens/ci/`.
- Render scenarios with `MediaQuery(disableAnimations: true)` for a deterministic final frame.
- To intentionally change a component's look: `flutter test --update-goldens`, then eyeball the diff before committing. Never blind-update.
- `test/**/failures/` and `test/goldens/{windows,macos,linux}/` are git-ignored; the gate **fails** if a `failures/` dir exists (a committed failure artifact masked a red sprint in S1).

## Known Gotchas
- Firestore (Native Mode) has a **baseline `request.auth != null` rule deployed** (not open test mode). Full least-privilege state-machine rules come in a later sprint.
- **Storage rules ARE deployed** to `tantin-dev` via a storage target (`.firebaserc` maps target `main` → `tantin-dev.firebasestorage.app`; `firebase.json` storage block references it). Baseline `request.auth != null`. `firebase deploy --only storage --project tantin-dev` works.
- Generated `*.g.dart`/`*.freezed.dart` are git-ignored — run `dart run build_runner build --delete-conflicting-outputs` after a fresh clone (CI does this automatically). See DECISIONS D004.
- Dependency set is just-in-time. Remaining packages (confetti is in via motion; contacts/image-picker/permissions, mocktail, fake_cloud_firestore, integration_test) are added in the sprint that first needs them.
- Do not commit service-account JSON keys or FCM server keys.

## What's Done / What's Next
- **Done:** S0 architecture setup; S1 design system & component library (tokens, components, SVG icons/zellige art, motion, gallery) — verified with 10 alchemist goldens + 5 interactive widget tests, gate green, CI green. One real bug fixed in remediation (AvatarStack `+N`).
- **Next:** S2 — start building functional screens (auth/onboarding) from the design-system primitives. Reuse components; do not re-implement them. Add S2's data/test deps just-in-time.
