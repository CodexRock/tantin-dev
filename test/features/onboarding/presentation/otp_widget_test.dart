import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/auth/presentation/auth_controller.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/otp_screen.dart';
import '../../../helpers/mock_otp_channel.dart';

void main() {
  Widget createWidgetUnderTest(ProviderContainer container) {
    final router = GoRouter(
      initialLocation: '/otp',
      routes: [
        GoRoute(
          path: '/otp',
          builder: (context, state) => const OtpScreen(),
        ),
        GoRoute(
          path: '/profile-setup',
          builder: (context, state) =>
              const Scaffold(body: Text('Profile Setup')),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('OtpScreen auto-advances on 6 digits', (
    tester,
  ) async {
    final mockChannel = MockOtpChannel();
    final container = ProviderContainer(
      overrides: [
        otpChannelProvider.overrideWithValue(mockChannel),
      ],
    );
    container.read(currentPhoneProvider.notifier).updatePhone('+212600000000');
    container
        .read(currentVerificationIdProvider.notifier)
        .updateId('test-verif-id');

    await tester.pumpWidget(createWidgetUnderTest(container));
    await tester.pump();

    expect(find.text('Entrez le code'), findsOneWidget);

    // Simulate typing 6 digits
    await tester.enterText(find.byType(EditableText), '123456');
    await tester.pumpAndSettle(); // Wait for auto-advance verify call

    expect(mockChannel.verifiedCode, '123456');
    expect(mockChannel.verifiedVerificationId, 'test-verif-id');
  });
}
