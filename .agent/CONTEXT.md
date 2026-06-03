# Tant'in Context

**Current Sprint:** S3 Part 3 - Cloud Functions deployed, commit/CI checkpoint pending

## Project Status
Flutter app (`tantin_flutter`) scaffolded and connected to the `tantin-dev` Firebase project.
- **Firebase Auth (S2):** Implemented for phone sign-in. Use test numbers to avoid SMS costs during development:
  - `+212 6 00 00 00 00` (code `123456`)
  - `+212 6 11 11 11 11` (code `111111`)

The app boots to a placeholder 5-tab shell; a dev-only gallery route renders every component. S1 design system & component library are built and golden-tested.

## Architecture & Folder Map
- `lib/core/`: Application-wide concerns (routing, formatting, tokens, theme, providers, motion).
- `lib/core/firebase/`: Exposes Firebase services via Riverpod providers.
- `lib/core/firebase/firestore_helpers.dart`: Shared Firestore `Timestamp`/map/list conversion helpers.
- `lib/features/darets/`: Freezed daret/member/period/contribution/invite models, pure domain logic,
  Firestore mappers, stream repositories, Riverpod providers, and callable wrappers.
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
- **State Management:** Riverpod 2 with codegen (`riverpod_annotation`, `riverpod_generator`).
- **Models:** `freezed` + `json_serializable`.
- **Firestore mapping:** Domain entities serialize JSON with generated code; Firestore mappers are
  explicit so `Timestamp` conversion and document IDs stay visible and testable.
- **Language:** French only (`app_fr.arb`).
- **Currency:** Dirham, formatted via `TantinFormat.fmtDH` with spaces (e.g. `1 500 DH`).

## Environment / Setup Commands
- `flutter pub get`: Fetch dependencies.
- `dart run build_runner build --delete-conflicting-outputs`: Generate Riverpod providers, Freezed models, JSON serialization, and GoRouter routes.
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
  --fatal-infos`, `dart run custom_lint`, and `flutter test`; prints `GATE: PASS`/`GATE: FAIL`.
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
- Generated `*.g.dart`/`*.freezed.dart` are git-ignored — run `dart run build_runner build --delete-conflicting-outputs` after a fresh clone (CI does this automatically). See DECISIONS D004.
- Dependency set is just-in-time. Remaining packages (confetti is in via motion; contacts/image-picker/permissions, mocktail, fake_cloud_firestore, integration_test) are added in the sprint that first needs them.
- Do not commit service-account JSON keys or FCM server keys.

## What's Done / What's Next
- **Current checkpoint:** S3 **Part 4 read screens are done and CI-green** (commit `7b2ead0`, run
  26881095108: `verify` + `backend` both success). The 5-tab shell is real — Accueil (hero next-action
  + Ce mois-ci summary + active darets), Mes Darets (segmented), Calendrier (period agenda), Activité
  (merged log), Profil (stats + settings + logout), plus Notifications and a read-only daret hub stub.
  Global « + » FAB → Créer/Rejoindre sheet with a **debug-only `seedDev`** action. All from the S1
  design system + live Firestore streams. `dart run tool/verify.dart` → GATE: PASS (47 tests).
- **Remaining to close S3:** (a) per-screen **golden tests** — add the test files, then run
  `flutter test --update-goldens` once to bake baselines (local-only, D011); (b) a device walkthrough
  (seed → Yasmine sees all 5 tabs matching the prototype); (c) finalize this file + `PROGRESS_S3`;
  (d) architect final S3 audit + sign-off.
- **Done:** S0 setup; S1 design system; S2 auth & onboarding; S3 Parts 1–3 (domain + least-privilege
  rules + indexes + repositories + the 13-Function backend, deployed to `tantin-dev`, rules+functions
  emulator tests green in CI).
- **Next sprints:** S4 (create wizard / drag-drop / join — wires `startDaret`/`createInvite`/
  `joinDaret`/`approveDaret`), S5 (daret hub + two-sided confirmation + payout — replaces the stub),
  S6 (FCM notifications + polish + release).
