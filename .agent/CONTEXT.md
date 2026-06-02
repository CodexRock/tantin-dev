# Tant'in Context

**Current Sprint:** S0

## Project Status
The project is currently in the initial setup phase. A Flutter app (`tantin_flutter`) has been scaffolded and connected to the `tantin-dev` Firebase project. Design tokens, theming, Riverpod codegen, go_router, and l10n have been wired up. The app boots to a placeholder 5-tab shell.

## Architecture & Folder Map
- `lib/core/`: Application-wide concerns (routing, formatting, tokens, theme, providers).
- `lib/core/firebase/`: Exposes Firebase services via Riverpod providers.
- `lib/l10n/`: French localization (ARB files).
- `lib/main.dart`: Entrypoint, Firebase initialization, App Check, Crashlytics, Analytics, `SystemUiOverlayStyle`.
- `test/`: Unit and widget tests.

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
- Forbidden: `any` version constraints (the gate rejects them) — pin everything (D004).

## Known Gotchas
- Firestore (Native Mode) now has a **baseline `request.auth != null` rule deployed** (no longer open test mode). Full least-privilege state-machine rules come in a later sprint.
- **Storage rules are NOT yet deployed:** `storage.rules` + `firebase.json` are ready, but `firebase deploy --only storage` fails with "Failed to fetch default storage bucket" — the default bucket isn't provisioned/reachable yet. **User follow-up:** finish Storage setup in the Firebase console (Storage → Get started, region europe-west1), then re-run `firebase deploy --only storage --project tantin-dev`. Not blocking S0/S1 (no feature uses Storage yet).
- Generated `*.g.dart`/`*.freezed.dart` are git-ignored — run `dart run build_runner build --delete-conflicting-outputs` after a fresh clone (CI does this automatically). See DECISIONS D004.
- Dependency set is intentionally minimal (just-in-time). Packages for animation/confetti/SVG/contacts/image-picker/permissions and test tooling (mocktail, fake_cloud_firestore, golden testing, integration_test) are added in the sprint that first needs them — S1 adds its UI/test deps.
- Do not commit service-account JSON keys or FCM server keys.

## What's Done / What's Next
- **Done:** S0 architecture setup, S1 Component library & Design system. Design tokens, shared components, SVG-based icons/zellige art, motion helpers, and gallery are implemented and verified with golden tests.
- **Next:** S2 (or further feature sprints) to start implementing functional screens using the design system.
