import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

/// The rich "Mes Darets" card: cover, name, amount/frequency, status chip,
/// member avatar stack, and a status-specific footer (progress / approvals /
/// "tour reçu"). Reads member + contribution streams live.
class DaretCard extends ConsumerWidget {
  const DaretCard({required this.daret, this.onTap, super.key});

  final Daret daret;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = hexToColor(daret.accent);
    final members =
        ref.watch(daretMembersProvider(daret.id)).valueOrNull ??
        const <DaretMember>[];
    final avatars = members
        .map(
          (m) => AvatarData(
            initials: m.initials,
            bgColor: m.avatarPalette.isNotEmpty
                ? hexToColor(m.avatarPalette.first)
                : accent,
          ),
        )
        .toList();

    return Pressable(
      onPressed: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: TantinColors.hairline),
          boxShadow: TantinShadows.md,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Header(daret: daret, accent: accent),
              const Divider(height: 1, color: TantinColors.hairline),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AvatarStack(avatars: avatars, size: 28, maxCount: 5),
                    _Footer(daret: daret, accent: accent, members: members),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.daret, required this.accent});

  final Daret daret;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final unit = daret.frequence == DaretFrequency.mensuel ? 'mois' : 'sem.';
    final amount = TantinFormat.fmtDH(daret.montant);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(daret.cover, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  daret.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 18.5,
                    letterSpacing: -0.37,
                    color: TantinColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$amount / $unit · ${daret.periodesCount} tours',
                  style: const TextStyle(
                    fontSize: 13,
                    color: TantinColors.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 9),
                _StatusChip(status: daret.statut),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DaretStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color, bg) = switch (status) {
      DaretStatus.actif => (
        'Actif',
        TantinColors.success,
        const Color(0x1F2E9E6B),
      ),
      DaretStatus.attente => (
        "En attente d'approbation",
        TantinColors.saffronDeep,
        const Color(0x24F5A623),
      ),
      DaretStatus.termine => (
        'Terminé',
        TantinColors.inkMuted,
        TantinColors.ivorySunken,
      ),
      DaretStatus.brouillon => (
        'Brouillon',
        TantinColors.inkMuted,
        TantinColors.ivorySunken,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Footer extends ConsumerWidget {
  const _Footer({
    required this.daret,
    required this.accent,
    required this.members,
  });

  final Daret daret;
  final Color accent;
  final List<DaretMember> members;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final percent = daret.periodesCount == 0
        ? 0
        : (daret.currentPeriode / daret.periodesCount * 100).round();

    switch (daret.statut) {
      case DaretStatus.actif:
        final contribs =
            ref
                .watch(
                  currentContributionsProvider((
                    daret.id,
                    daret.currentPeriode,
                  )),
                )
                .valueOrNull ??
            const <Contribution>[];
        final paid = contribs
            .where((c) => c.state == ContributionState.confirme)
            .length;
        final total = contribs
            .where((c) => c.state != ContributionState.recipient)
            .length;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$paid/$total payé',
              style: const TextStyle(
                fontSize: 12.5,
                color: TantinColors.inkMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 9),
            ProgressRing(
              value: daret.currentPeriode.toDouble(),
              total: daret.periodesCount.toDouble(),
              size: 40,
              strokeWidth: 4.5,
              color: accent,
              child: Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: accent,
                ),
              ),
            ),
          ],
        );
      case DaretStatus.attente:
        final approved = members
            .where((m) => m.approvalStatus == ApprovalStatus.approved)
            .length;
        return Text(
          '$approved/${members.length} ont approuvé',
          style: const TextStyle(
            fontSize: 12.5,
            color: TantinColors.saffronDeep,
            fontWeight: FontWeight.w700,
          ),
        );
      case DaretStatus.termine:
      case DaretStatus.brouillon:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TnIcons.checkCircle(size: 15, color: TantinColors.success),
            const SizedBox(width: 5),
            const Text(
              'Tour reçu',
              style: TextStyle(
                fontSize: 12.5,
                color: TantinColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        );
    }
  }
}
