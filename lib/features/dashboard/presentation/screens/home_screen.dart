import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_logic.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/darets/presentation/widgets/daret_card.dart';
import 'package:tantin_flutter/features/notifications/data/notification_providers.dart';
import 'package:tantin_flutter/features/notifications/domain/app_notification.dart';
import 'package:tantin_flutter/features/profile/data/user_providers.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

T? _firstOrNull<T>(Iterable<T> items) {
  for (final item in items) {
    return item;
  }
  return null;
}

/// Accueil (dashboard) — the home tab. Greeting + bell, the hero next-action
/// card (from [nextDashboardAction]), the Ce mois-ci entrées/sorties summary,
/// and the active darets, all from live Firestore data.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final notifs =
        ref.watch(notificationsProvider).valueOrNull ??
        const <AppNotification>[];
    final unread = notifs.where((n) => n.unread).length;
    final darets = ref.watch(myDaretsProvider()).valueOrNull ?? const <Daret>[];
    final active = darets.where((d) => d.statut == DaretStatus.actif).toList();

    final periodsByDaret = <String, List<DaretPeriod>>{};
    final contribsByDaret = <String, List<Contribution>>{};
    for (final d in active) {
      periodsByDaret[d.id] =
          ref.watch(periodsProvider(d.id)).valueOrNull ?? const <DaretPeriod>[];
      contribsByDaret[d.id] =
          ref
              .watch(currentContributionsProvider(d.id, d.currentPeriode))
              .valueOrNull ??
          const <Contribution>[];
    }

    final uid = user?.uid;
    final next = uid == null
        ? null
        : nextDashboardAction(
            uid: uid,
            darets: active,
            periodsByDaret: periodsByDaret,
            currentContributionsByDaret: contribsByDaret,
            now: DateTime.now(),
          );

    var entrees = 0;
    var sorties = 0;
    for (final d in active) {
      final current = _firstOrNull(
        (periodsByDaret[d.id] ?? const <DaretPeriod>[]).where(
          (p) => p.index == d.currentPeriode,
        ),
      );
      if (current != null &&
          uid != null &&
          current.recipientUids.contains(uid)) {
        entrees += current.potAmount;
      }
      final mine = _firstOrNull(
        (contribsByDaret[d.id] ?? const <Contribution>[]).where(
          (c) => c.payerUid == uid,
        ),
      );
      if (mine != null &&
          (mine.state == ContributionState.apayer ||
              mine.state == ContributionState.attente ||
              mine.state == ContributionState.retard)) {
        sorties += mine.amount;
      }
    }

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            _TopBar(
              user: user,
              unread: unread,
              onBell: () => context.push('/notifications'),
            ),
            if (next != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
                child: _SmartCard(
                  action: next,
                  daret: _firstOrNull(
                    active.where((d) => d.id == next.daretId),
                  ),
                  onTap: () => context.push('/daret/${next.daretId}'),
                ),
              ),
            _MonthSummary(entrees: entrees, sorties: sorties),
            if (active.isEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: EmptyBlock(
                  title: "Bienvenue sur Tant'in",
                  body:
                      'Appuyez sur le + pour créer ou rejoindre '
                      'votre premier daret.',
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 11),
                      child: Text(
                        'Mes darets actifs',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontSize: 17,
                              letterSpacing: -0.34,
                              color: TantinColors.ink,
                            ),
                      ),
                    ),
                    for (final d in active) ...[
                      DaretCard(
                        daret: d,
                        onTap: () => context.push('/daret/${d.id}'),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.user,
    required this.unread,
    required this.onBell,
  });

  final AppUser? user;
  final int unread;
  final VoidCallback onBell;

  @override
  Widget build(BuildContext context) {
    final palette = user?.avatarPalette ?? const <String>[];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Avatar(
                data: AvatarData(
                  initials: user?.initials ?? '',
                  bgColor: palette.isNotEmpty
                      ? hexToColor(palette.first)
                      : TantinColors.majorelle,
                ),
                size: 42,
              ),
              const SizedBox(width: 11),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bonjour,',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: TantinColors.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    user?.prenom ?? '',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 19,
                      letterSpacing: -0.38,
                      color: TantinColors.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Pressable(
            onPressed: onBell,
            child: Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TantinColors.ivorySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: TantinColors.hairline),
                boxShadow: TantinShadows.sm,
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TnIcons.bell(size: 21, color: TantinColors.ink),
                  if (unread > 0)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: TantinColors.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmartCard extends StatelessWidget {
  const _SmartCard({required this.action, required this.daret, this.onTap});

  final DashboardNextAction action;
  final Daret? daret;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPay = action.type == DashboardActionType.payContribution;
    final label = isPay ? 'À FAIRE MAINTENANT' : 'BIENTÔT';
    final lead = isPay ? 'Votre part pour' : 'Vous recevez pour';
    final name = daret?.nom ?? 'votre daret';
    return Pressable(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [TantinColors.majorelle, TantinColors.majorelleDeep],
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66352DA8),
              offset: Offset(0, 16),
              blurRadius: 40,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0x38F5A623),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TnIcons.bolt(size: 14, color: const Color(0xFFF5C76A)),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFFFCDFA6),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text.rich(
              TextSpan(
                text: '$lead ',
                style: const TextStyle(
                  color: Color(0xD1FFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                children: [
                  TextSpan(
                    text: name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              TantinFormat.fmtDH(action.amount),
              style: const TextStyle(
                fontFamily: 'Fraunces',
                color: Colors.white,
                fontSize: 44,
                height: 1,
                letterSpacing: -1.3,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TnIcons.clock(size: 15, color: const Color(0xB3FFFFFF)),
                const SizedBox(width: 7),
                Text(
                  'Échéance le ${TantinDates.dayMonth(action.date)}',
                  style: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: TantinColors.saffron,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Text(
                      'Voir le daret',
                      style: TextStyle(
                        color: Color(0xFF2A1B05),
                        fontWeight: FontWeight.w700,
                        fontSize: 15.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthSummary extends StatelessWidget {
  const _MonthSummary({required this.entrees, required this.sorties});

  final int entrees;
  final int sorties;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ce mois-ci',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 17,
                    letterSpacing: -0.34,
                    color: TantinColors.ink,
                  ),
                ),
                Text(
                  TantinDates.monthYear(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 13,
                    color: TantinColors.inkMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _SummaryTile(
                  label: 'Entrées',
                  amount: entrees,
                  color: TantinColors.success,
                  icon: TnIcons.arrowDown(
                    size: 17,
                    color: TantinColors.success,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SummaryTile(
                  label: 'Sorties',
                  amount: sorties,
                  color: TantinColors.terracotta,
                  icon: TnIcons.arrowUp(
                    size: 17,
                    color: TantinColors.terracotta,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.amount,
    required this.color,
    required this.icon,
  });

  final String label;
  final int amount;
  final Color color;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 15),
      decoration: BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TantinColors.hairline),
        boxShadow: TantinShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: icon,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: TantinColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            TantinFormat.fmtDH(amount),
            style: TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 22,
              letterSpacing: -0.44,
              color: color,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
