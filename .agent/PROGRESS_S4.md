# PROGRESS - Sprint S4: Create Wizard + Drag-Drop + Join

**Sprint:** S4 - Create wizard + drag-drop payout ordering + join flow
**Started:** 2026-06-03     **Status:** in progress
**Prereqs verified:** Y

## Objective
Build the real destinations behind the existing "Creer / Rejoindre" sheet:
the 5-step create-daret wizard, the signature drag-drop payout ordering with
group splits, invite-code sharing, join-by-code preview, and member approval.
Privileged writes remain Function-owned; no client writes to server-owned
integrity fields.

## Task checklist
- [x] T0 - Onboarding, pull, inherited gate, and S4 progress record
- [ ] T1 - Wizard scaffold, routing, progress indicator, and validation
- [ ] T2 - Identity, money/rhythm, members, and recap steps
- [ ] T-dd1 - Period timeline slots with generated dates and pot amount
- [ ] T-dd2 - Drag/drop member placement with tray return behavior
- [ ] T-dd3 - Groupe split editor with 100% validation
- [ ] T-dd4 - Live assignment validation and disabled submit states
- [ ] T-dd5 - Auto-organiser and tirage au sort helpers
- [ ] T-dd6 - Assignment controller/model with unit tests
- [ ] T-join1 - Invite-code entry, previewDaret, joinDaret, and errors
- [ ] T-join2 - Approval review/progress and approveDaret
- [ ] T-join3 - createInvite code display and share_plus OS share sheet
- [ ] T6 - End-to-end callable wiring and backend generation verification
- [ ] T7 - Goldens, docs, commits, deploy/CI/device evidence

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

## Verification evidence

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

## Blockers / questions for the user
- None currently.

## Commits this sprint
- Pending.

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
