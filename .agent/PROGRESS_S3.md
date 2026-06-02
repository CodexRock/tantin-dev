# PROGRESS - Sprint S3: Backend Foundation + App Shell + Read Screens

**Sprint:** S3 - Backend Foundation + App Shell + Read Screens
**Started:** 2026-06-02     **Status:** in progress
**Prereqs verified:** Y

## Objective
Make the app real: a logged-in user sees the 5 tabs populated by live Firestore data shaped exactly
like the prototype's `data.js`, including a seed of the canonical demo dataset. Writes that S4/S5 need
are gated by tested security rules, and privileged Functions exist before read screens build on them.

## Task checklist
- [x] T1 - Freezed domain entities + Firestore DTOs/mappers
- [x] T2 - Pure domain logic + unit tests
- [x] T3 - Default-deny Firestore rules with membership, role, integrity, and contribution guards
- [x] T4 - Firestore indexes + self-only avatar storage rules
- [x] T5 - Security-rules emulator allow/deny matrix + CI job
- [x] T6 - Stream repositories + Riverpod read providers and guarded writes
- [ ] T7 - Cloud Functions suite
- [ ] T8 - Canonical dev seed
- [ ] T9 - Real 5-tab shell + FAB sheet
- [ ] T10 - Accueil read screen
- [ ] T11 - Mes Darets read screen
- [ ] T12 - Calendrier read screen
- [ ] T13 - Activite read screen
- [ ] T14 - Profil read screen
- [ ] T15 - Empty + loading states
- [ ] T16 - Tests + docs

## Work log
- 2026-06-02 - Read the operating manual, rolling context, decision log, S2 progress, S3 prompt, implementation plan, and canonical prototype dataset.
- 2026-06-02 - Verified inherited `6e0d23e` baseline before S3: local gate passed with 35 tests; CI green at https://github.com/CodexRock/tantin-dev/actions/runs/26840308554.
- 2026-06-02 - Created the S3 progress record. Implementing Parts 1-2 only, then stopping for the required security audit checkpoint.
- 2026-06-02 - Implemented Part 1 Freezed entities, explicit Firestore mappers, schedules, split
  validation, progress helpers, dashboard action selection, and the two-sided confirmation state
  machine with exhaustive legal/illegal transition tests. Flutter gate pending user-run verification.
- 2026-06-02 - Implemented Part 2 stream repositories/providers, callable wrappers, default-deny
  Firestore rules, indexes, self-only avatar Storage rules, emulator harness, and the second CI job.
- 2026-06-02 - Fixed inherited S2 avatar raw-string interpolation bug and migrated onboarding profile
  writes to the canonical S3 user schema while preserving legacy reads.
- 2026-06-02 - First emulator run failed before tests because the live Storage target cannot resolve
  under isolated emulator project `tantin-rules-test`; added `firebase.test.json`.
- 2026-06-02 - Emulator suite passed with 17 assertions. Expanded the matrix with explicit denied
  client creates for server-owned nested docs and profile stats. Fresh run pending dependency refresh.
- 2026-06-02 - `npm audit` found five advisories through `firebase-tools 14.27.0`; moved the declared
  range to `firebase-tools ^15.19.0`. `npm install` was not approved, so lock refresh is pending.
- 2026-06-02 - User refreshed the lockfile and ran the expanded emulator matrix: 19 tests passed.
  `firebase-tools 15.19.0` removed the high-severity advisories but retained four moderate nested UUID
  advisories. Added scoped UUID overrides; fresh `npm audit --json` reports zero vulnerabilities and
  fresh `npm test` still passes all 19 emulator tests.
- 2026-06-02 - User-ran Flutter gate after initial implementation: codegen, format, custom lint, and
  47 tests passed; static analysis failed on five info-level lints. Applied narrow lint fixes. Fresh
  user-ran Flutter gate pending.
- 2026-06-02 - User-ran Flutter gate after first lint pass: codegen, format, custom lint, and 47 tests
  passed; static analysis failed on two remaining info-level lints. Removed the redundant record
  pattern label and made the schedule test start date non-default. Fresh user-ran Flutter gate pending.
- 2026-06-02 - User-ran Flutter gate after second lint pass: static analysis failed because the
  simplified `MapEntry` syntax was invalid for an object pattern. Replaced the pattern with a typed
  loop to stay compatible with the pinned analyzer. Fresh user-ran Flutter gate pending.
- 2026-06-02 - User-ran `flutter analyze --fatal-infos` after typed-loop fix: no issues found. Full
  canonical gate rerun still required before checking Part 1/2 complete.
- 2026-06-02 - Pushed Parts 1-2 checkpoint at `e83904d`; GitHub Actions run
  https://github.com/CodexRock/tantin-dev/actions/runs/26847978786 failed in the new backend job
  before tests because `firebase-tools 15.19.0` requires Java 21+. Added Temurin JDK 21 setup and
  updated official Actions majors to Node-24-based `checkout@v6` / `setup-node@v6` / `setup-java@v5`.

## Verification evidence

### Inherited baseline gate - user-ran `dart run tool/verify.dart`
```
SUMMARY
  Resolve dependencies: PASS
  Generate l10n: PASS
  Codegen reproduces: PASS
  Format check: PASS
  Static analysis: PASS
  Custom lint (riverpod): PASS
  Tests: PASS (35 tests)
GATE: PASS
```

### Inherited baseline CI - user-ran `dart run tool/check_ci.dart`
```
CI gate - CodexRock/tantin-dev @ 6e0d23e
conclusion: success
https://github.com/CodexRock/tantin-dev/actions/runs/26840308554
CI: GREEN
```

### Part 1 / Part 2 verification
The user requested that the agent not run Dart or Flutter commands because they are slow; the agent
will provide exact commands for the user to run and record the pasted terminal output.

### Backend audit - `npm audit --json`
```
"vulnerabilities": {
  "info": 0,
  "low": 0,
  "moderate": 0,
  "high": 0,
  "critical": 0,
  "total": 0
}
```

### Backend emulator rules tests - fresh `npm test`
```
Test Suites: 2 passed, 2 total
Tests:       19 passed, 19 total
Snapshots:   0 total
Time:        23.978 s, estimated 46 s
Ran all test suites matching rules-tests.
```

### Superseded Flutter gate - user-ran before five lint fixes
```
SUMMARY
  Resolve dependencies: PASS
  Generate l10n: PASS
  Codegen reproduces: PASS
  Format check: PASS
  Static analysis: FAIL (5 info-level lints)
  Custom lint (riverpod): PASS
  Tests: PASS (47 tests)
GATE: FAIL
```

### Superseded Flutter gate - user-ran before final two lint fixes
```
SUMMARY
  Resolve dependencies: PASS
  Generate l10n: PASS
  Codegen reproduces: PASS
  Format check: PASS
  Static analysis: FAIL (2 info-level lints)
  Custom lint (riverpod): PASS
  Tests: PASS (47 tests)
GATE: FAIL
```

### Superseded Flutter gate - user-ran before typed-loop mapper fix
```
SUMMARY
  Resolve dependencies: PASS
  Generate l10n: PASS
  Codegen reproduces: PASS
  Format check: PASS
  Static analysis: FAIL (positional_field_in_object_pattern)
GATE: FAIL
```

### Targeted static analysis - user-ran after typed-loop mapper fix
```
Analyzing tantinFlutter...
No issues found! (ran in 84.8s)
```

### Part 1 / Part 2 canonical gate - user-ran `dart run tool/verify.dart`
```
═══════════════════════════════════════════════
 SUMMARY
═══════════════════════════════════════════════
  ✅  Resolve dependencies
  ✅  Generate l10n
  ✅  Codegen reproduces
  ✅  Format check
  ✅  Static analysis
  ✅  Custom lint (riverpod)
  ✅  Tests
═══════════════════════════════════════════════
GATE: PASS ✅  — safe to check DoD boxes.
```

## Blockers / questions for the user
- Parts 1-2 security checkpoint: local verification is complete. Cloud deployment and CI proof remain
  pending until the architect audits the security layer and the checkpoint commits are pushed.

## Commits this sprint
- `cc40081` feat(domain): add S3 daret models and logic
- `db6df25` feat(data): add realtime Firestore repositories
- `d007245` fix(auth): scope avatars and canonicalize profiles
- `6dd60c1` feat(security): enforce Firebase least privilege rules

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
- [ ] Sprint S3 complete summary posted

**Sprint sign-off:** Pending.
