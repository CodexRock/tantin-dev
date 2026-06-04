# PROGRESS — Sprint S5: Daret Hub + Two-Sided Confirmation + Payout + Admin

> Update the checklist and work log CONTINUOUSLY (after each task), not in one dump at the end.
> Flip a box to `[x]` ONLY with pasted evidence below. `[~] BLOCKED: reason` for parked work.
> A false `[x]` is the worst outcome on this project. The sprint is complete only when the
> Definition of Done at the bottom is 100% checked.

**Sprint:** S5 — Daret hub + two-sided confirmation + payout + admin
**Started:** 2026-06-04     **Status:** in progress
**Prereqs verified:** S4 DoD signed off (PROGRESS_S4 — COMPLETE 2026-06-04, CI-green, device-proven). Baseline HEAD: 710a140

## Objective
Implement the active daret hub and the full trust-based two-sided confirmation lifecycle, the
celebratory payout moment, and the admin management tools. After this sprint a daret can be operated
end-to-end: members declare payments, recipients/admin confirm, the period progresses, the beneficiary
gets the celebration + shareable card, and the admin can manage everything through to clôture. This
sprint REPLACES the read-only stub (`lib/features/darets/presentation/screens/daret_hub_stub_screen.dart`)
with the live hub and wires daret-card taps + the Accueil hero button to it.
Design source: `../src/hub.jsx`, `../src/hub2.jsx`, `../src/app.jsx` sheets (ConfirmPay/Received/ShareCard/Admin).

## Task checklist
> Flip to [x] only when implemented AND verified. Gate between Parts.

### Part 1 — Daret hub (screens 21)
- [x] T1 — Hub header: nom, cagnotte, « Période en cours X/N » + dates (expand transition from card if feasible)
- [x] T2 — « Période en cours » card: Bénéficiaire badge, two-sided state checklist (À payer/En attente/Confirmé/En retard), per-member « Relancer », progress ring « 8/12 ont payé »
- [x] T3 — Hub sections/tabs: Périodes (timeline past/current/upcoming), Membres (roster + roles/states), Activité (this daret's log)

### Part 2 — Two-sided confirmation (screens 22) — THE CORE MECHANIC
- [x] T4 — Payer: « J'ai payé ma part » → ConfirmPaySheet (incl. « Tant'in ne traite pas d'argent ») → `apayer/retard → attente`, optimistic, rules-guarded client write
- [x] T5 — Recipient/admin: « Reçu » → ReceivedSheet → `attente → confirmé` (green, confirmedAt/By); admin can mark directly
- [x] T6 — « Relancer » → `sendNudge` (rate-limited) → success toast
- [x] T7 — All confirmed → period advances (`advancePeriod`/trigger); new current period reflects live; no illegal client transitions
- [x] **SECURITY CHECKPOINT (mandatory, before Part 3)** — rules tests prove: non-recipient/non-admin cannot confirm; member can only declare their own; no client write to period.status/aggregates. `npm test`/`npm run test:rules` green + pasted. STOP and post checkpoint message; wait for lead go-ahead.

### Part 3 — Payout celebration + clôture (screens 23, 24)
- [ ] T8 — « C'est ton tour! » payout takeover: confetti + amount count-up + shareable « payout reçu » card (ShareCardSheet → share_plus image). Celebration only, NO gamification
- [ ] T9 — Clôture du daret: closing summary + thanks (`closeDaret`) → moves to Terminés; lifetime stats updated

### Part 4 — Admin (screens 25, 26) — build FULLY, not stubs
- [ ] T10 — Gérer le daret (AdminSheets): edit details, réorganiser l'ordre, remplacer un membre, manage/close a period, adjust amounts, supprimer le daret (confirmation guard). Admin-gated by rules + Functions
- [ ] T11 — Period management: force-close by status/date + advance (`closePeriod`/`advancePeriod`), confirmation + activity logging

### Rollup
- [ ] T12 — Wire every S5 Function (sendNudge, advancePeriod, closePeriod, closeDaret, onContributionWritten); verify aggregates/activity/push produced
- [ ] T13 — Tests + docs (CONTEXT/DECISIONS/this file); goldens for new screens with committed baselines

## Work log
- 2026-06-04 12:07 — Read operating manual, CONTEXT, DECISIONS, S5 prompt, and prototype sources (`hub.jsx`, `hub2.jsx`, `app.jsx`). Confirmed baseline HEAD `710a140` (S5 progress skeleton) with S4 sign-off at `8158fc4`. Began Part 1 only per sprint gate. commit: 99a3c1b
- 2026-06-04 12:07 — Replaced the read-only hub stub with `DaretHubScreen`: live header, current-period beneficiary card, contributor checklist/state actions (UI-only until Part 2), progress ring, Périodes/Membres/Activité tabs, and router wiring. Added focused widget test `test/features/darets/presentation/daret_hub_screen_test.dart`. Gate pending user-run `dart run tool\verify.dart` (sprint brief forbids agent-run Dart/npm/Firebase/gcloud). commit: 99a3c1b
- 2026-06-04 12:22 — User-run Part 1 gate returned `GATE: FAIL`: analyzer infos in `daret_hub_screen.dart` plus a widget-test expectation mismatch on the member tab. Fixed the reported analyzer nits and changed the test to assert the actual admin/beneficiary subtitle (`Admin · Bénéficiaire actuel`). Awaiting rerun. commit: 99a3c1b
- 2026-06-04 12:35 — User reran `dart run tool\verify.dart`; Part 1 gate is green (`GATE: PASS`). Checked T1–T3 only. commit: 99a3c1b
- 2026-06-04 — Began Part 2 only. Removed the Part-1 `_showPartTwoSnack` placeholder, wired `ConfirmPaySheet` / `ReceivedSheet` to `DaretRepository.declarePaid` and `DaretRepository.confirmReceived` direct rules-guarded client writes, wired `Relancer` to `sendNudge`, and surfaced admin `advancePeriod` only when all current contributions are confirmed. Extended the hub widget smoke for the two sheets and extended `rules-tests/firestore.rules.test.cjs` with the mandatory allow/deny checkpoint cases. Awaiting user-run `npm run test:rules` and `dart run tool\verify.dart`; no Part 2 boxes checked yet.
- 2026-06-04 — User ran `dart format`, `npm run test:rules`, and `dart run tool\verify.dart`. Rules checkpoint passed (`24 passed, 24 total`), but canonical gate failed on six analyzer infos in `daret_hub_screen.dart` (`discarded_futures` x3, `lines_longer_than_80_chars` x3). Fixed those reported issues with explicit `unawaited(...)` and wrapped sheet strings. Awaiting rerun of `dart format` + `dart run tool\verify.dart`; no Part 2 boxes checked yet.
- 2026-06-04 — User reran `dart format lib\features\darets\presentation\screens\daret_hub_screen.dart` and `dart run tool\verify.dart`; canonical gate passed (`GATE: PASS`). Checked T4–T7 and the mandatory Part-2 security checkpoint only. STOP before Part 3 pending lead go-ahead.

## Verification evidence (PASTE REAL OUTPUT — no adjectives, per the Prime Directive)

### Part-1 gate — `dart run tool/verify.dart`
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

### Part-2 SECURITY CHECKPOINT — rules tests (`npm test` / `npm run test:rules`)
```
> test:rules
> firebase emulators:exec --config firebase.test.json --only firestore,storage "jest --runInBand rules-tests" --project tantin-rules-test

 PASS  rules-tests/firestore.rules.test.cjs (16.738 s)
 PASS  rules-tests/storage.rules.test.cjs

Test Suites: 2 passed, 2 total
Tests:       24 passed, 24 total
Snapshots:   0 total
Time:        19.021 s
Ran all test suites matching rules-tests.
+  Script exited successfully (code 0)
```

### Part-2 canonical gate attempt — `dart run tool\verify.dart` (FAIL)
```
  ✅  Resolve dependencies
  ✅  Generate l10n
  ✅  Codegen reproduces
  ✅  Format check
  ❌  Static analysis
  ✅  Tests
GATE: FAIL ❌  — DO NOT mark the sprint done. Fix and re-run.

Static analysis findings:
- daret_hub_screen.dart:145 discarded_futures
- daret_hub_screen.dart:153 discarded_futures
- daret_hub_screen.dart:166 discarded_futures
- daret_hub_screen.dart:457 lines_longer_than_80_chars
- daret_hub_screen.dart:542 lines_longer_than_80_chars
- daret_hub_screen.dart:543 lines_longer_than_80_chars
```

### Part-2 canonical gate rerun — `dart run tool\verify.dart`
```
  ✅  Resolve dependencies
  ✅  Generate l10n
  ✅  Codegen reproduces
  ✅  Format check
  ✅  Static analysis
  ✅  Tests
GATE: PASS ✅  — safe to check DoD boxes.
```

### Functions tests — `npm run test:functions`
```
{paste Test Suites/Tests counts; bare `jest` fails with "FIRESTORE_EMULATOR_HOST must be set"}
```

### Final canonical gate — `dart run tool/verify.dart`
```
{paste SUMMARY + GATE: PASS}
```
- Tests added this sprint: `test/features/darets/presentation/daret_hub_screen_test.dart` (Part 1 hub render/tabs smoke; Part 2 confirm/received sheet entry smoke), `rules-tests/firestore.rules.test.cjs` Part 2 confirmation allow/deny checkpoint cases
- Screens compared to prototype (hub/sheets/payout/clôture/admin): {match? goldens committed?}

### CI proof — `dart run tool/check_ci.dart`
```
{paste — CI: GREEN, both `verify` + `backend` success, run URL}
```

### On-device walkthrough (user-run, physical Android)
{declare → confirm(green) → relancer → period advances → payout (confetti + count-up + share card) → clôture → admin réorganiser/remplacer/supprimer. Paste result + any blocker found & fix.}

### Cloud config deployed this sprint
{firebase deploy --only functions/firestore — deployed? For the 4 S5 callables first-invoked on device (advancePeriod/closePeriod/closeDaret/sendNudge), confirm Cloud Run invoker bindings (D027) granted & verified.}

## Blockers / questions for the user
- Part 2 confirmation core is gate-green. STOP before Part 3 pending lead go-ahead.
- WATCH (D027): on first device call, the new callables (advancePeriod, closePeriod, closeDaret, sendNudge)
  may return raw `[firebase_functions/unauthenticated] UNAUTHENTICATED` (missing Cloud Run invoker binding).
  Fix proactively: `gcloud run services add-iam-policy-binding <svc-lowercased> --member=allUsers
  --role=roles/run.invoker --region=europe-west1 --project=tantin-dev`. Do NOT bind triggers.
- {others | none}

## Commits this sprint
- 99a3c1b feat(darets): build live daret hub

## ── DEFINITION OF DONE (gate) ──
> Legend: `[x]` done & verified this session · `[~] BLOCKED: reason` · `[ ]` not yet.
> NEVER mark `[x]` without evidence above.
- [ ] Every task above is [x] and actually implemented (admin built fully, not stubs; hub replaces the stub)
- [ ] A full period operates end-to-end: declare → recipient/admin confirms → progress updates → period advances → clôture; live/real-time, optimistic, offline-tolerant
- [ ] Two-sided state machine cannot be bypassed from the client (non-recipient/non-admin cannot confirm; member declares only their own) — proven by rules tests
- [ ] Payout matches the prototype (confetti + count-up + shareable card via share sheet)
- [ ] Admin tools work and are admin-gated (rules + Function checks); delete has a confirmation guard
- [ ] `dart run tool/verify.dart` → `GATE: PASS` (output pasted above)
- [ ] Backend Functions + security-rules emulator tests pass (output pasted above)
- [ ] CI is green for the pushed commit — `dart run tool/check_ci.dart` → `CI: GREEN` (pasted above)
- [ ] New/changed UI visually matches the prototype; golden test(s) exist & committed (tagged `golden`, D011)
- [ ] App builds & touched flows run on Android without runtime errors (device walkthrough pasted)
- [ ] `CONTEXT.md`, `DECISIONS.md`, this file are updated & accurate
- [ ] All work committed (per task) and pushed; commit hashes listed above
- [ ] No secrets/private keys committed; App Check NOT touched (stays OFF in dev per D022)
- [ ] Cloud config changes deployed & verified live; new-callable invoker bindings granted (D027)
- [ ] "Sprint S5 complete — ready for architect audit" posted to the user (with pasted gate result + CI link)

**Sprint sign-off:** {pending}
