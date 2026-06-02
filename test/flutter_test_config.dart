import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Global golden-test configuration (auto-loaded by `flutter test`).
///
/// We run **only CI goldens** (platform goldens disabled) on every machine.
/// CI goldens render text as deterministic blocks and are pixel-identical
/// across Windows/macOS/Linux — so a golden generated locally matches the
/// exact same file in GitHub Actions (Ubuntu). This closes the S1 trap where
/// Windows-generated goldens failed on the Linux CI runner. True font-level
/// visual parity to the prototype is checked via the dev gallery screen +
/// the committed screenshots, not via these structural goldens.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
