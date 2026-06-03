import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/features/create_daret/data/create_daret_providers.dart';
import 'package:tantin_flutter/features/create_daret/domain/create_daret_models.dart';
import 'package:tantin_flutter/features/create_daret/presentation/create_daret_controller.dart';
import 'package:tantin_flutter/features/create_daret/presentation/screens/create_daret_screen.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/profile/data/user_providers.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

const _user = AppUser(
  uid: 'self',
  prenom: 'Yasmine',
  nom: 'Amrani',
  name: 'Yasmine Amrani',
  initials: 'YA',
  phone: '+212600000000',
  avatarPalette: ['#5247E6', '#E7E5FB'],
);

const _karim = CreateParticipant(
  uid: 'karim',
  name: 'Karim Tazi',
  prenom: 'Karim',
  initials: 'KT',
  avatarPalette: ['#F5A623', '#FBEFD6'],
  kind: CreateParticipantKind.app,
);

const _salma = CreateParticipant(
  uid: 'salma',
  name: 'Salma Idrissi',
  prenom: 'Salma',
  initials: 'SI',
  avatarPalette: ['#2E9E6B', '#DCF0E6'],
  kind: CreateParticipantKind.app,
);

void main() {
  testWidgets('dragging a tray member places them into a period slot', (
    tester,
  ) async {
    final controller = _orderController();

    await tester.pumpWidget(_host(controller));
    await tester.pumpAndSettle();

    final source = tester.getCenter(find.text('Karim'));
    final target = tester.getCenter(find.text('Glissez un membre ici').first);

    await tester.timedDragFrom(
      source,
      target - source,
      const Duration(milliseconds: 300),
    );
    await tester.pumpAndSettle();

    expect(controller.state.slots.first.recipientUids, const ['karim']);
    expect(controller.state.slots.first.shares, const {'karim': 100});
  });
}

Widget _host(CreateDaretController controller) {
  return ProviderScope(
    overrides: [
      createDaretControllerProvider.overrideWith((ref) => controller),
      currentAppUserProvider.overrideWith((ref) => Stream.value(_user)),
      myDaretsProvider.overrideWith(
        (ref) => Stream.value(const <Daret>[]),
      ),
    ],
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: CreateDaretScreen(),
      ),
    ),
  );
}

CreateDaretController _orderController() {
  final controller = CreateDaretController()
    ..ensureCurrentUser(_user)
    ..setNom('Daret Famille')
    ..setPeriodesCount(3)
    ..toggleParticipant(_karim)
    ..toggleParticipant(_salma)
    ..setStep(4);
  return controller;
}
