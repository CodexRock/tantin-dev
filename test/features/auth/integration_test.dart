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

// ignore: subtype_of_sealed_class, Firestore DocumentSnapshot is sealed but we need a fake for testing
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
}
