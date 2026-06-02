// `goldenTest` registers a test (like `testWidgets`) and returns a Future that
// is intentionally not awaited at the top level — so silence discarded_futures.
// ignore_for_file: discarded_futures
import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';

/// Disables animations so every animated component (Reveal, Skel, ProgressRing,
/// Pressable, AnimatedContainer/Positioned) renders its deterministic final
/// frame. Combined with alchemist's CI goldens (text as blocks), this makes the
/// goldens identical on Windows and the Linux CI runner.
Widget _static(Widget child) => Builder(
  builder: (context) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: true),
    child: child,
  ),
);

/// Wraps overlay (Positioned-based) components in a bounded Stack for goldens.
Widget _overlay(Widget child, {double w = 320, double h = 420}) => _static(
  SizedBox(
    width: w,
    height: h,
    child: Stack(children: [child]),
  ),
);

Future<void> _pumpOnce(WidgetTester tester) =>
    tester.pump(const Duration(milliseconds: 50));

void main() {
  goldenTest(
    'Button — all variants',
    fileName: 'buttons',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'primary',
          child: _static(
            TnButton(onPressed: () {}, child: const Text('Payer')),
          ),
        ),
        GoldenTestScenario(
          name: 'saffron',
          child: _static(
            TnButton(
              variant: ButtonVariant.saffron,
              onPressed: () {},
              child: const Text('Inviter'),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'soft',
          child: _static(
            TnButton(
              variant: ButtonVariant.soft,
              onPressed: () {},
              child: const Text('Voir'),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'ghost',
          child: _static(
            TnButton(
              variant: ButtonVariant.ghost,
              onPressed: () {},
              child: const Text('Annuler'),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'danger',
          child: _static(
            TnButton(
              variant: ButtonVariant.danger,
              onPressed: () {},
              child: const Text('Supprimer'),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'dark',
          child: _static(
            TnButton(
              variant: ButtonVariant.dark,
              onPressed: () {},
              child: const Text('Continuer'),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'sm',
          child: _static(
            TnButton(
              size: ButtonSize.sm,
              onPressed: () {},
              child: const Text('Petit'),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'lg',
          child: _static(
            TnButton(
              size: ButtonSize.lg,
              onPressed: () {},
              child: const Text('Grand'),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'disabled',
          child: _static(
            TnButton(
              disabled: true,
              onPressed: () {},
              child: const Text('Payer'),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'StateBadge — all 5 states',
    fileName: 'state_badges',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'apayer',
          child: _static(const StateBadge(state: DaretState.apayer)),
        ),
        GoldenTestScenario(
          name: 'attente',
          child: _static(const StateBadge(state: DaretState.attente)),
        ),
        GoldenTestScenario(
          name: 'confirme',
          child: _static(const StateBadge(state: DaretState.confirme)),
        ),
        GoldenTestScenario(
          name: 'retard',
          child: _static(const StateBadge(state: DaretState.retard)),
        ),
        GoldenTestScenario(
          name: 'recipient',
          child: _static(const StateBadge(state: DaretState.recipient)),
        ),
        GoldenTestScenario(
          name: 'small',
          child: _static(
            const StateBadge(state: DaretState.confirme, small: true),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'Card',
    fileName: 'cards',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'plain',
          child: _static(
            const SizedBox(
              width: 240,
              child: TnCard(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Daret Famille'),
                ),
              ),
            ),
          ),
        ),
        GoldenTestScenario(
          name: 'accent',
          child: _static(
            const SizedBox(
              width: 240,
              child: TnCard(
                accent: TantinColors.majorelle,
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('Avec accent'),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'Avatar & AvatarStack (+N overflow)',
    fileName: 'avatars',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'single',
          child: _static(const Avatar(data: AvatarData(initials: 'YB'))),
        ),
        GoldenTestScenario(
          name: 'single-ring',
          child: _static(
            const Avatar(data: AvatarData(initials: 'AM'), ring: true),
          ),
        ),
        GoldenTestScenario(
          name: 'stack-overflow',
          child: _static(
            AvatarStack(
              avatars: List.generate(
                7,
                (i) => AvatarData(
                  initials: 'U$i',
                  bgColor: [
                    TantinColors.majorelle,
                    TantinColors.saffron,
                    TantinColors.success,
                  ][i % 3],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'ProgressRing — several values',
    fileName: 'progress_rings',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: '0',
          child: _static(const ProgressRing(value: 0, total: 100)),
        ),
        GoldenTestScenario(
          name: '40',
          child: _static(const ProgressRing(value: 40, total: 100)),
        ),
        GoldenTestScenario(
          name: '100',
          child: _static(const ProgressRing(value: 100, total: 100)),
        ),
      ],
    ),
  );

  goldenTest(
    'Segmented',
    fileName: 'segmented',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'two-options',
          child: _static(
            SizedBox(
              width: 340,
              child: Segmented<int>(
                value: 0,
                onChange: (_) {},
                options: const [
                  SegmentedOption(value: 0, label: 'Actifs', count: '3'),
                  SegmentedOption(value: 1, label: 'Terminés'),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'EmptyBlock',
    fileName: 'empty_block',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'with-action',
          child: _static(
            SizedBox(
              width: 320,
              child: EmptyBlock(
                title: 'Aucun daret',
                body: 'Créez votre premier daret pour commencer.',
                action: 'Créer un daret',
                onAction: () {},
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'Sheet — open',
    fileName: 'sheet',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'open',
          child: _overlay(
            Sheet(
              open: true,
              onClose: () {},
              title: 'Confirmer',
              child: const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Text('Contenu de la feuille.'),
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'Toast',
    fileName: 'toast',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'success',
          child: _overlay(
            const Toast(
              toast: ToastData(
                msg: 'Paiement confirmé',
                type: ToastType.success,
              ),
            ),
          ),
        ),
      ],
    ),
  );

  goldenTest(
    'Skel — static (animations disabled)',
    fileName: 'skel',
    pumpBeforeTest: _pumpOnce,
    builder: () => GoldenTestGroup(
      children: [
        GoldenTestScenario(
          name: 'block',
          child: _static(const SizedBox(width: 200, child: Skel())),
        ),
      ],
    ),
  );
}
