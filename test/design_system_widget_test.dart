import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/design_system/design_system.dart';

/// Pumps [child] inside a minimal app host with animations disabled so taps
/// resolve through the simple (non-animated) Pressable path deterministically.
Future<void> _pump(WidgetTester tester, Widget child) {
  return tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('Segmented calls onChange with the tapped value', (tester) async {
    int? changed;
    await _pump(
      tester,
      Segmented<int>(
        value: 0,
        onChange: (v) => changed = v,
        options: const [
          SegmentedOption(value: 0, label: 'Actifs'),
          SegmentedOption(value: 1, label: 'Terminés'),
        ],
      ),
    );

    await tester.tap(find.text('Terminés'));
    await tester.pump();

    expect(changed, 1);
  });

  testWidgets('Disabled button does not call onPressed', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      TnButton(
        disabled: true,
        onPressed: () => taps++,
        child: const Text('Payer'),
      ),
    );

    await tester.tap(find.text('Payer'));
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('Enabled button calls onPressed', (tester) async {
    var taps = 0;
    await _pump(
      tester,
      TnButton(
        onPressed: () => taps++,
        child: const Text('Payer'),
      ),
    );

    await tester.tap(find.text('Payer'));
    await tester.pump();

    expect(taps, 1);
  });

  testWidgets('Sheet calls onClose when the scrim is tapped', (tester) async {
    var closed = 0;
    await _pump(
      tester,
      SizedBox(
        width: 320,
        height: 480,
        child: Stack(
          children: [
            Sheet(
              open: true,
              onClose: () => closed++,
              child: const Text('Contenu'),
            ),
          ],
        ),
      ),
    );

    // Tap the scrim near the top of the sheet's rect, above the bottom panel.
    final rect = tester.getRect(find.byType(Sheet));
    await tester.tapAt(Offset(rect.center.dx, rect.top + 10));
    await tester.pump();

    expect(closed, 1);
  });

  testWidgets('Toast renders its message; nothing when null', (tester) async {
    await _pump(
      tester,
      const SizedBox(
        width: 320,
        height: 480,
        child: Stack(
          children: [
            Toast(
              toast: ToastData(msg: 'Confirmé', type: ToastType.success),
            ),
          ],
        ),
      ),
    );
    expect(find.text('Confirmé'), findsOneWidget);

    await _pump(
      tester,
      const SizedBox(
        width: 320,
        height: 480,
        child: Stack(children: [Toast(toast: null)]),
      ),
    );
    expect(find.byType(Text), findsNothing);
  });
}
