import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

class _CalItem {
  const _CalItem({
    required this.date,
    required this.daretNom,
    required this.accent,
    required this.isEntree,
    required this.amount,
  });

  final DateTime date;
  final String daretNom;
  final Color accent;
  final bool isEntree;
  final int amount;
}

/// Calendrier — an agenda of upcoming pay-ins (sorties you owe) and payouts
/// (entrées you receive) derived from each active daret's periods.
class CalendrierScreen extends ConsumerWidget {
  const CalendrierScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
    final darets = ref.watch(myDaretsProvider()).valueOrNull ?? const <Daret>[];
    final active = darets.where((d) => d.statut == DaretStatus.actif).toList();

    final items = <_CalItem>[];
    for (final d in active) {
      final periods =
          ref.watch(periodsProvider(d.id)).valueOrNull ?? const <DaretPeriod>[];
      for (final p in periods.where((p) => p.index >= d.currentPeriode)) {
        final isEntree = uid != null && p.recipientUids.contains(uid);
        items.add(
          _CalItem(
            date: p.scheduledDate,
            daretNom: d.nom,
            accent: hexToColor(d.accent),
            isEntree: isEntree,
            amount: isEntree ? p.potAmount : d.montant,
          ),
        );
      }
    }
    items.sort((a, b) => a.date.compareTo(b.date));

    final children = <Widget>[
      const ScreenHeader(
        title: 'Calendrier',
        subtitle: 'Vos entrées et sorties à venir',
      ),
    ];
    if (items.isEmpty) {
      children.add(
        const Padding(
          padding: EdgeInsets.all(20),
          child: EmptyBlock(
            title: 'Rien de prévu',
            body: 'Vos prochaines échéances apparaîtront ici.',
          ),
        ),
      );
    } else {
      String? lastMonth;
      for (final item in items) {
        final month = TantinDates.monthYear(item.date);
        if (month != lastMonth) {
          children.add(_MonthLabel(label: month));
          lastMonth = month;
        }
        children.add(_CalRow(item: item));
      }
    }

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: children,
        ),
      ),
    );
  }
}

class _MonthLabel extends StatelessWidget {
  const _MonthLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          color: TantinColors.inkMuted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CalRow extends StatelessWidget {
  const _CalRow({required this.item});

  final _CalItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isEntree
        ? TantinColors.success
        : TantinColors.terracotta;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TantinColors.hairline),
          boxShadow: TantinShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.accent.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                '${item.date.day}',
                style: TextStyle(
                  fontFamily: 'Fraunces',
                  fontSize: 18,
                  color: item.accent,
                ),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item.daretNom,
                    style: const TextStyle(
                      fontSize: 15,
                      color: TantinColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.isEntree ? 'Vous recevez' : 'Votre part',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${item.isEntree ? '+' : '−'}${TantinFormat.fmtDH(item.amount)}',
              style: TextStyle(
                fontFamily: 'Fraunces',
                fontSize: 15,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
