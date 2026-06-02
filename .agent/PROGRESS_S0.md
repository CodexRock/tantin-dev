# PROGRESS_S0: Architecture & Technical Setup

**Objective:** Stand up a clean, correct, runnable Flutter app skeleton wired to Firebase, with the design tokens, theming, fonts, routing shell, state management, l10n, lints, CI, and the `.agent/` memory system — so that every later sprint drops into a solid foundation.

**Status:** ✅ Complete (after remediation — see "Remediation" below). Gate verified by running the toolchain, not by assertion.

## Task Checklist
- [x] **A. Project scaffold** (T1, T2)
- [x] **B. Dependencies & tooling** (T3, T4)
- [x] **C. Firebase wiring** (T5, T6, T7)
- [x] **D. Design system foundation** (T8)
- [x] **E. Navigation shell + l10n** (T9, T10)
- [x] **F. Memory system + CI + first run** (T11, T12, T13)

## Work Log
- Verified prerequisites (flutter doctor).
- Scaffolding via `flutter create`; git set up and pushed to `main`.
- Resolved initial Riverpod/lint version solving by downgrading Riverpod to v2.
- Generated baseline `firestore.rules` and `firebase.json`; ran `flutterfire configure`.
- Implemented `lib/main.dart` (Firebase init, App Check, Crashlytics handlers, Firestore persistence, Analytics, overlay style).
- Set up `TantinColors/Shadows/Motion/Radii`, `TantinTheme`, `TantinFormat.fmtDH`.
- Configured GoRouter (5-tab `StatefulShellRoute`) and French l10n.
- Created `.agent/` tracking files.

## Remediation (S0 audit, 2026-06-02)
An audit found the original "all green" report was inaccurate — the gate had not actually been run. Fixes applied:
1. **freezed 3.x compile error** — `SmokeModel` was a bare `class`; changed to `abstract class` (D005). This was the real cause of the `non_abstract_class_inherits_abstract_member` error (not an analyzer-config artifact).
2. **Deprecated Riverpod `Ref` typedefs** — migrated all per-provider `FooRef` to the shared `Ref` (added `flutter_riverpod` import where needed).
3. **30 lint infos** — fixed import ordering + `package:` imports in `main.dart`/`theme.dart`, constructor/required-param ordering in `motion.dart`, `const ColorScheme` + redundant-arg in `theme.dart`, long comment in `format.dart`.
4. **custom_lint plugin crash** — `any` constraints let `riverpod_lint` drift to 3.1.3, leaving a stale `.dart_tool/custom_lint` client. Pinned all codegen/lint dev-deps (D004), cleared the cache, re-ran `pub get`. `dart run custom_lint` now passes.
5. **Generated-code git limbo** — `*.g.dart`/`*.freezed.dart` now git-ignored; CI regenerates them (D004).
6. **Firebase rules** — baseline `request.auth != null` Firestore rules **deployed** to `tantin-dev` (no longer open test mode). Added `storage.rules` + wired into `firebase.json` (deploy pending bucket provisioning — see Blockers).
7. **pubspec description** — replaced the default placeholder.

## Verification Evidence (commands actually run, 2026-06-02)
- `flutter analyze` → **No issues found!** (0 issues)
- `dart run custom_lint` → **No issues found!** (analyzer plugin starts cleanly)
- `flutter test` → **All tests passed!** (4/4: 3 format + 1 widget boot test)
- `dart format .` → clean (no files changed)
- `dart run build_runner build --delete-conflicting-outputs` → codegen reproduces (9 outputs)
- `firebase deploy --only firestore:rules --project tantin-dev` → **Deploy complete!** (rules live)

## Definition of Done (Gate)
- [x] Every task in the sprint's checklist is `[x]` and implemented.
- [x] `dart format .` is clean and `flutter analyze` reports zero issues (verified above).
- [x] `dart run custom_lint` reports zero issues (analyzer plugin healthy).
- [x] All tests for this sprint pass (4/4, verified above).
- [x] New/changed UI visually compared to prototype (S0 ships placeholders only; pixel-parity work begins S1).
- [x] App builds and runs on Android (google-services.json + gradle plugin wired; debug APK builds in CI).
- [x] Baseline Firestore security rules deployed (no longer open test mode).
- [x] `CONTEXT.md`, `DECISIONS.md`, and `PROGRESS_S0.md` updated honestly.
- [x] All work committed and pushed.
- [x] No secrets committed.

## Blockers / Follow-ups (carried into S1)
- **Storage rules not deployed:** `firebase deploy --only storage` fails with "Failed to fetch default storage bucket." Needs the user to finish Storage setup in the Firebase console (region europe-west1), then re-run `firebase deploy --only storage --project tantin-dev`. Config (`storage.rules`, `firebase.json`) is ready. Non-blocking — no feature uses Storage yet.
- **Dependencies are minimal (just-in-time):** animation/UI/contacts/image/permission packages and test tooling (mocktail, fake_cloud_firestore, golden testing, integration_test) are deferred to the sprint that first needs them. S1 adds its UI + test deps.
