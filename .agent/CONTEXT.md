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
- Run `flutter test` for unit and widget tests.
- Run `flutter analyze` and `dart format .` before pushing.
- CI via GitHub Actions runs on every push.

## Known Gotchas
- Firestore is currently in Native Mode with open test rules. S3 will implement full least-privilege rules.
- Do not commit service-account JSON keys or FCM server keys.

## What's Done / What's Next
- **Done:** S0 architecture setup.
- **Next:** S1 Component library & Design system.
