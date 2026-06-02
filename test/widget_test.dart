import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tantin_flutter/main.dart';

void main() {
  testWidgets('App boots and renders shell placeholder', (tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify the router is initialized and the bottom nav is present
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify the home placeholder is displayed initially
    expect(find.text('Accueil Placeholder'), findsOneWidget);
  });
}
