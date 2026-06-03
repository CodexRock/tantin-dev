// goldenTest registers tests like testWidgets and returns an unawaited Future.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/join_daret/presentation/screens/approval_screen.dart';
import 'package:tantin_flutter/features/join_daret/presentation/screens/join_daret_screen.dart';

const _daretId = 'daret-s4';

const _daret = Daret(
  id: _daretId,
  nom: 'Daret Famille',
  cover: '🏡',
  accent: '#5247E6',
  montant: 1500,
  frequence: DaretFrequency.mensuel,
  periodesCount: 3,
  cagnotteParPeriode: 6000,
  statut: DaretStatus.attente,
  adminUid: 'self',
  memberUids: ['self', 'karim', 'pending_1', 'salma'],
  currentPeriode: 0,
  inviteCode: 'TANTIN-7K2P',
  settings: DaretSettings(echeanceDay: 5, graceDays: 2),
);

const _members = <DaretMember>[
  DaretMember(
    uid: 'self',
    role: MemberRole.admin,
    approvalStatus: ApprovalStatus.approved,
    name: 'Yasmine Amrani',
    prenom: 'Yasmine',
    initials: 'YA',
    avatarPalette: ['#5247E6', '#E7E5FB'],
  ),
  DaretMember(
    uid: 'karim',
    role: MemberRole.member,
    approvalStatus: ApprovalStatus.pending,
    name: 'Karim Tazi',
    prenom: 'Karim',
    initials: 'KT',
    avatarPalette: ['#F5A623', '#FBEFD6'],
  ),
  DaretMember(
    uid: 'pending_1',
    role: MemberRole.member,
    approvalStatus: ApprovalStatus.pending,
    name: 'Invitation 1',
    prenom: 'Invitation',
    initials: 'IN',
    avatarPalette: ['#F5A623', '#FBEFD6'],
  ),
  DaretMember(
    uid: 'salma',
    role: MemberRole.member,
    approvalStatus: ApprovalStatus.pending,
    name: 'Salma Idrissi',
    prenom: 'Salma',
    initials: 'SI',
    avatarPalette: ['#2E9E6B', '#DCF0E6'],
  ),
];

final _periods = <DaretPeriod>[
  DaretPeriod(
    id: '01',
    index: 1,
    recipientUids: const ['self'],
    shares: const {'self': 100},
    scheduledDate: DateTime(2026, 6, 5),
    potAmount: 6000,
    status: PeriodStatus.upcoming,
    paidCount: 0,
    totalCount: 2,
  ),
  DaretPeriod(
    id: '02',
    index: 2,
    recipientUids: const ['karim', 'pending_1'],
    shares: const {'karim': 50, 'pending_1': 50},
    scheduledDate: DateTime(2026, 7, 5),
    potAmount: 6000,
    status: PeriodStatus.upcoming,
    paidCount: 0,
    totalCount: 1,
  ),
  DaretPeriod(
    id: '03',
    index: 3,
    recipientUids: const ['salma'],
    shares: const {'salma': 100},
    scheduledDate: DateTime(2026, 8, 5),
    potAmount: 6000,
    status: PeriodStatus.upcoming,
    paidCount: 0,
    totalCount: 2,
  ),
];

void main() {
  goldenTest(
    'Join and approval screens',
    fileName: 's4_join_approval',
    pumpBeforeTest: _pumpSettled,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'join',
          child: const SizedBox(
            width: 390,
            height: 844,
            child: JoinDaretScreen(),
          ),
        ),
        GoldenTestScenario(
          name: 'approval',
          child: SizedBox(
            width: 390,
            height: 844,
            child: _approvalHost(),
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

Widget _approvalHost() {
  return ProviderScope(
    overrides: [
      authStateChangesProvider.overrideWith(
        (ref) => Stream<User?>.value(null),
      ),
      daretProvider(_daretId).overrideWith((ref) => Stream.value(_daret)),
      daretMembersProvider(_daretId).overrideWith(
        (ref) => Stream.value(_members),
      ),
      periodsProvider(_daretId).overrideWith(
        (ref) => Stream.value(_periods),
      ),
    ],
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: ApprovalScreen(
          daretId: _daretId,
          inviteCode: 'TANTIN-7K2P',
        ),
      ),
    ),
  );
}
