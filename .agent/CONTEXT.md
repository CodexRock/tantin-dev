# Tant'in Context

**Current Sprint:** S5 - Daret hub + two-sided confirmation + payout + admin

## Project Status
Flutter app (`tantin_flutter`) scaffolded and connected to the `tantin-dev` Firebase project.
- **Firebase Auth (S2):** Implemented for phone sign-in. Use test numbers to avoid SMS costs during development:
  - `+212 6 00 00 00 00` (code `123456`)
  - `+212 6 11 11 11 11` (code `111111`)

The app boots to a real 5-tab shell backed by live Firestore streams. A dev-only gallery route renders every component. S1 design system & component library are built and golden-tested.

## Architecture & Folder Map
- `lib/core/`: Application-wide concerns (routing, formatting, tokens, theme, providers, motion).
- `lib/core/firebase/`: Exposes Firebase services via Riverpod providers.
- `lib/core/firebase/firestore_helpers.dart`: Shared Firestore `Timestamp`/map/list conversion helpers.
- `lib/features/darets/`: Freezed daret/member/period/contribution/invite models, pure domain logic,
  Firestore mappers, stream repositories, Riverpod providers, and callable wrappers.
- `lib/features/create_daret/`: S4 create wizard draft domain/controller/repository and UI. The
  wizard writes a rules-allowed draft root, then calls deployed Functions for privileged start/invite
  work.
- `lib/features/join_daret/`: S4 join-by-code and approval review UI. Join/approval writes go through
  callable wrappers only.
- `functions/`: TypeScript Cloud Functions v2 in `europe-west1`. Callables wrap testable handlers with
  zod validation, auth, and App Check checks. Admin SDK writes all server-owned daret integrity fields
  (`statut`, `currentPeriode`, `memberUids`, period `status`/aggregates, contributions, members,
  activity, notifications, invites).
- `lib/features/profile/`, `lib/features/activity/`, `lib/features/notifications/`: Typed domain
  entities, Firestore mappers, repositories, and Riverpod stream providers for S3 read paths.
- `lib/core/motion/`: Reveal, FadeIn, Pressable, StaggeredReveal, page transitions, confetti — all reduced-motion aware via `MediaQuery.disableAnimationsOf`.
- `lib/design_system/`: `components/` (Avatar, Button, Card, CountUp, EmptyBlock, ProgressRing, ScreenHeader, Segmented, Sheet, Skel, StateBadge, Toast), `icons/` (TnIcons), `art/` (TnArt zellige), `gallery/` (dev route), and `design_system.dart` barrel. Components reference `core/theme` tokens only — no literal hex/spacing.
- `lib/l10n/`: French localization (ARB files).
- `lib/main.dart`: Entrypoint, Firebase init, App Check, Crashlytics, Analytics, `SystemUiOverlayStyle`.
- `test/`: unit + widget tests, golden tests (`design_system_test.dart`), goldens in `test/goldens/ci/`.

## Key Conventions
- **Feature-first architecture:** Upcoming sprints will organize by feature (e.g. `lib/features/daret/`).
- **State Management:** Riverpod 2 **runtime** with **manual providers** (NO codegen). `riverpod_generator`/
  `riverpod_lint`/`riverpod_annotation`/`custom_lint` were removed in S4 because they pinned `analyzer <8`,
  which crashes on the Dart 3.11 ecosystem (see DECISIONS D025). Declare providers by hand
  (`Provider`/`StreamProvider`/`NotifierProvider`/`StateNotifierProvider`, `.autoDispose`/`.family`) with
  an **explicit type annotation** (very_good_analysis `specify_nonobvious_property_types`). Riverpod 3
  migration is deferred to S6 (tech-debt).
- **Models:** `freezed` + `json_serializable`.
- **Firestore mapping:** Domain entities serialize JSON with generated code; Firestore mappers are
  explicit so `Timestamp` conversion and document IDs stay visible and testable.
- **Language:** French only (`app_fr.arb`).
- **Currency:** Dirham, formatted via `TantinFormat.fmtDH` with spaces (e.g. `1 500 DH`).

## Environment / Setup Commands
- `flutter pub get`: Fetch dependencies.
- `dart run build_runner build`: Generate Freezed models + JSON serialization (`*.freezed.dart`/`*.g.dart`).
  build_runner is `2.15.0` (analyzer 10) — the old `--delete-conflicting-outputs` flag was removed (it is
  now the default). Providers are NOT generated (manual since S4, D025).
- `flutter gen-l10n`: Generate localizations.
- `npm install`: Resolve the pinned backend rules-test toolchain and refresh `package-lock.json`.
- From `functions/`, `npm install`: Resolve the pinned Functions toolchain and refresh
  `functions/package-lock.json`. Do not use `npm --prefix functions install` from the repo root; npm
  treats the root package as a `file:..` dependency and creates a junction that makes Dart analysis
  recurse into generated backend dependencies.
- `npm test`: Run Firestore + Storage allow/deny rules tests in emulators using `firebase.test.json`.
  As of S3 Part 3 this also builds `functions/` and runs the Functions Jest suite against the Firestore
  emulator.
- Backend emulator tests require Java 21+ because `firebase-tools 15.19.0` rejects older runtimes.
- The backend test harness applies scoped `uuid ^11.1.1` npm overrides under `gaxios` and
  `universal-analytics`; `npm audit --json` must remain clean (D016).
- The Functions package applies scoped/global `uuid ^11.1.1` overrides for Firebase Admin's Google
  client transitive paths; `npm --prefix functions audit --json` must remain clean (D019).

## Dev Seed
- `seedDev` is an `europe-west1` callable guarded to dev projects and still requires both auth and
  App Check. It maps the caller's signed-in UID to Yasmine Benali, then writes the canonical `data.js`
  dataset to Firestore: Yasmine + 12 seed personas, 4 darets, periods, contributions, activity, and
  notifications.
- After deploying Functions to `tantin-dev`, sign in on a dev device with the account that should be
  Yasmine and invoke `DaretCallableRepository.seedDev()` from a debug-only action or one-off debug
  call. Do not add a persistent production UI for this.
- The seed is deterministic and idempotent for the canonical docs: Yasmine uses the signed-in UID;
  other personas use `seed-person-01` through `seed-person-12`; darets use `d1` through `d4`.

## Testing & CI
- **Canonical gate: `dart run tool/verify.dart`** — the single source of truth for "is it green?".
  Runs pub get, gen-l10n, build_runner, `dart format --set-exit-if-changed`, `flutter analyze
  --fatal-infos`, and `flutter test`; prints `GATE: PASS`/`GATE: FAIL`. (The `custom_lint` step was
  removed in S4 with riverpod_lint — see D025.)
  Use `--fast` to skip pub/codegen for quick re-checks, `--ci` to also build the APK.
- **Never check a Definition-of-Done box without pasting this gate's output** (see the Operating
  Manual's Prime Directive). CI runs the same script (`dart run tool/verify.dart --ci`); the only
  difference is CI **excludes golden tests** (`--exclude-tags golden`) because pixel goldens are
  platform-bound — see Golden-test workflow + D011. Everything else (analyze, custom_lint, logic/
  widget tests, Android build) is identical local vs CI.
- **After pushing, prove CI is actually green: `dart run tool/check_ci.dart`** — it finds the Actions
  run for HEAD, waits for it to finish, and exits non-zero unless it's `success`. A sprint is not done
  until this prints `CI: GREEN`. (Set `GITHUB_TOKEN` to avoid the 60/hour unauthenticated rate limit.)
- Forbidden: `any` version constraints (the gate rejects them) — pin everything (D004).

## Golden-test workflow (D008 + D011)
- CI has a second `backend` job for root `npm ci`, `npm --prefix functions ci`, and `npm test`. The
  backend gate covers Firestore/Storage rules tests plus Functions Jest tests.
- Goldens use **alchemist** (auto-tagged `golden`); baselines committed in `test/goldens/ci/`. Render scenarios with `MediaQuery(disableAnimations: true)` for a deterministic final frame.
- **Goldens are a LOCAL gate only.** They run in `dart run tool/verify.dart` (local) but are **excluded in CI** (`--exclude-tags golden`) — pixel rendering of shadows/gradients/blur differs across OSes, and we author baselines on Windows but CI runs Linux. CI covers logic/widget tests + the Android build (D011).
- Regenerate baselines on THIS machine after an intentional visual change: `flutter test --update-goldens`, then eyeball the diff. Never blind-update.
- `test/**/failures/` and `test/goldens/{windows,macos,linux}/` are git-ignored; the gate **fails** if a `failures/` dir exists (a committed failure artifact masked a red sprint in S1).

## Known Gotchas
- S3 least-privilege Firestore + Storage rules + indexes are **deployed to `tantin-dev`** (Part 3,
  after the architect security audit). Re-deploy with
  `firebase deploy --only firestore:rules,firestore:indexes,storage --project tantin-dev`.
- `firebase.test.json` intentionally avoids the live Storage target. Emulator tests use isolated
  project ID `tantin-rules-test`; live deploys continue to use `firebase.json` + target `main`.
- CI explicitly installs Temurin JDK 21 before emulator startup; do not rely on the hosted runner's
  default Java version (D017).
- CI pins Flutter to `3.41.2`, matching the project `.metadata` revision; do not use floating
  `3.x`, because Dart formatter output changed in Flutter 3.44/Dart 3.12 (D018).
- Firestore (Native Mode) has a **baseline `request.auth != null` rule deployed** (not open test mode). Full least-privilege state-machine rules come in a later sprint.
- **Storage rules ARE deployed** to `tantin-dev` via a storage target (`.firebaserc` maps target `main` → `tantin-dev.firebasestorage.app`; `firebase.json` storage block references it). Baseline `request.auth != null`. `firebase deploy --only storage --project tantin-dev` works.
- **App Check enforcement is OFF in dev** (`enforceAppCheck = false` in `functions/src/index.ts`) — the test device's Play Integrity kept failing ("Too many attempts") and blocked every callable. Auth + Firestore rules still protect all data. **MUST re-enable before release (S6).** See DECISIONS D022.
- Generated `*.g.dart`/`*.freezed.dart` are git-ignored — run `dart run build_runner build` after a fresh
  clone (CI does this automatically). See DECISIONS D004.
- **Codegen + analyzer (S4, D025):** if `build_runner` ever crashes with
  `Missing implementation of visitDotShorthandInvocation` (analyzer summary linker) + hangs, the cause is
  an `analyzer <8` being resolved against the Dart 3.11 ecosystem. Toolchain is now `analyzer 10` /
  `build_runner 2.15` / `freezed ^3.2` / `json_serializable ^6.10`, and riverpod codegen is gone — do NOT
  re-add `riverpod_generator`/`riverpod_lint` (they pin `analyzer <8` and reintroduce the crash). If a
  build hangs, also kill stray concurrent `dart` processes (multiple build_runners corrupt `.dart_tool`).
- Dependency set is just-in-time. Remaining packages (confetti is in via motion; contacts/image-picker/permissions, mocktail, fake_cloud_firestore, integration_test) are added in the sprint that first needs them.
- Do not commit service-account JSON keys or FCM server keys.

### Known device blockers (infra/contract — the gate & CI CANNOT catch these; only on-device proves them)
- **Callable returns raw `[firebase_functions/unauthenticated] UNAUTHENTICATED` (no handler message) →
  missing Cloud Run invoker binding (D027).** Gen-2 callables are Cloud Run services; a new/first-invoked
  one may have an empty IAM policy so `allUsers` can't invoke, and Cloud Run rejects before our code runs.
  Fix: `gcloud run services add-iam-policy-binding <svc-lowercased> --member=allUsers
  --role=roles/run.invoker --region=europe-west1 --project=tantin-dev`. This is the standard callable
  model (real auth is in `parseCallable` + rules), not an exposure. Do NOT bind the triggers
  (onContributionWritten/onMemberCreated/dailyReminders). S5 admin follow-up adds one new
  device-invoked callable service, `approvememberfor`, which needs the same D027 binding after deploy.
  No `fillseat` service was added; contact-fill reuses the existing `replacemember` callable. If instead
  the error carries a *message* (e.g. "Authentication is required."), it's our handler -> a real client
  auth issue.
- **Callable returns `[firebase_functions/failed-precondition] nom must be a string` → empty last name
  (D026).** `nom` is optional by product design; the backend tolerates `nom: ''`. Never `requireString`
  a person's `nom`. (Fixed in `readRequiredProfile`; jest regression covers it.)

## What's Done / What's Next (current — 2026-06-05)
- **S5 admin follow-up (post-Part-4) is locally gate-green on 2026-06-05.** Delete-confirm sheets are
  keyboard-aware and use the stable `SUPPRIMER` guard (D031). Admin can approve another pending member
  through the new Function-only `approveMemberFor` callable (D032). Vacant `pending_*` seats can be
  filled from the shared create-step-3 participant/contact picker by reusing `replaceMember`; active
  fills restore the live `apayer` contribution and invite-code fills obey the same D030 lock (D033).
  Device feedback then refined the D030 lock: before any payment is recorded, period 1 is editable too;
  `reorderPeriods` reseeds live contribution docs when tour 1 changes, and `replaceMember` can replace
  the current unpaid recipient (D034). User-run `dart run tool\verify.dart` printed `GATE: PASS` with
  Flutter tests `+73`; user-run `npm run test:functions` printed `32 passed`. Close-out still requires
  commit/push, deploy, `approvememberfor` D027 invoker binding, CI proof, and physical-device walkthrough.
- **Done through S4 — on-device proven.** S0 setup; S1 design system; S2 auth & onboarding; S3 (5-tab
  read shell + read-only daret-hub stub + Notifications + the 13-Function backend on `tantin-dev`);
  **S4 (create wizard + drag-drop payout ordering + group split + invite/share + join-by-code + preview
  + approval).** The full create→start→invite→join→approve loop is verified end-to-end on a physical
  Android device through to daret activation. Toolchain is post-D025 (manual Riverpod 2 providers,
  analyzer 10); App Check OFF in dev (D022). See `PROGRESS_S4.md` for the signed-off close-out + evidence.
- **Two device-only blockers were found & fixed during the S4 walkthrough** (both are now in
  "Known device blockers" above): Cloud Run invoker IAM (D027) and optional `nom` (D026). Lesson:
  deployed infra + client/backend data contracts live outside the repo, so the gate/CI/emulator can pass
  green while a real device fails — the device walkthrough is a required, non-skippable gate.
- **S5 Part 1 hub passed the local gate.** The read-only hub stub has been replaced by a live
  `DaretHubScreen` with header, current-period card, contributor states/actions, progress ring,
  Périodes/Membres/Activité tabs, and a focused widget test. User-run `dart run tool\verify.dart`
  printed `GATE: PASS` on 2026-06-04; T1–T3 are checked in `PROGRESS_S5.md`.
- **S5 Parts 1–3 done, gate-green & architect-reviewed (HEAD 0ccbed4):** live hub, two-sided
  confirmation core + Part-2 security checkpoint, payout celebration + clôture.
- **S5 Part 4 (admin) implemented and locally gate-green.** Four Function-only admin callables added
  (`reorderPeriods`, `replaceMember`, `editDaretDetails`, `deleteDaret`) — no rules loosened; the
  active-daret root/period/member/contribution docs stay Function-owned (new rules deny test proves it).
  `joinDaret` extended to complete a re-invite into an active daret. Hub gear → `Gérer le daret` menu +
  sub-sheets (edit / réorganiser upcoming tours / remplacer via re-invite placeholder / supprimer with
  type-to-confirm). "Mettre en pause" intentionally deferred; "adjust amounts" folded into
  `reorderPeriods` (D028). Goldens: interaction widget tests + device walkthrough, no new alchemist
  golden (D029). **S5 now deploys 8 callables total — the 4 above PLUS advancePeriod/closePeriod/
  closeDaret/sendNudge all need their Cloud Run invoker bindings on first device call (D027).**
- **Then S6 — FCM notifications + polish + release**, which also RE-ENABLES App Check (reverses D022).
