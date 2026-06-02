// ignore_for_file: discarded_futures, goldenTest registers
// tests like testWidgets — unawaited by design
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/intro_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/otp_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/phone_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/profile_setup_screen.dart';
import 'package:tantin_flutter/features/onboarding/presentation/screens/splash_screen.dart';

void main() {
  Widget buildScreen(Widget child) {
    return ProviderScope(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child,
          ),
        ),
      ),
    );
  }

  group('S2 Auth & Onboarding Goldens', () {
    goldenTest(
      'SplashScreen',
      fileName: 's2_splash_screen',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Splash',
            child: const SizedBox(
              width: 390,
              height: 844,
              child: SplashScreen(),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'IntroScreen',
      fileName: 's2_intro_screen',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Intro Slide 1',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreen(const IntroScreen()),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'PhoneScreen',
      fileName: 's2_phone_screen',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Phone Screen',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreen(const PhoneScreen()),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'OtpScreen',
      fileName: 's2_otp_screen',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'OTP Screen',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreen(const OtpScreen()),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'ProfileSetupScreen',
      fileName: 's2_profile_setup_screen',
      pumpBeforeTest: pumpOnce,
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'Profile Setup',
            child: SizedBox(
              width: 390,
              height: 844,
              child: buildScreen(const ProfileSetupScreen()),
            ),
          ),
        ],
      ),
    );
  });
}
