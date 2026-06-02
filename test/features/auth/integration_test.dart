import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/core/router/router.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/dashboard/presentation/screens/home_screen.dart';

class FakeUser implements User {
  @override
  String get uid => 'fake-uid';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ignore: subtype_of_sealed_class, Fake is required for testing
class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  bool get exists => true;
  @override
  Map<String, dynamic>? data() => {};
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('Smoke test: authenticated user routes to shell', (
    tester,
  ) async {
    final fakeUser = FakeUser();
    final fakeProfile = FakeDocumentSnapshot();

    final container = ProviderContainer(
      overrides: [
        authStateChangesProvider.overrideWith((ref) => Stream.value(fakeUser)),
        userProfileProvider.overrideWith((ref) => Stream.value(fakeProfile)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: container.read(routerProvider),
        ),
      ),
    );

    // Wait for the redirect stream to settle
    await tester.pumpAndSettle();

    // Should be on the home screen
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets(
    'Regression: Sign-out drives redirect to /splash and userProfile clears',
    (
      tester,
    ) async {
      final testUserProvider = StateProvider<User?>((ref) => FakeUser());
      final testProfileProvider =
          StateProvider<DocumentSnapshot<Map<String, dynamic>>?>(
            (ref) => FakeDocumentSnapshot(),
          );

      final container = ProviderContainer(
        overrides: [
          authStateChangesProvider.overrideWith(
            (ref) => Stream.value(ref.watch(testUserProvider)),
          ),
          userProfileProvider.overrideWith((ref) {
            final user = ref.watch(authStateChangesProvider).value;
            if (user == null) return Stream.value(null);
            return Stream.value(ref.watch(testProfileProvider));
          }),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, child) {
              return MaterialApp.router(
                routerConfig: ref.watch(routerProvider),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should redirect to home screen
      expect(
        container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        AppRoutes.home,
      );

      // User signs out
      container.read(testUserProvider.notifier).state = null;
      container.read(testProfileProvider.notifier).state = null;

      // Pump multiple times to clear any pending microtasks
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      // Should redirect back to splash screen
      expect(
        container
            .read(routerProvider)
            .routerDelegate
            .currentConfiguration
            .uri
            .path,
        AppRoutes.splash,
      );

      // Verify that userProfileProvider resolves to null
      final profileVal = container.read(userProfileProvider).value;
      expect(profileVal, isNull);
    },
  );
}
