import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/router/router.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/darets/data/daret_callable_providers.dart';

/// Opens the « + » Créer / Rejoindre sheet. A dev-only seed action (debug
/// builds) loads the canonical Firestore dataset.
Future<void> showCreateJoinSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const CreateJoinSheet(),
  );
}

class CreateJoinSheet extends ConsumerWidget {
  const CreateJoinSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.only(top: 4, bottom: 16),
              decoration: BoxDecoration(
                color: TantinColors.ivorySunken,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Text(
            'Nouveau daret',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 22,
              letterSpacing: -0.44,
              color: TantinColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          _Option(
            icon: TnIcons.plus(size: 22, color: TantinColors.majorelle),
            title: 'Créer un daret',
            subtitle: 'Lancez un nouveau cercle et invitez vos proches.',
            onTap: () => _go(context, AppRoutes.createDaret),
          ),
          const SizedBox(height: 12),
          _Option(
            icon: TnIcons.qr(size: 22, color: TantinColors.majorelle),
            title: 'Rejoindre avec un code',
            subtitle: "Entrez un code d'invitation reçu d'un proche.",
            onTap: () => _go(context, AppRoutes.joinDaret),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 12),
            _Option(
              icon: TnIcons.sparkle(size: 22, color: TantinColors.saffronDeep),
              title: 'Charger les données démo (dev)',
              subtitle: 'Remplit Firestore avec le jeu de données Yasmine.',
              onTap: () => _seed(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  void _go(BuildContext context, String route) {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    unawaited(router.push<void>(route));
  }

  Future<void> _seed(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Chargement des données démo…')),
    );
    try {
      await ref.read(daretCallableRepositoryProvider).seedDev();
      messenger.showSnackBar(
        const SnackBar(content: Text('Données démo chargées ✓')),
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Échec du seed : $error')),
      );
    }
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Widget icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TantinColors.ivoryBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TantinColors.majorelleSoft,
                borderRadius: BorderRadius.circular(13),
              ),
              child: icon,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: TantinColors.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: TantinColors.inkMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
