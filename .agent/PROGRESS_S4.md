# PROGRESS - Sprint S4: Create Wizard + Drag-Drop + Join

**Sprint:** S4 - Create wizard + drag-drop payout ordering + join flow
**Started:** 2026-06-03     **Status:** Codegen blocker RESOLVED (2026-06-04, D025); finishing S4
**Prereqs verified:** Y

## Objective
Build the real destinations behind the existing "Creer / Rejoindre" sheet:
the 5-step create-daret wizard, the signature drag-drop payout ordering with
group splits, invite-code sharing, join-by-code preview, and member approval.
Privileged writes remain Function-owned; no client writes to server-owned
integrity fields.

## Task checklist
- [x] T0 - Onboarding, pull, inherited gate, and S4 progress record
- [x] T1 - Wizard scaffold, routing, progress indicator, and validation
- [x] T2 - Identity, money/rhythm, members, and recap steps
- [x] T-dd1 - Period timeline slots with generated dates and pot amount
- [x] T-dd2 - Drag/drop member placement with tray return behavior
- [x] T-dd3 - Groupe split editor with 100% validation
- [x] T-dd4 - Live assignment validation and disabled submit states
- [x] T-dd5 - Auto-organiser and tirage au sort helpers
- [x] T-dd6 - Assignment controller/model with unit tests
- [x] T-join1 - Invite-code entry, previewDaret, joinDaret, and errors
- [x] T-join2 - Approval review/progress and approveDaret
- [x] T-join3 - createInvite code display and share_plus OS share sheet
- [~] T6 - End-to-end callable wiring and backend generation verification
- [~] T7 - Goldens, docs, commits, deploy/CI/device evidence

## Work log
- 2026-06-03 - Read the operating manual, CONTEXT, DECISIONS, PROGRESS_S3,
  pulled `main` (`Already up to date.`), read the S4 prompt, and skimmed the
  latest 20 commits. Current HEAD is `fc4b364`.
- 2026-06-03 - Verified inherited baseline before code: local Flutter gate
  passed with 48 tests.
- 2026-06-03 - Found `.agent/PROGRESS_S3.md` already dirty with local S3
  documentation edits. Leaving it untouched and staging only S4-related work.
- 2026-06-03 - Read `../src/create.jsx`, `../src/create_order.jsx`, routing,
  the create/join sheet, callable wrappers, daret models/repositories, rules,
  rules tests, Functions handlers, the implementation plan, and seed data.
- 2026-06-03 - Backend-contract finding: Firestore rules allow only a strict
  draft root create by the admin and deny client-created `members`/`periods`,
  while the current `startDaret(daretId)` Function expects those docs to
  already exist. S4 therefore needs `startDaret` to expand a client-owned draft
  payload into server-owned member/period docs, using the existing callable
  wrapper names and without loosening nested-doc rules.
- 2026-06-03 - Implemented the backend S4 contract: `startDaret` expands
  `draftMembers`/`draftPeriods`, validates group assignment and shares, creates
  Function-owned members/periods, and deletes the draft payload; `joinDaret`
  replaces a generic `pending_*` invite placeholder with the real caller UID.
  No contact phone numbers are stored in pending placeholders. Added Functions
  and Firestore rules tests. First Functions rerun compiled and the new test ran
  through, but Jest timed out in shared recursive cleanup; added an explicit
  30s suite timeout and reran green.
- 2026-06-03 - Implemented the Flutter S4 create/join surface: sheet routing,
  five-step create wizard, member selection, drag/drop payout assignment, group
  split editor, createDraft -> startDaret -> createInvite wiring, join-by-code
  preview/confirm, approval review, approve action, and share_plus invite
  sharing. Added domain/widget tests plus structural goldens for the new
  create, join, and approval screens.
- 2026-06-03 - Local gate is blocked in the `Codegen reproduces` step. Both
  `dart run tool/verify.dart` and isolated
  `dart run build_runner build --delete-conflicting-outputs` hang after logging
  `Missing implementation of visitDotShorthandInvocation` from analyzer while
  running `riverpod_generator` on `lib/core/router/router.dart`, plus
  `SDK language version 3.11.0 is newer than analyzer language version 3.9.0`.
  This is NOT green and must not be counted as DoD evidence.
- 2026-06-03 - Attempted a narrow mitigation: converted
  `lib/core/router/router.dart` from a generated `@riverpod GoRouter router`
  provider to a manual `Provider<GoRouter>` with the same public
  `routerProvider` symbol, removing `part 'router.g.dart'` and the
  `riverpod_annotation` import. That did not resolve the codegen hang: the
  user reran build_runner in PowerShell and the same analyzer error appeared.
  Leave this change for the next agent to evaluate; it is uncommitted and not
  proven by the full gate.

- 2026-06-04 - **Diagnosed and fixed the codegen blocker (new session).** Proved via the build_runner
  stack trace that the crash is the **analyzer 7.6.0 summary linker** (`BundleWriter._writeParameterElement`
  → `ResolutionSink._writeNode` → `ThrowingAstVisitor.visitDotShorthandInvocation`) failing to serialize a
  **dot-shorthand default-parameter value** in a `flutter_localizations`-graph dependency. analyzer 7.6.0
  is pinned by `riverpod_generator 2.6.5` (`<8.0.0`); the Flutter 3.41.2/Dart 3.11 ecosystem ships
  dot-shorthand in library APIs. Ruled out: project code (grep-clean), node_modules (1 trivial file), and
  cache (a fully clean `flutter clean`+`rm .dart_tool`+`pub get` build crashed identically); SDK is exactly
  the pinned `90673a4`/`3.41.2`. Per user decision (Option 1): dropped `riverpod_generator`/`riverpod_lint`/
  `riverpod_annotation`/`custom_lint`, kept **Riverpod 2 runtime** with **manual providers**, and bumped the
  codegen toolchain to **analyzer 10.0.1 / build_runner 2.15.0 / freezed ^3.2 / json_serializable ^6.10**.
  Converted 9 provider/controller files; fixed `router.dart` (added the missing S4 routes/imports/AppRoutes
  constants); `myDarets` dropped its unused `status` key; `currentContributions` now takes a
  `(daretId, periodIndex)` record key. Excluded `node_modules` from analysis; scoped the gate's `dart format`
  to `lib test tool` (node_modules template broke `dart format .`); removed the dead `custom_lint` gate step;
  deleted the throwaway S0 smoke files. Recorded **DECISIONS D025**. Riverpod 3 migration → S6 tech-debt.

## Verification evidence

### POST-FIX canonical gate (2026-06-04) — `dart run tool/verify.dart`
Toolchain: analyzer 10.0.1, build_runner 2.15.0, freezed ^3.2, json_serializable 6.11.4,
flutter_riverpod 2.6.1 (runtime), riverpod codegen REMOVED (D025). Flutter 3.41.2 / Dart 3.11.0.
```
═══════════════════════════════════════════════
 SUMMARY
═══════════════════════════════════════════════
  ✅  Resolve dependencies
  ✅  Generate l10n
  ✅  Codegen reproduces
  ✅  Format check
  ✅  Static analysis
  ✅  Tests
═══════════════════════════════════════════════
GATE: PASS ✅  — safe to check DoD boxes.
```
(`flutter analyze --fatal-infos`: No issues found. `flutter test`: All tests passed — 56 tests, incl. the
S4 `create_daret`/`join_approval` goldens and the auth keepAlive-provider regression test.)

### Inherited baseline - `dart run tool/verify.dart`
```
SUMMARY
  Resolve dependencies: PASS
  Generate l10n: PASS
  Codegen reproduces: PASS
  Format check: PASS
  Static analysis: PASS
  Custom lint (riverpod): PASS
  Tests: PASS (48 tests)
GATE: PASS
```

### Backend S4 contract - `npm test`
```
Test Suites: 2 passed, 2 total
Tests:       20 passed, 20 total
Snapshots:   0 total
Time:        18.722 s, estimated 28 s
Ran all test suites matching rules-tests.
Test Suites: 1 passed, 1 total
Tests:       14 passed, 14 total
Snapshots:   0 total
Time:        24.325 s, estimated 33 s
Ran all test suites.
```

### S4 Flutter slice - targeted analyze/tests/goldens
```
flutter analyze --fatal-infos lib\features\create_daret lib\features\join_daret lib\features\darets\data\daret_callable_repository.dart lib\features\shell\presentation\create_join_sheet.dart lib\core\router\router.dart test\features\create_daret test\features\join_daret
Analyzing 7 items...
No issues found! (ran in 29.2s)
```

```
flutter test --update-goldens test\features\join_daret\presentation\join_approval_golden_test.dart
00:00 +0: loading C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/join_daret/presentation/join_approval_golden_test.dart
00:00 +0: Join and approval screens (variant: CI)
00:08 +1: All tests passed!
```

```
flutter test test\features\create_daret test\features\join_daret
00:00 +0: loading C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/create_daret/domain/create_daret_logic_test.dart
00:00 +0: C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/create_daret/domain/create_daret_logic_test.dart: CreateDaretLogic generates future dates from the global echeance setting
00:00 +1: C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/create_daret/domain/create_daret_logic_test.dart: CreateDaretLogic moves a participant between slots without duplicating them
00:00 +2: C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/create_daret/domain/create_daret_logic_test.dart: CreateDaretLogic auto-organizes overflow members into a valid group split
00:00 +3: C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/create_daret/domain/create_daret_logic_test.dart: CreateDaretLogic rejects group shares that do not total 100 percent
00:00 +4: C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/create_daret/domain/create_daret_logic_test.dart: CreateDaretLogic pending invite draft data stays generic and phone-free
00:04 +5: C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/create_daret/presentation/create_daret_golden_test.dart: Create daret wizard (variant: CI)
00:12 +6: C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/create_daret/presentation/create_daret_screen_test.dart: dragging a tray member places them into a period slot
00:27 +7: C:/Users/harchane/Tant_in_design/tantinFlutter/test/features/join_daret/presentation/join_approval_golden_test.dart: Join and approval screens (variant: CI)
00:30 +8: All tests passed!
```

### BLOCKED - local gate/codegen failure
```
dart run tool/verify.dart
...
▶ Codegen reproduces:  dart run build_runner build --delete-conflicting-outputs
...
log output for riverpod_generator on lib/core/router/router.dart
E Exception: Missing implementation of visitDotShorthandInvocation
...
log output for build_runner
W SDK language version 3.11.0 is newer than `analyzer` language version 3.9.0. Run `flutter packages upgrade`.
Log overflowed the console, switching to line-by-line logging.
```

```
dart run build_runner build --delete-conflicting-outputs
55s riverpod_generator on 105 inputs: 90 skipped, 1 same, 14 no-op; spent 42s analyzing, 7s resolving, 5s reading
0s freezed on 105 inputs: 90 skipped, 15 no-op
0s json_serializable on 210 inputs: 20 skipped; spent 4s reading, 4s resolving; lib/core/router/router.dart
0s source_gen:combining_builder on 210 inputs

Building, incremental build.

log output for riverpod_generator on lib/core/router/router.dart
E Exception: Missing implementation of visitDotShorthandInvocation
...
log output for build_runner
W SDK language version 3.11.0 is newer than `analyzer` language version 3.9.0. Run `flutter packages upgrade`.
Log overflowed the console, switching to line-by-line logging.
```

## Handoff for next agent
- Worktree is dirty. Pre-existing user/other-agent file: `.agent/PROGRESS_S3.md`
  was already modified before S4 work and should not be staged unless the user
  explicitly asks.
- Backend S4 contract is committed as `8fd9341`. UI/tests/docs after that commit
  are uncommitted.
- Important uncommitted S4 files:
  - `lib/features/create_daret/domain/create_daret_models.dart`
  - `lib/features/create_daret/data/create_daret_repository.dart`
  - `lib/features/create_daret/data/create_daret_providers.dart`
  - `lib/features/create_daret/presentation/create_daret_controller.dart`
  - `lib/features/create_daret/presentation/screens/create_daret_screen.dart`
  - `lib/features/join_daret/presentation/screens/join_daret_screen.dart`
  - `lib/features/join_daret/presentation/screens/approval_screen.dart`
  - `lib/features/darets/data/daret_callable_repository.dart`
  - `lib/features/shell/presentation/create_join_sheet.dart`
  - `lib/core/router/router.dart`
  - `test/features/create_daret/**`
  - `test/features/join_daret/**`
- Generated S4 golden baselines exist at:
  - `test/features/create_daret/presentation/goldens/ci/s4_create_daret_wizard.png`
  - `test/features/join_daret/presentation/goldens/ci/s4_join_approval.png`
- Last proven Flutter evidence before the codegen blocker:
  targeted S4 analyze passed, golden update passed, and
  `flutter test test\features\create_daret test\features\join_daret` passed
  with 8 tests. The canonical full gate has NOT passed after S4 changes.
- Suggested next debugging path:
  1. Stop any leftover `dart run build_runner` process before retrying.
  2. Decide whether to keep or revert the manual `routerProvider` change.
  3. Resolve the analyzer mismatch. `flutter pub outdated` showed
     `build_runner 2.15.0` and `analyzer 8.4.0` are resolvable, but Riverpod
     runtime must stay v2 per S4 rules/D003. If upgrading dev tooling, record
     the decision in `.agent/DECISIONS.md`, avoid `any`, and rerun the canonical
     gate.
  4. Only after `dart run tool/verify.dart` passes, continue with commit, deploy,
     device E2E, push, and CI proof.

## Blockers / questions for the user
- [x] RESOLVED (2026-06-04, D025): the `visitDotShorthandInvocation` codegen crash was the analyzer-7.6.0
  summary linker (pinned by riverpod_generator 2.6.5) vs the Dart 3.11 ecosystem. Fixed by dropping
  riverpod codegen (manual Riverpod 2 providers) + moving the toolchain to analyzer 10. Gate now green
  (see Verification evidence). Riverpod 3 migration is logged as **S6 tech-debt**.
- Remaining (not blockers, normal S4 close-out, need user authorization to push): commit the work, push,
  prove CI green (`dart run tool/check_ci.dart`), deploy any cloud config, and run the Android device
  walkthrough of the create/join/approval flows.

## Commits this sprint
- `8fd9341` feat(functions): expand S4 daret drafts

## Definition of Done gate
- [ ] Every task above is implemented and verified
- [ ] `dart run tool/verify.dart` -> `GATE: PASS` with output pasted
- [ ] Backend lint/tests + security-rules emulator tests pass with output pasted
- [ ] CI is green for pushed commit with output pasted
- [ ] New UI visually matches prototype and has committed goldens
- [ ] App builds and touched flows run on Android
- [ ] `CONTEXT.md`, `DECISIONS.md`, and this file are current
- [ ] All work committed per task and pushed
- [ ] No secrets/private keys committed
- [ ] Cloud config changes deployed and verified live or marked blocked
- [ ] Sprint S4 complete summary posted

**Sprint sign-off:** Pending.
