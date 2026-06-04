# PROGRESS - Sprint S4: Create Wizard + Drag-Drop + Join

**Sprint:** S4 - Create wizard + drag-drop payout ordering + join flow
**Started:** 2026-06-03     **Status:** Device bug fixes CI GREEN; Functions deploy user-reported; device retest pending
**Prereqs verified:** Y

## Objective
Build the real destinations behind the existing "Creer / Rejoindre" sheet:
the 5-step create-daret wizard, the signature drag-drop payout ordering with
group splits, invite-code sharing, join-by-code preview, and member approval.
The client writes only the rules-constrained draft root described in D024; all
privileged state transitions and server-owned member/period/contribution writes
remain Function-owned.

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

- 2026-06-04 - Verification/self-review pass (no S5 work). Confirmed S4 routes from the global "+" sheet
  go to the real create/join screens; S4 approval/share screen is separate from the read-only daret hub
  stub; App Check remains OFF in dev per D022; D025 manual Riverpod providers are reflected in CONTEXT and
  DECISIONS. Reviewed create wizard/order/join/approval code against the S4 prompt and found one S4 bug:
  the group split bottom sheet was built from a stale slot snapshot, so +/- changed controller state but the
  open sheet did not redraw the visible percentages/total live. Fixed it by making the sheet body watch
  `createDaretControllerProvider` while open and added a widget regression test:
  `group split sheet redraws share totals live`.
- 2026-06-04 - User ran `dart run tool/verify.dart` after the verification fix and pasted a green gate:
  dependency resolution, l10n, build_runner, format, `flutter analyze --fatal-infos`, and `flutter test`
  all passed; tests ended at `00:42 +57: All tests passed!`; final line was `GATE: PASS`.
- 2026-06-04 - Physical-device creation walkthrough found two blockers: (1) Step 2/3 used member count
  rather than period count for the displayed cagnotte and used full-member contributions for grouped
  recipients; (2) final submit failed at `startDaret` with `[firebase_functions/unauthenticated]
  UNAUTHENTICATED` in the physical-device stack trace. Fixed the math model in Flutter and Functions:
  gross cagnotte = `montant * periodesCount`; period payout = `montant * (periodesCount - 1)`; a group
  slot is one share, so 40/60 members pay 40/60 of the base amount and receive 40/60 of the payout from
  the other shares. Added Flutter domain tests and a Functions regression covering grouped recipients.
  Added a client callable auth guard that force-refreshes the Firebase ID token before every callable.
  Note: App Check remains disabled in source per D022; if the device still returns unauthenticated after
  deploying this Functions bundle, verify the live Functions deployment and Auth session/debug token state.
- 2026-06-04 - User reran `dart run tool/verify.dart` after the period-share/auth fixes. Fresh gate is
  green for the current device-bug-fix tree: dependencies, l10n, codegen, format, static analysis, and
  tests all passed; tests ended at `00:28 +59: All tests passed!`; final line was `GATE: PASS`.
- 2026-06-04 - User reported running `firebase deploy --only functions --project tantin-dev` after the
  device-bug-fix commits were pushed. Deploy output was not pasted, so this is recorded as user-reported
  deployment rather than command-output evidence. Post-fix physical-device retest is planned for
  2026-06-05.

## Verification evidence

### Post-review verification fix canonical gate (2026-06-04) - `dart run tool/verify.dart`
User-run from `C:\users\harchane\Tant_in_design\tantinFlutter` after the group split sheet live-redraw fix:
```
SUMMARY
  Resolve dependencies: PASS
  Generate l10n: PASS
  Codegen reproduces: PASS
  Format check: PASS
  Static analysis: PASS
  Tests: PASS (00:42 +57: All tests passed!)
GATE: PASS
```

### POST-FIX canonical gate (2026-06-04) — `dart run tool/verify.dart`
This PASS was recorded before the 2026-06-04 verification fix to the group split sheet. It proves the
committed S4 implementation through `a3baca3`; the current dirty working tree is proven by the
post-review verification fix gate above.

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

### Backend grouped-share regression after device bug (2026-06-04) - `npm test`
Agent-run after fixing the period-share math:
```
Rules: Test Suites: 2 passed, 2 total; Tests: 20 passed, 20 total.
Functions: Test Suites: 1 passed, 1 total; Tests: 15 passed, 15 total.
New coverage: grouped recipients are one share; 40/60 group on base 1000 generates 400/600 monthly
contributions and 40/60 of the period payout.
```

### Fresh Flutter gate after device bug fixes (2026-06-04) - `dart run tool/verify.dart`
User-run from `C:\users\harchane\Tant_in_design\tantinFlutter`:
```
SUMMARY
  Resolve dependencies: PASS
  Generate l10n: PASS
  Codegen reproduces: PASS
  Format check: PASS
  Static analysis: PASS
  Tests: PASS (00:28 +59: All tests passed!)
GATE: PASS
```

### CI proof after device bug fix (2026-06-04) - GitHub Actions
Checked run `26922657221` for pushed HEAD `1673c1c8ed935da17dbf51f65a97ddd9b6607ef7`:
```
CI: GREEN
backend: success
verify: success
Run: https://github.com/CodexRock/tantin-dev/actions/runs/26922657221
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

### Historical blocker - local gate/codegen failure (resolved by D025)
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

## Current close-out state
- Worktree is dirty. Pre-existing user/other-agent file: `.agent/PROGRESS_S3.md`
  was already modified before this close-out pass and should not be staged unless
  the user explicitly asks.
- S4 implementation is committed through `a3baca3`; docs-only commit `9024973`
  was marked `[skip ci]`. Device-bug-fix commit `80dae7b` corrects period-share
  math, adds callable auth token refresh, and updates tests/docs after the
  fresh user-run gate passed. It has been pushed to `origin/main`.
- CI evidence is **GREEN for `1673c1c`** (run 26922657221, both `verify` and
  `backend` jobs success, checked via GitHub Actions API). Earlier CI evidence
  was also green for `a3baca3` (run 26917868600, user-confirmed). Do not claim
  device proof or live Functions proof until the user reruns the walkthrough.
- Verification review found and fixed one S4 UI bug in the group split editor:
  the open split sheet now redraws live while +/- changes shares. User-run
  `dart run tool/verify.dart` passed after the fix.
- Physical-device creation testing then found incorrect period-share math and
  `[firebase_functions/unauthenticated]` on final submit. The current tree fixes
  both locally and is covered by Flutter + Functions regression tests. The user
  reran `dart run tool/verify.dart` and pasted `GATE: PASS` for this tree.
- Generated S4 golden baselines are committed:
  - `test/features/create_daret/presentation/goldens/ci/s4_create_daret_wizard.png`
  - `test/features/join_daret/presentation/goldens/ci/s4_join_approval.png`
- Device walkthrough result: **[~] BLOCKED pending post-fix device retest.** The
  first physical create run found blockers; the fixed Functions bundle deploy
  is user-reported complete but deploy output was not pasted. The S3 regression
  screens and S4 create/invite/join/approve flow must be rerun on device. The
  agent cannot run Flutter/device commands in this environment and must not
  claim that result.

## Self-review vs S4 spec (2026-06-04)
- Wizard/spec: 5-step create flow is present (identity, money/rhythm, members, order/periods, recap),
  with progress indicator and per-step validation. It follows `../src/create.jsx` / `../src/create_order.jsx`
  structurally: cover/accent, amount/frequency/count, members from previous darets/fallback app users/
  contacts-as-pending-invites, drag/drop order, group split editor, recap submit.
- Split validation: `CreateDaretLogic.validateAssignment` enforces every period filled, every selected member
  placed exactly once, and group shares summing to 100. The verification fix makes the open group editor
  redraw share values/totals live while editing.
- Plus sheet: the global "+" sheet routes "Creer un daret" and "Rejoindre avec un code" to real S4 screens.
  The remaining SnackBars are only the debug `seedDev` action and normal error/success feedback, not route
  stubs.
- Do not over-ask: no per-daret rules/echeance wizard step exists. The draft records global default
  `echeanceDay` / `graceDays` from the user's settings.
- Write boundary: client creates only the strict `brouillon` draft root permitted by rules/D024. `startDaret`,
  `createInvite`, `previewDaret`, `joinDaret`, and `approveDaret` go through `DaretCallableRepository`; server
  status transitions, member docs, period docs, contributions, invites, activity, and notifications are
  Function-owned. App Check remains OFF in dev per D022; this file does not change it.
- Scope guards: no S5 daret hub, two-sided payment confirmation, payout, or celebration work was added.
  Daret-card taps and the Accueil hero route still go to the read-only hub stub.
- Goldens: S4 create/join/approval golden tests exist via `goldenTest`; baselines are committed in the S4
  golden paths listed above.

## Blockers / questions for the user
- [x] RESOLVED (2026-06-04, D025): the `visitDotShorthandInvocation` codegen crash was the analyzer-7.6.0
  summary linker (pinned by riverpod_generator 2.6.5) vs the Dart 3.11 ecosystem. Fixed by dropping
  riverpod codegen (manual Riverpod 2 providers) + moving the toolchain to analyzer 10. Gate now green
  (see Verification evidence). Riverpod 3 migration is logged as **S6 tech-debt**.
- [~] BLOCKED pending post-fix device report: rerun the Android walkthrough for S3 regression reads plus S4
  create/invite/join/approve after the user-reported Functions deploy. Capture any runtime error,
  overflow, callable failure, or wrong/empty data.
- [x] RESOLVED: user ran `dart run tool/verify.dart` after the device bug fixes and pasted `GATE: PASS`.
- [~] BLOCKED pending device retest after the user-reported Functions deploy: creation submit must no
  longer return `[firebase_functions/unauthenticated]`, and grouped shares must show/pay/receive correctly.
- [x] RESOLVED: CI is green for pushed HEAD `1673c1c` (run 26922657221, `backend` + `verify` success).

### CI proof — `dart run tool/check_ci.dart`
```
 CI gate — CodexRock/tantin-dev @ a3baca3
 conclusion: success
 https://github.com/CodexRock/tantin-dev/actions/runs/26917868600
CI: GREEN ✅
```
(CI runs `dart run tool/verify.dart --ci` = format + analyze + logic/widget tests + Android APK build,
plus the `backend` job = Firestore/Storage rules tests + Functions Jest. Both jobs green.)

## Commits this sprint
- `8fd9341` feat(functions): expand S4 daret drafts (backend contract, prior session)
- `587987e` fix(build): drop riverpod codegen for manual Riverpod 2 providers on analyzer 10
- `a3baca3` feat(daret): S4 create wizard + drag-drop payout + join-by-code + approval
- `9024973` docs(s4): record codegen-fix gate PASS + CI green (run 26917868600) [skip ci]
- `80dae7b` fix(daret): correct S4 period-share math
- `1673c1c` docs(s4): record device bug fix handoff
- Pushed to `origin/main` through `1673c1c`; CI run 26922657221 = success for latest pushed HEAD.

## Definition of Done gate
- [ ] Every task above is implemented and verified
- [x] `dart run tool/verify.dart` -> `GATE: PASS` with output pasted for the current device-bug-fix tree
- [x] Backend lint/tests + security-rules emulator tests pass with output pasted
- [x] CI is green for pushed commit with output pasted
- [ ] New UI visually matches prototype and has committed goldens
- [ ] App builds and touched flows run on Android
- [~] `CONTEXT.md`, `DECISIONS.md`, and this file are current; final device result still needs recording
- [x] All S4 work committed per task and pushed
- [x] No secrets/private keys committed
- [~] Cloud config changes deployed and verified live or marked blocked; Functions deploy is user-reported,
  output not pasted, and live device proof is pending
- [ ] Sprint S4 complete summary posted

**Sprint sign-off:** Pending.
