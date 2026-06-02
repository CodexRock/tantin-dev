import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/design_system/components/button.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/profile_setup_screen.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const ProviderScope(
      child: MaterialApp(
        home: ProfileSetupScreen(),
      ),
    );
  }

  testWidgets('ProfileSetupScreen disables button if first name < 2 chars', (
    tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify "Continuer" button is disabled initially
    final buttonFinder = find.byType(TnButton);
    expect(buttonFinder, findsOneWidget);

    final button = tester.widget<TnButton>(buttonFinder);
    expect(button.disabled, isTrue);

    // Enter 1 char
    await tester.enterText(find.byType(TextField).first, 'A');
    await tester.pumpAndSettle();

    final button2 = tester.widget<TnButton>(buttonFinder);
    expect(button2.disabled, isTrue);

    // Enter 2 chars
    await tester.enterText(find.byType(TextField).first, 'Ab');
    await tester.pumpAndSettle();

    final button3 = tester.widget<TnButton>(buttonFinder);
    expect(button3.disabled, isFalse);
  });
}
