import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';

void main() {
  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'Outfit',
        scaffoldBackgroundColor: TantinColors.ivoryBg,
      ),
      home: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  testWidgets('TnButton variants match golden', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TnButton(child: const Text('Primary'), onPressed: () {}),
            const SizedBox(height: 8),
            TnButton(
              variant: ButtonVariant.saffron,
              child: const Text('Saffron'),
              onPressed: () {},
            ),
            const SizedBox(height: 8),
            TnButton(
              variant: ButtonVariant.soft,
              child: const Text('Soft'),
              onPressed: () {},
            ),
            const SizedBox(height: 8),
            TnButton(
              variant: ButtonVariant.ghost,
              child: const Text('Ghost'),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('goldens/buttons.png'),
    );
  });

  testWidgets('Avatars match golden', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Avatar(data: AvatarData(initials: 'AM')),
            const SizedBox(width: 16),
            AvatarStack(
              avatars: List.generate(
                5,
                (i) => AvatarData(
                  initials: r'U$i',
                  bgColor: [
                    TantinColors.majorelle,
                    TantinColors.saffron,
                    TantinColors.success,
                  ][i % 3],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(Row),
      matchesGoldenFile('goldens/avatars.png'),
    );
  });

  testWidgets('StateBadge match golden', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StateBadge(state: DaretState.apayer),
            SizedBox(height: 8),
            StateBadge(state: DaretState.attente),
            SizedBox(height: 8),
            StateBadge(state: DaretState.confirme),
          ],
        ),
      ),
    );
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('goldens/state_badges.png'),
    );
  });

  testWidgets('ProgressRing match golden', (tester) async {
    await tester.pumpWidget(
      buildTestWidget(
        const ProgressRing(value: 40, total: 100),
      ),
    );
    // Wait for animation
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ProgressRing),
      matchesGoldenFile('goldens/progress_ring.png'),
    );
  });
}
