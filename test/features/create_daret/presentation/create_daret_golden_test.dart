// goldenTest registers tests like testWidgets and returns an unawaited Future.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
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

const _nadia = CreateParticipant(
  uid: 'nadia',
  name: 'Nadia Bennani',
  prenom: 'Nadia',
  initials: 'NB',
  avatarPalette: ['#D2483F', '#F8DAD7'],
  kind: CreateParticipantKind.app,
);

void main() {
  goldenTest(
    'Create daret wizard',
    fileName: 's4_create_daret_wizard',
    pumpBeforeTest: _pumpSettled,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'identity',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _host(_identityController()),
          ),
        ),
        GoldenTestScenario(
          name: 'order',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _host(_orderController()),
          ),
        ),
      ],
    ),
  );
}

Future<void> _pumpSettled(WidgetTester tester) async {
  await tester.pump();
  await tester.pumpAndSettle();
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

CreateDaretController _identityController() {
  return CreateDaretController()
    ..ensureCurrentUser(_user)
    ..setNom('Daret Famille');
}

CreateDaretController _orderController() {
  return CreateDaretController()
    ..ensureCurrentUser(_user)
    ..setNom('Daret Famille')
    ..setMontant(1500)
    ..setPeriodesCount(3)
    ..toggleParticipant(_karim)
    ..toggleParticipant(_salma)
    ..toggleParticipant(_nadia)
    ..autoOrganize()
    ..setStep(4);
}
