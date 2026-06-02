# PROGRESS — Sprint S2: Auth & Onboarding

> Copy this file to `.agent/PROGRESS_S{n}.md` at the start of the sprint. Update the checklist and work
> log CONTINUOUSLY (after each task), not in one dump at the end. The sprint is complete ONLY when the
> Definition of Done at the bottom is 100% checked.

**Sprint:** S2 — Auth & Onboarding
**Started:** 2026-06-02     **Status:** DONE (architect close-out + audit applied)
**Prereqs verified:** Y

## Objective
Implement the full onboarding + authentication flow exactly like the prototype, backed by Firebase Phone (SMS) auth behind a swappable OtpChannel interface. After this sprint a real user can: see splash → intro slides → enter phone (+212) → receive & enter an SMS OTP → set up profile (name + photo with geometric fallback) → grant/ skip contacts → land on the dashboard with the first-daret coachmark. Auth state drives routing.

## Task checklist
> Flip to [x] only when implemented AND verified. Add sub-tasks as needed.
- [x] T1 — `features/onboarding/` + `features/auth/` structure (data/domain/presentation)
- [x] T2: Splash + Intro screens
- [x] T3: Phone auth flow & `OtpChannel`
- [x] T4: OTP Screen with `pinput`
- [x] T5: Profile Setup with `image_picker`
- [x] T6: Contacts Permission with `permission_handler`
- [x] T7: Coachmark overlay
- [x] T8: Auth state & router redirects; logout flow
- [x] T9 — Tests + docs. Update CONTEXT/DECISIONS/PROGRESS.

## Work log
- 2026-06-02 13:22 — Read manual, context, decision log, and started gate verification.
- 2026-06-02 13:23 — Created PROGRESS_S2.md.

## Verification evidence (PASTE REAL OUTPUT — no adjectives, per the Prime Directive)

### Gate result — paste the verbatim SUMMARY + GATE line from `dart run tool/verify.dart`
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
- Tests added this sprint: phone-validation unit, profile-mapping unit, OTP auto-advance widget, profile-form validation widget, fake-auth→shell integration smoke, S2 screen goldens, mocked OtpChannel. Gate: 33 tests pass.
- Backend/rules: `users/{uid}` rule = `request.auth.uid == uid` + default-deny `if false`. **Deployed live** by architect on 2026-06-02 (`firebase deploy --only firestore:rules`; agent had NOT actually deployed it — the live DB was still on the S0 baseline until close-out). No emulator rules test yet — deferred to S3 (needs the emulator harness).
- Screens compared to prototype: splash, intro, phone, OTP, profile, contacts, home+coachmark. Copy says "par SMS" (verified, zero "WhatsApp").
- Ran on Android: device walkthrough performed by the user (`flutter run -d`) — see their report.
- **CI run:** GREEN after the golden-CI close-out (D011: goldens excluded from CI; logic/widget tests + Android build run). Confirmed via `tool/check_ci.dart`.
- Cloud config deployed this sprint: `firestore.rules` (users/{uid} least-privilege) — live.

## Blockers / questions for the user
- none (emulator rules test deferred to S3, tracked).

## Commits this sprint
- `4136d8d` feat(onboarding): S2 Auth & Onboarding complete
- `<close-out>` fix(s2): deploy users rule, goldens local-only/CI-excluded, honest PROGRESS (hash in summary)

## ── DEFINITION OF DONE (gate) ──
> Legend: `[x]` done & verified this session · `[~] BLOCKED: reason` · `[ ]` not yet.
- [x] Every task above is [x] and actually implemented
- [x] `dart run tool/verify.dart` → `GATE: PASS` (33 tests; output pasted above)
- [~] DEFERRED to S3: no security-rules emulator test yet (rule itself is deployed & least-privilege)
- [x] CI is green for the pushed commit (goldens excluded per D011; `tool/check_ci.dart`)
- [x] New/changed UI matches the prototype; golden tests exist & committed (local gate)
- [x] App builds (gate `--ci`); touched flows verified on Android by the user's device run
- [x] `CONTEXT.md`, `DECISIONS.md`, this file are updated & accurate
- [x] All work committed and pushed; commit hashes listed above
- [x] No secrets/private keys committed
- [x] Cloud config deployed & verified live (users/{uid} rule deployed by architect)
- [x] "Sprint S2 complete" summary posted to the user

**Sprint sign-off:** 2026-06-02 — S2 complete after architect close-out: security rule deployed, golden-CI strategy fixed (D011), reporting corrected. Gate green (33), CI green.
