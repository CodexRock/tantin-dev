import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/splash_screen.dart';
import 'package:tantin_flutter/main.dart';

void main() {
  testWidgets('App boots and renders shell placeholder', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateChangesProvider.overrideWith((ref) => const Stream.empty()),
          userProfileProvider.overrideWith((ref) => const Stream.empty()),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify the splash screen is displayed initially (since there is no auth)
    expect(find.byType(SplashScreen), findsOneWidget);
  });
}
