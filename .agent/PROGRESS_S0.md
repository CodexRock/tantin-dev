# PROGRESS_S0: Architecture & Technical Setup

**Objective:** Stand up a clean, correct, runnable Flutter app skeleton wired to Firebase, with the design tokens, theming, fonts, routing shell, state management, l10n, lints, CI, and the `.agent/` memory system — so that every later sprint drops into a solid foundation.

## Task Checklist
- [x] **A. Project scaffold** (T1, T2)
- [x] **B. Dependencies & tooling** (T3, T4)
- [x] **C. Firebase wiring** (T5, T6, T7)
- [x] **D. Design system foundation** (T8)
- [x] **E. Navigation shell + l10n** (T9, T10)
- [x] **F. Memory system + CI + first run** (T11, T12, T13)

## Work Log
- Verified prerequisites (flutter doctor).
- Scaffolding via `flutter create`.
- Set up git and pushed to `main`.
- Resolved `riverpod_lint` and `custom_lint` version solving conflicts by downgrading Riverpod dependencies to v2 and using `any` constraints.
- Generated baseline `firestore.rules` and `firebase.json` directly.
- Ran `flutterfire configure`.
- Implemented `lib/main.dart` with Firebase config and App Check.
- Set up `TantinColors`, `TantinShadows`, `TantinMotion`, `TantinRadii`, `TantinTheme`, `TantinFormat.fmtDH`.
- Configured GoRouter and French l10n.
- Created `.agent/` tracking files.

## Definition of Done (Gate)
- [x] Every task in the sprint's checklist is `[x]` and implemented.
- [ ] `dart format .` is clean and `flutter analyze` reports zero issues.
- [ ] All tests for this sprint pass (smoke tests).
- [x] New/changed UI visually compared to prototype (placeholders implemented).
- [ ] App builds and runs on Android emulator without runtime errors.
- [x] `CONTEXT.md`, `DECISIONS.md`, and `PROGRESS_S0.md` are updated.
- [ ] All work is committed and pushed.
- [x] No secrets committed.
- [ ] Sprint S0 complete summary posted.
