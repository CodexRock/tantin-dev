// Tant'in canonical verification gate.
//
// THE single source of truth for "is this green?". The coding agent runs this
// before checking ANY Definition-of-Done box, and CI runs the exact same script
// (`dart run tool/verify.dart --ci`). If it exits non-zero, the sprint is NOT
// done — no prose claim overrides this script.
//
// Usage:
//   dart run tool/verify.dart          # full gate (local, before claiming done)
//   dart run tool/verify.dart --ci     # full gate for CI (also builds the APK)
//   dart run tool/verify.dart --fast   # skip pub get + codegen (quick re-check)
//
// Why this exists: in S0 the agent reported "flutter analyze: 0 issues" and
// "all green" WITHOUT running the toolchain. analyze was actually red and the
// custom_lint plugin was crashing. This script makes that class of mistake
// impossible: green is something you PROVE by running, not something you claim.
import 'dart:io';

void _out(String line) => stdout.writeln(line);

const _rule = '═══════════════════════════════════════════════';

Future<void> main(List<String> args) async {
  final ci = args.contains('--ci');
  final fast = args.contains('--fast');

  _out(_rule);
  _out(" Tant'in verification gate  ${ci ? '(CI)' : '(local)'}");
  _out(_rule);

  // Static guard: forbid `any` version constraints in pubspec.yaml. They let
  // the resolver drift (this is how riverpod_lint jumped to 3.x and crashed
  // the analyzer plugin). Constraints must be explicit (caret/range).
  _assertNoAnyConstraints();

  // Static guard: a `failures/` dir under test/ only exists when a golden test
  // FAILED. In S1 such artifacts were committed while the sprint was reported
  // "done". They must never be in the tree.
  _assertNoGoldenFailureArtifacts();

  final steps = <_Step>[
    if (!fast) const _Step('Resolve dependencies', 'flutter', ['pub', 'get']),
    if (!fast) const _Step('Generate l10n', 'flutter', ['gen-l10n']),
    if (!fast)
      // build_runner >=2.15 deletes conflicting outputs by default and rejects
      // the old --delete-conflicting-outputs flag, so it is no longer passed.
      const _Step('Codegen reproduces', 'dart', [
        'run',
        'build_runner',
        'build',
      ]),
    // Scope to the dirs we own. Formatting `.` makes dart_style recurse into
    // the git-ignored `node_modules/` (the backend rules-test harness) and
    // crash reading a vendored template's analysis_options.yaml. `functions/`
    // is TypeScript. See DECISIONS D025.
    const _Step('Format check', 'dart', [
      'format',
      '--set-exit-if-changed',
      'lib',
      'test',
      'tool',
    ]),
    // --fatal-infos: an info-level lint is a failure. We hold a zero-issue bar.
    const _Step('Static analysis', 'flutter', ['analyze', '--fatal-infos']),
    // NOTE: the custom_lint (riverpod_lint) step was removed in S4 — riverpod
    // codegen/lint was dropped because it pinned analyzer <8.0.0, which is
    // incompatible with the Flutter 3.41.2 / Dart 3.11 ecosystem (the analyzer
    // 7.6.0 summary linker crashes on dot-shorthand in dependency APIs). The
    // app stays on Riverpod 2 with MANUAL providers. See DECISIONS D025.
    // Golden tests are platform-sensitive (Skia rasterizes shadows/gradients/
    // blur/SVG differently per OS). Baselines are authored on the dev's machine,
    // so goldens run LOCALLY but are EXCLUDED in CI (Linux). CI still runs all
    // logic/widget tests + the Android build. See DECISIONS D011.
    _Step('Tests', 'flutter', [
      'test',
      if (ci) ...['--exclude-tags', 'golden'],
    ]),
    if (ci)
      const _Step('Android debug build', 'flutter', [
        'build',
        'apk',
        '--debug',
      ]),
  ];

  final results = <String, bool>{};
  var allPassed = true;

  for (final step in steps) {
    _out('\n▶ ${step.name}:  ${step.command} ${step.args.join(' ')}');
    final result = await Process.start(
      step.command,
      step.args,
      runInShell: true,
      mode: ProcessStartMode.inheritStdio,
    );
    final code = await result.exitCode;
    final ok = code == 0;
    results[step.name] = ok;
    if (!ok) allPassed = false;
    _out(ok ? '  ✅ ${step.name}' : '  ❌ ${step.name} (exit $code)');
  }

  _out('\n$_rule');
  _out(' SUMMARY');
  _out(_rule);
  results.forEach((name, ok) => _out('  ${ok ? '✅' : '❌'}  $name'));
  _out(_rule);

  if (allPassed) {
    _out('GATE: PASS ✅  — safe to check DoD boxes.');
    exit(0);
  }
  _out('GATE: FAIL ❌  — DO NOT mark the sprint done. Fix and re-run.');
  exit(1);
}

void _assertNoAnyConstraints() {
  final pubspec = File('pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('❌ pubspec.yaml not found — run from the repo root.');
    exit(2);
  }
  final offenders = <String>[];
  var inDeps = false;
  for (final raw in pubspec.readAsLinesSync()) {
    final line = raw.trimRight();
    if (RegExp('^(dependencies|dev_dependencies):').hasMatch(line)) {
      inDeps = true;
      continue;
    }
    // A new top-level key ends the dependency block.
    if (inDeps && RegExp('^[a-zA-Z_]').hasMatch(line)) inDeps = false;
    if (!inDeps) continue;
    // Match `  package: any` (the dangerous unpinned form).
    final m = RegExp(r'^\s{2,}([a-z0-9_]+):\s*any\s*$').firstMatch(line);
    if (m != null) offenders.add(m.group(1)!);
  }
  if (offenders.isNotEmpty) {
    stderr.writeln(
      '❌ Forbidden `any` version constraint(s): ${offenders.join(', ')}.\n'
      '   Pin every dependency to an explicit caret/range (see DECISIONS D004).',
    );
    exit(2);
  }
}

void _assertNoGoldenFailureArtifacts() {
  final testDir = Directory('test');
  if (!testDir.existsSync()) return;
  final offenders = testDir
      .listSync(recursive: true)
      .whereType<Directory>()
      .where((d) => d.path.replaceAll(r'\', '/').endsWith('/failures'))
      .toList();
  if (offenders.isNotEmpty) {
    stderr.writeln(
      '❌ Golden-failure artifacts present: '
      '${offenders.map((d) => d.path).join(', ')}.\n'
      '   A golden test failed. Fix the component or regenerate goldens '
      '(`flutter test --update-goldens`); never commit failure images.',
    );
    exit(2);
  }
}

class _Step {
  const _Step(this.name, this.command, this.args);
  final String name;
  final String command;
  final List<String> args;
}
