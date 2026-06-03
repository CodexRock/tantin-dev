// goldenTest registers a test (like testWidgets) and returns an unawaited
// Future at the top level — silence discarded_futures.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:tantin_flutter/features/darets/domain/daret_logic.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/dashboard/presentation/widgets/smart_card.dart';

Widget _static(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

const _daret = Daret(
  id: 'd1',
  nom: 'Daret Famille',
  cover: '🏡',
  accent: '#5247E6',
  montant: 1500,
  frequence: DaretFrequency.mensuel,
  periodesCount: 12,
  cagnotteParPeriode: 18000,
  statut: DaretStatus.actif,
  adminUid: 'u0',
  memberUids: ['u0'],
  currentPeriode: 4,
  settings: DaretSettings(echeanceDay: 5, graceDays: 2),
);

void main() {
  goldenTest(
    'SmartCard — hero next-action',
    fileName: 'smart_card',
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'pay',
          child: _static(
            SizedBox(
              width: 360,
              child: SmartCard(
                action: DashboardNextAction(
                  type: DashboardActionType.payContribution,
                  daretId: 'd1',
                  amount: 1500,
                  date: DateTime.utc(2026, 6, 5),
                ),
                daret: _daret,
                onPrimary: () {},
                onOpen: () {},
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'receive',
          child: _static(
            SizedBox(
              width: 360,
              child: SmartCard(
                action: DashboardNextAction(
                  type: DashboardActionType.receiveSoon,
                  daretId: 'd1',
                  amount: 18000,
                  date: DateTime.utc(2026, 6, 5),
                ),
                daret: _daret,
                onPrimary: () {},
                onOpen: () {},
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
