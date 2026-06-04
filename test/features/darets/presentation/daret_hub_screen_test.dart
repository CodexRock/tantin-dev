import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/activity/data/activity_providers.dart';
import 'package:tantin_flutter/features/activity/domain/activity_event.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/darets/presentation/screens/daret_hub_screen.dart';
import 'package:tantin_flutter/features/profile/data/user_providers.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

const _daretId = 'daret-s5';

const _user = AppUser(
  uid: 'admin',
  prenom: 'Yasmine',
  nom: '',
  name: 'Yasmine',
  initials: 'Y',
  phone: '+212600000000',
  avatarPalette: ['#5247E6', '#E7E5FB'],
);

const _payerUser = AppUser(
  uid: 'karim',
  prenom: 'Karim',
  nom: '',
  name: 'Karim',
  initials: 'K',
  phone: '+212611111111',
  avatarPalette: ['#F5A623', '#FBEFD6'],
);

final _daret = Daret(
  id: _daretId,
  nom: 'Daret Famille',
  cover: '🏡',
  accent: '#5247E6',
  montant: 1500,
  frequence: DaretFrequency.mensuel,
  periodesCount: 4,
  cagnotteParPeriode: 6000,
  statut: DaretStatus.actif,
  adminUid: 'admin',
  memberUids: const ['admin', 'karim', 'salma', 'reda'],
  currentPeriode: 2,
  prochaineDate: DateTime(2026, 7, 5),
  settings: const DaretSettings(echeanceDay: 5, graceDays: 2),
);

const _members = <DaretMember>[
  DaretMember(
    uid: 'admin',
    role: MemberRole.admin,
    approvalStatus: ApprovalStatus.approved,
    name: 'Yasmine',
    prenom: 'Yasmine',
    initials: 'Y',
    avatarPalette: ['#5247E6', '#E7E5FB'],
  ),
  DaretMember(
    uid: 'karim',
    role: MemberRole.member,
    approvalStatus: ApprovalStatus.approved,
    name: 'Karim Tazi',
    prenom: 'Karim',
    initials: 'KT',
    avatarPalette: ['#F5A623', '#FBEFD6'],
  ),
  DaretMember(
    uid: 'salma',
    role: MemberRole.member,
    approvalStatus: ApprovalStatus.approved,
    name: 'Salma Idrissi',
    prenom: 'Salma',
    initials: 'SI',
    avatarPalette: ['#2E9E6B', '#DCF0E6'],
  ),
  DaretMember(
    uid: 'reda',
    role: MemberRole.member,
    approvalStatus: ApprovalStatus.approved,
    name: 'Reda Mansouri',
    prenom: 'Reda',
    initials: 'RM',
    avatarPalette: ['#D2483F', '#F8DAD7'],
  ),
];

final _periods = <DaretPeriod>[
  DaretPeriod(
    id: '01',
    index: 1,
    recipientUids: const ['karim'],
    shares: const {'karim': 100},
    scheduledDate: DateTime(2026, 6, 5),
    potAmount: 4500,
    status: PeriodStatus.closed,
    paidCount: 3,
    totalCount: 3,
  ),
  DaretPeriod(
    id: '02',
    index: 2,
    recipientUids: const ['admin'],
    shares: const {'admin': 100},
    scheduledDate: DateTime(2026, 7, 5),
    potAmount: 4500,
    status: PeriodStatus.current,
    paidCount: 1,
    totalCount: 3,
  ),
  DaretPeriod(
    id: '03',
    index: 3,
    recipientUids: const ['salma', 'reda'],
    shares: const {'salma': 50, 'reda': 50},
    scheduledDate: DateTime(2026, 8, 5),
    potAmount: 4500,
    status: PeriodStatus.upcoming,
    paidCount: 0,
    totalCount: 2,
  ),
];

final Daret _closingDaret = _daret.copyWith(
  currentPeriode: 4,
  prochaineDate: DateTime(2026, 9, 5),
);

final _closingPeriods = <DaretPeriod>[
  _periods[0],
  _periods[1].copyWith(
    status: PeriodStatus.closed,
    paidCount: 3,
    totalCount: 3,
  ),
  _periods[2].copyWith(
    status: PeriodStatus.closed,
    paidCount: 2,
    totalCount: 2,
  ),
  DaretPeriod(
    id: '04',
    index: 4,
    recipientUids: const ['salma'],
    shares: const {'salma': 100},
    scheduledDate: DateTime(2026, 9, 5),
    potAmount: 4500,
    status: PeriodStatus.current,
    paidCount: 3,
    totalCount: 3,
  ),
];

const _contributions = <Contribution>[
  Contribution(
    payerUid: 'admin',
    state: ContributionState.recipient,
    amount: 0,
  ),
  Contribution(
    payerUid: 'karim',
    state: ContributionState.apayer,
    amount: 1500,
  ),
  Contribution(
    payerUid: 'salma',
    state: ContributionState.attente,
    amount: 1500,
  ),
  Contribution(
    payerUid: 'reda',
    state: ContributionState.confirme,
    amount: 1500,
  ),
];

const _closingContributions = <Contribution>[
  Contribution(
    payerUid: 'admin',
    state: ContributionState.confirme,
    amount: 1500,
  ),
  Contribution(
    payerUid: 'karim',
    state: ContributionState.confirme,
    amount: 1500,
  ),
  Contribution(
    payerUid: 'salma',
    state: ContributionState.recipient,
    amount: 0,
  ),
  Contribution(
    payerUid: 'reda',
    state: ContributionState.confirme,
    amount: 1500,
  ),
];

// Period-1, no-payment recorded → reorder/replace are still available.
const _arrangeableContributions = <Contribution>[
  Contribution(
    payerUid: 'karim',
    state: ContributionState.recipient,
    amount: 0,
  ),
  Contribution(
    payerUid: 'admin',
    state: ContributionState.apayer,
    amount: 1500,
  ),
  Contribution(
    payerUid: 'salma',
    state: ContributionState.apayer,
    amount: 1500,
  ),
  Contribution(payerUid: 'reda', state: ContributionState.apayer, amount: 1500),
];

final _activity = <ActivityEvent>[
  ActivityEvent(
    id: 'a1',
    type: ActivityType.paiement,
    actorUid: 'admin',
    text: 'a confirmé le paiement de Reda',
    createdAt: DateTime(2026, 7, 2, 10),
    amount: 1500,
    periodIndex: 2,
  ),
];

void main() {
  testWidgets('renders current period, tabs, roster and activity', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text("C'EST VOTRE TOUR !"), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    await tester.pumpAndSettle();

    expect(find.text('Daret Famille'), findsOneWidget);
    expect(find.text('BÉNÉFICIAIRE DE CE TOUR'), findsOneWidget);
    expect(find.text("C'est votre tour !"), findsOneWidget);
    expect(find.text('1/3 ont payé'), findsOneWidget);
    expect(find.text('Relancer'), findsOneWidget);
    expect(find.text('Reçu'), findsNWidgets(2));

    await tester.tap(find.text('Périodes'));
    await tester.pumpAndSettle();
    expect(find.text('Versé'), findsOneWidget);
    expect(find.text('À venir'), findsOneWidget);

    await tester.tap(find.text('Membres'));
    await tester.pumpAndSettle();
    expect(find.text('Yasmine (vous)'), findsOneWidget);
    expect(find.text('Admin · Bénéficiaire actuel'), findsOneWidget);

    await tester.tap(find.text('Activité'));
    await tester.pumpAndSettle();
    expect(find.text('a confirmé le paiement de Reda'), findsOneWidget);
  });

  testWidgets('opens payer confirmation sheet', (tester) async {
    await tester.pumpWidget(_host(user: _payerUser));
    await tester.pumpAndSettle();

    await tester.tap(find.text("J'ai payé ma part"));
    await tester.pumpAndSettle();

    expect(find.text('Confirmer votre paiement'), findsOneWidget);
    expect(
      find.textContaining("Tant'in ne traite pas d'argent"),
      findsOneWidget,
    );
  });

  testWidgets('opens received confirmation sheet', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    await _dismissPayoutTakeover(tester);

    await tester.tap(find.text('Reçu').first);
    await tester.pumpAndSettle();

    expect(find.text('Confirmer la réception'), findsOneWidget);
    expect(find.textContaining('Validation admin'), findsOneWidget);
  });

  testWidgets('shows payout takeover and share card sheet', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text("C'EST VOTRE TOUR !"), findsOneWidget);
    expect(find.text('Vous recevez'), findsOneWidget);
    expect(find.text('4 500 DH'), findsOneWidget);

    await tester.tap(find.text('Partager ma carte'));
    await tester.pumpAndSettle();

    expect(find.text('Votre carte'), findsOneWidget);
    expect(find.text('Tour reçu'), findsOneWidget);
    expect(find.textContaining('Daret Famille'), findsWidgets);
  });

  testWidgets('opens final close confirmation sheet', (tester) async {
    await tester.pumpWidget(
      _host(
        daret: _closingDaret,
        periods: _closingPeriods,
        contributions: _closingContributions,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Clôturer').first);
    await tester.pumpAndSettle();

    expect(find.text('Clôturer le daret ?'), findsOneWidget);
    expect(
      find.textContaining("Tant'in ne déplace jamais d'argent"),
      findsOneWidget,
    );
  });

  testWidgets('admin manage sheet exposes the four operations', (tester) async {
    await tester.pumpWidget(
      _host(
        daret: _daret.copyWith(currentPeriode: 1),
        contributions: _arrangeableContributions,
      ),
    );
    await tester.pumpAndSettle();
    await _dismissPayoutTakeover(tester);

    await tester.tap(find.byKey(const Key('hub-admin-gear')));
    await tester.pumpAndSettle();

    expect(find.text('Gérer le daret'), findsOneWidget);
    expect(find.text('Modifier les détails'), findsOneWidget);
    expect(find.text("Réorganiser l'ordre"), findsOneWidget);
    expect(find.text('Remplacer un membre'), findsOneWidget);
    expect(find.text('Supprimer le daret'), findsOneWidget);
  });

  testWidgets('manage sheet hides reorder/replace once payments start', (
    tester,
  ) async {
    // Default daret is on period 2 → arrangement is locked.
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    await _dismissPayoutTakeover(tester);

    await tester.tap(find.byKey(const Key('hub-admin-gear')));
    await tester.pumpAndSettle();

    expect(find.text('Modifier les détails'), findsOneWidget);
    expect(find.text('Supprimer le daret'), findsOneWidget);
    expect(find.text("Réorganiser l'ordre"), findsNothing);
    expect(find.text('Remplacer un membre'), findsNothing);
  });

  testWidgets('delete guard stays locked until the daret name is typed', (
    tester,
  ) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    await _dismissPayoutTakeover(tester);

    await tester.tap(find.byKey(const Key('hub-admin-gear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Supprimer le daret'));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer ce daret ?'), findsOneWidget);
    final locked = tester.widget<TnButton>(
      find.widgetWithText(TnButton, 'Supprimer définitivement'),
    );
    expect(locked.disabled, isTrue);

    await tester.enterText(find.byType(TextField), 'Daret Famille');
    await tester.pumpAndSettle();
    final unlocked = tester.widget<TnButton>(
      find.widgetWithText(TnButton, 'Supprimer définitivement'),
    );
    expect(unlocked.disabled, isFalse);
  });

  testWidgets('edit details sheet pre-fills the current daret', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();
    await _dismissPayoutTakeover(tester);

    await tester.tap(find.byKey(const Key('hub-admin-gear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier les détails'));
    await tester.pumpAndSettle();

    expect(find.text('Couleur'), findsOneWidget);
    expect(find.text('Enregistrer'), findsOneWidget);
    expect(find.text('Daret Famille'), findsWidgets);
  });

  testWidgets('replace member lists only not-yet-served members', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        daret: _daret.copyWith(currentPeriode: 1),
        contributions: _arrangeableContributions,
      ),
    );
    await tester.pumpAndSettle();
    await _dismissPayoutTakeover(tester);

    await tester.tap(find.byKey(const Key('hub-admin-gear')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remplacer un membre'));
    await tester.pumpAndSettle();

    // salma & reda hold an upcoming turn; karim already received in period 1.
    expect(find.text('Salma Idrissi'), findsOneWidget);
    expect(find.text('Reda Mansouri'), findsOneWidget);
    expect(find.text('Karim Tazi'), findsNothing);
  });
}

Widget _host({
  AppUser? user,
  Daret? daret,
  List<DaretPeriod>? periods,
  List<Contribution>? contributions,
  List<ActivityEvent>? activity,
}) {
  final hostUser = user ?? _user;
  final hostDaret = daret ?? _daret;
  final hostPeriods = periods ?? _periods;
  final hostContributions = contributions ?? _contributions;
  final hostActivity = activity ?? _activity;
  return ProviderScope(
    overrides: [
      currentAppUserProvider.overrideWith((ref) => Stream.value(hostUser)),
      daretProvider(_daretId).overrideWith((ref) => Stream.value(hostDaret)),
      daretMembersProvider(_daretId).overrideWith(
        (ref) => Stream.value(_members),
      ),
      periodsProvider(
        _daretId,
      ).overrideWith((ref) => Stream.value(hostPeriods)),
      currentContributionsProvider(
        (_daretId, hostDaret.currentPeriode),
      ).overrideWith(
        (ref) => Stream.value(hostContributions),
      ),
      activityProvider(_daretId).overrideWith(
        (ref) => Stream.value(hostActivity),
      ),
    ],
    child: const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: DaretHubScreen(daretId: _daretId),
      ),
    ),
  );
}

Future<void> _dismissPayoutTakeover(WidgetTester tester) async {
  if (find.text("C'EST VOTRE TOUR !").evaluate().isEmpty) return;
  await tester.tap(find.text('Continuer'));
  await tester.pumpAndSettle();
}
