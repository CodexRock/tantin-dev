import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/features/darets/domain/daret_logic.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

void main() {
  group('daret math', () {
    test('computes the pot for one period', () {
      expect(cagnotteParPeriode(montant: 1500, memberCount: 12), 18000);
    });

    test('generates monthly dates and clamps short months', () {
      final schedule = generateSchedule(
        startDate: DateTime(2026, 1, 15),
        frequency: DaretFrequency.mensuel,
        periodesCount: 3,
        echeanceDay: 31,
      );

      expect(
        schedule,
        <DateTime>[
          DateTime(2026, 1, 31),
          DateTime(2026, 2, 28),
          DateTime(2026, 3, 31),
        ],
      );
    });

    test('generates weekly dates from the start date', () {
      final schedule = generateSchedule(
        startDate: DateTime(2026, 6, 2),
        frequency: DaretFrequency.hebdomadaire,
        periodesCount: 3,
        echeanceDay: 5,
      );

      expect(
        schedule,
        <DateTime>[
          DateTime(2026, 6, 2),
          DateTime(2026, 6, 9),
          DateTime(2026, 6, 16),
        ],
      );
    });
  });

  group('group shares', () {
    test('defaults to deterministic equal shares totaling 100', () {
      final shares = equalShares(const ['a', 'b', 'c']);

      expect(shares, const {'a': 34, 'b': 33, 'c': 33});
      expect(hasValidShares(shares), isTrue);
    });

    test('rejects empty, zero, and non-100 splits', () {
      expect(hasValidShares(const {}), isFalse);
      expect(hasValidShares(const {'a': 100, 'b': 0}), isFalse);
      expect(hasValidShares(const {'a': 60, 'b': 30}), isFalse);
    });
  });

  group('two-sided contribution state machine', () {
    final legalTransitions =
        <
          (
            ContributionState,
            ContributionActorRole,
            ContributionAction,
            ContributionState,
          )
        >[
          (
            ContributionState.apayer,
            ContributionActorRole.payer,
            ContributionAction.declarePaid,
            ContributionState.attente,
          ),
          (
            ContributionState.retard,
            ContributionActorRole.payer,
            ContributionAction.declarePaid,
            ContributionState.attente,
          ),
          (
            ContributionState.attente,
            ContributionActorRole.recipient,
            ContributionAction.confirmReceived,
            ContributionState.confirme,
          ),
          (
            ContributionState.attente,
            ContributionActorRole.admin,
            ContributionAction.confirmReceived,
            ContributionState.confirme,
          ),
          (
            ContributionState.apayer,
            ContributionActorRole.admin,
            ContributionAction.adminConfirm,
            ContributionState.confirme,
          ),
          (
            ContributionState.retard,
            ContributionActorRole.admin,
            ContributionAction.adminConfirm,
            ContributionState.confirme,
          ),
          (
            ContributionState.attente,
            ContributionActorRole.admin,
            ContributionAction.adminConfirm,
            ContributionState.confirme,
          ),
          (
            ContributionState.apayer,
            ContributionActorRole.scheduler,
            ContributionAction.markOverdue,
            ContributionState.retard,
          ),
        ];

    test('accepts every documented state-changing transition', () {
      for (final (current, role, action, expected) in legalTransitions) {
        expect(
          nextContributionState(
            current: current,
            actorRole: role,
            action: action,
          ),
          expected,
        );
      }
    });

    test('nudge never mutates contribution state', () {
      for (final state in ContributionState.values) {
        expect(
          nextContributionState(
            current: state,
            actorRole: ContributionActorRole.other,
            action: ContributionAction.sendNudge,
          ),
          state,
        );
      }
    });

    test('rejects every undocumented state-changing transition', () {
      final documented = legalTransitions
          .map((item) => (item.$1, item.$2, item.$3))
          .toSet();
      for (final state in ContributionState.values) {
        for (final role in ContributionActorRole.values) {
          for (final action in ContributionAction.values.where(
            (item) => item != ContributionAction.sendNudge,
          )) {
            if (documented.contains((state, role, action))) continue;
            expect(
              () => nextContributionState(
                current: state,
                actorRole: role,
                action: action,
              ),
              throwsA(isA<InvalidContributionTransition>()),
              reason: '${state.name} ${role.name} ${action.name}',
            );
          }
        }
      }
    });
  });

  group('period progress', () {
    test(
      'counts confirmed contributors and excludes recipient placeholders',
      () {
        final progress = periodProgress([
          contribution('a', ContributionState.confirme),
          contribution('b', ContributionState.attente),
          contribution('c', ContributionState.recipient),
        ]);

        expect(progress.paidCount, 1);
        expect(progress.totalCount, 2);
        expect(progress.ratio, 0.5);
      },
    );
  });

  group('dashboard next action', () {
    test('prioritizes the earliest actionable contribution', () {
      final action = nextDashboardAction(
        uid: 'me',
        darets: [
          daret(id: 'later', currentPeriode: 1),
          daret(id: 'urgent', currentPeriode: 1),
        ],
        periodsByDaret: {
          'later': [period(id: '01', index: 1, day: 8)],
          'urgent': [period(id: '01', index: 1, day: 5)],
        },
        currentContributionsByDaret: {
          'later': [contribution('me', ContributionState.apayer)],
          'urgent': [contribution('me', ContributionState.retard)],
        },
        now: DateTime(2026, 6, 2),
      );

      expect(action?.type, DashboardActionType.payContribution);
      expect(action?.daretId, 'urgent');
      expect(action?.amount, 1500);
    });

    test('computes the upcoming recipient action', () {
      final action = nextDashboardAction(
        uid: 'me',
        darets: [daret(id: 'copines', currentPeriode: 2)],
        periodsByDaret: {
          'copines': [
            period(id: '02', index: 2, day: 3),
            period(id: '03', index: 3, day: 10, recipients: const ['me']),
          ],
        },
        currentContributionsByDaret: const {},
        now: DateTime(2026, 6, 2),
      );

      expect(action?.type, DashboardActionType.receiveSoon);
      expect(action?.daretId, 'copines');
      expect(action?.amount, 18000);
    });
  });
}

Daret daret({
  required String id,
  required int currentPeriode,
}) {
  return Daret(
    id: id,
    nom: id,
    cover: '',
    accent: '#5247E6',
    montant: 1500,
    frequence: DaretFrequency.mensuel,
    periodesCount: 12,
    cagnotteParPeriode: 18000,
    statut: DaretStatus.actif,
    adminUid: 'admin',
    memberUids: const ['me', 'admin'],
    currentPeriode: currentPeriode,
    settings: const DaretSettings(echeanceDay: 5, graceDays: 2),
  );
}

DaretPeriod period({
  required String id,
  required int index,
  required int day,
  List<String> recipients = const ['recipient'],
}) {
  return DaretPeriod(
    id: id,
    index: index,
    recipientUids: recipients,
    shares: {recipients.first: 100},
    scheduledDate: DateTime(2026, 6, day),
    potAmount: 18000,
    status: PeriodStatus.current,
    paidCount: 0,
    totalCount: 1,
  );
}

Contribution contribution(String uid, ContributionState state) {
  return Contribution(
    payerUid: uid,
    state: state,
    amount: 1500,
  );
}
