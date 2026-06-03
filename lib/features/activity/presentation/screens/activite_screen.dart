import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/activity/data/activity_providers.dart';
import 'package:tantin_flutter/features/activity/domain/activity_event.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

class _Item {
  const _Item(this.daretNom, this.event);

  final String daretNom;
  final ActivityEvent event;
}

/// Activité — a plain chronological log merged across all the user's darets.
/// No gamification, just what happened, newest first.
class ActiviteScreen extends ConsumerWidget {
  const ActiviteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final darets = ref.watch(myDaretsProvider).valueOrNull ?? const <Daret>[];
    final items = <_Item>[];
    for (final d in darets) {
      final events =
          ref.watch(activityProvider(d.id)).valueOrNull ??
          const <ActivityEvent>[];
      for (final e in events) {
        items.add(_Item(d.nom, e));
      }
    }
    items.sort((a, b) => b.event.createdAt.compareTo(a.event.createdAt));

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const ScreenHeader(
              title: 'Activité',
              subtitle: 'Tout ce qui se passe dans vos darets',
            ),
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(20),
                child: EmptyBlock(
                  title: 'Aucune activité',
                  body: 'Les paiements, rappels et tours apparaîtront ici.',
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    for (final item in items) _Row(item: item),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item});

  final _Item item;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _visual(item.event.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TantinColors.hairline),
          boxShadow: TantinShadows.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: icon,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.event.text,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: TantinColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.daretNom} · '
                    '${TantinDates.relative(item.event.createdAt)}',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: TantinColors.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (item.event.amount != null)
              Text(
                TantinFormat.fmtDH(item.event.amount!),
                style: const TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 14,
                  color: TantinColors.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }

  (Widget, Color) _visual(ActivityType type) {
    switch (type) {
      case ActivityType.paiement:
        return (
          TnIcons.checkCircle(size: 19, color: TantinColors.success),
          TantinColors.success,
        );
      case ActivityType.tour:
        return (
          TnIcons.gift(size: 19, color: TantinColors.saffronDeep),
          TantinColors.saffronDeep,
        );
      case ActivityType.rappel:
        return (
          TnIcons.clock(size: 19, color: TantinColors.terracotta),
          TantinColors.terracotta,
        );
      case ActivityType.membre:
        return (
          TnIcons.user(size: 19, color: TantinColors.majorelle),
          TantinColors.majorelle,
        );
      case ActivityType.demarre:
        return (
          TnIcons.sparkle(size: 19, color: TantinColors.majorelle),
          TantinColors.majorelle,
        );
      case ActivityType.cloture:
        return (
          TnIcons.check(size: 19, color: TantinColors.inkMuted),
          TantinColors.inkMuted,
        );
    }
  }
}
