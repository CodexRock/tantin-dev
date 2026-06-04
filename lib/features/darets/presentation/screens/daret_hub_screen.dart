import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/activity/data/activity_providers.dart';
import 'package:tantin_flutter/features/activity/domain/activity_event.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_logic.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/profile/data/user_providers.dart';

enum _HubTab { courant, periodes, membres, activite }

class DaretHubScreen extends ConsumerStatefulWidget {
  const DaretHubScreen({required this.daretId, super.key});

  final String daretId;

  @override
  ConsumerState<DaretHubScreen> createState() => _DaretHubScreenState();
}

class _DaretHubScreenState extends ConsumerState<DaretHubScreen> {
  _HubTab _tab = _HubTab.courant;

  @override
  Widget build(BuildContext context) {
    final daretAsync = ref.watch(daretProvider(widget.daretId));
    final daret = daretAsync.valueOrNull;

    if (daretAsync.hasError) {
      return const Scaffold(
        backgroundColor: TantinColors.ivoryBg,
        body: SafeArea(
          child: Center(
            child: EmptyBlock(
              title: 'Daret introuvable',
              body: 'Impossible de charger les détails de ce daret.',
            ),
          ),
        ),
      );
    }

    if (daret == null) {
      return const Scaffold(
        backgroundColor: TantinColors.ivoryBg,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final currentUser = ref.watch(currentAppUserProvider).valueOrNull;
    final uid = currentUser?.uid;
    final members =
        ref.watch(daretMembersProvider(daret.id)).valueOrNull ??
        const <DaretMember>[];
    final periods =
        ref.watch(periodsProvider(daret.id)).valueOrNull ??
        const <DaretPeriod>[];
    final contributions =
        ref
            .watch(
              currentContributionsProvider((daret.id, daret.currentPeriode)),
            )
            .valueOrNull ??
        const <Contribution>[];
    final activity =
        ref.watch(activityProvider(daret.id)).valueOrNull ??
        const <ActivityEvent>[];

    final currentPeriod = periods.firstWhereOrNull(
      (period) => period.index == daret.currentPeriode,
    );
    final membersByUid = {for (final member in members) member.uid: member};
    final accent = hexToColor(daret.accent);
    final isAdmin = uid != null && uid == daret.adminUid;

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: Column(
        children: [
          _HubHeader(
            daret: daret,
            currentPeriod: currentPeriod,
            admin: membersByUid[daret.adminUid],
            accent: accent,
            isAdmin: isAdmin,
            onBack: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/darets');
              }
            },
            onHeaderAction: () => _showPartTwoSnack(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
            child: Segmented<_HubTab>(
              value: _tab,
              onChange: (tab) => setState(() => _tab = tab),
              options: const [
                SegmentedOption(value: _HubTab.courant, label: 'En cours'),
                SegmentedOption(value: _HubTab.periodes, label: 'Périodes'),
                SegmentedOption(value: _HubTab.membres, label: 'Membres'),
                SegmentedOption(value: _HubTab.activite, label: 'Activité'),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                18,
                14,
                18,
                24 + MediaQuery.paddingOf(context).bottom,
              ),
              children: [
                switch (_tab) {
                  _HubTab.courant => _CurrentPeriodTab(
                    daret: daret,
                    currentPeriod: currentPeriod,
                    membersByUid: membersByUid,
                    contributions: contributions,
                    currentUid: uid,
                    isAdmin: isAdmin,
                    accent: accent,
                    onAction: () => _showPartTwoSnack(context),
                  ),
                  _HubTab.periodes => _PeriodsTimelineTab(
                    daret: daret,
                    periods: periods,
                    membersByUid: membersByUid,
                    currentUid: uid,
                    accent: accent,
                  ),
                  _HubTab.membres => _MembersTab(
                    daret: daret,
                    periods: periods,
                    members: members,
                    currentUid: uid,
                    accent: accent,
                  ),
                  _HubTab.activite => _ActivityTab(
                    events: activity,
                    membersByUid: membersByUid,
                    accent: accent,
                  ),
                },
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPartTwoSnack(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Le flux de confirmation sera câblé au checkpoint Part 2.',
        ),
      ),
    );
  }
}

class _HubHeader extends StatelessWidget {
  const _HubHeader({
    required this.daret,
    required this.currentPeriod,
    required this.admin,
    required this.accent,
    required this.isAdmin,
    required this.onBack,
    required this.onHeaderAction,
  });

  final Daret daret;
  final DaretPeriod? currentPeriod;
  final DaretMember? admin;
  final Color accent;
  final bool isAdmin;
  final VoidCallback onBack;
  final VoidCallback onHeaderAction;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    final deep = _shade(accent, -0.26);
    final subtitle = isAdmin
        ? 'Vous administrez'
        : 'Administré par ${admin?.prenom ?? 'un membre'}';
    final date = currentPeriod == null
        ? daret.prochaineDate
        : currentPeriod!.scheduledDate;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, deep],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.26,
              child: TnArt.zelligeFaint(),
            ),
          ),
          Positioned(
            right: -34,
            top: top + 12,
            child: Opacity(
              opacity: 0.22,
              child: TnArt.starTile(size: 132, c1: Colors.white, c3: accent),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(18, top + 8, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _HeaderIconButton(
                      onPressed: onBack,
                      child: TnIcons.chevL(size: 22, color: Colors.white),
                    ),
                    Row(
                      children: [
                        if (isAdmin) ...[
                          _HeaderIconButton(
                            onPressed: onHeaderAction,
                            child: TnIcons.settings(
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _HeaderIconButton(
                          onPressed: onHeaderAction,
                          child: TnIcons.share(size: 19, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(
                        daret.cover,
                        style: const TextStyle(fontSize: 28),
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            daret.nom,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 24,
                                  letterSpacing: -0.48,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xD1FFFFFF),
                              fontSize: 13.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _HeaderStat(
                        label: 'Cagnotte / tour',
                        value: TantinFormat.fmtDH(
                          currentPeriod?.potAmount ?? daret.cagnotteParPeriode,
                        ),
                      ),
                    ),
                    Expanded(
                      child: _HeaderStat(
                        label: 'Période en cours',
                        value:
                            '${daret.currentPeriode} / ${daret.periodesCount}',
                      ),
                    ),
                    Expanded(
                      child: _HeaderStat(
                        label: 'Échéance',
                        value: date == null
                            ? 'À venir'
                            : TantinDates.dayMonth(date),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.onPressed, required this.child});

  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(13),
        ),
        child: child,
      ),
    );
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: 'Fraunces',
            fontSize: 18,
            letterSpacing: -0.18,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xB8FFFFFF),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CurrentPeriodTab extends StatelessWidget {
  const _CurrentPeriodTab({
    required this.daret,
    required this.currentPeriod,
    required this.membersByUid,
    required this.contributions,
    required this.currentUid,
    required this.isAdmin,
    required this.accent,
    required this.onAction,
  });

  final Daret daret;
  final DaretPeriod? currentPeriod;
  final Map<String, DaretMember> membersByUid;
  final List<Contribution> contributions;
  final String? currentUid;
  final bool isAdmin;
  final Color accent;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    if (currentPeriod == null) {
      return const EmptyBlock(
        title: 'Aucune période en cours',
        body: 'Ce daret n’a pas encore de tour actif.',
      );
    }

    final recipientUids = currentPeriod!.recipientUids;
    final iAmRecipient =
        currentUid != null && recipientUids.contains(currentUid);
    final progress = periodProgress(contributions);
    final myContribution = currentUid == null
        ? null
        : contributions.firstWhereOrNull(
            (contribution) => contribution.payerUid == currentUid,
          );
    final contributors =
        contributions
            .where(
              (contribution) =>
                  contribution.state != ContributionState.recipient,
            )
            .toList()
          ..sort(
            (left, right) => _memberOrder(
              daret.memberUids,
              left.payerUid,
            ).compareTo(_memberOrder(daret.memberUids, right.payerUid)),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RecipientCard(
          recipientUids: recipientUids,
          membersByUid: membersByUid,
          amount: currentPeriod!.potAmount,
          iAmRecipient: iAmRecipient,
        ),
        const SizedBox(height: 14),
        if (myContribution != null || iAmRecipient) ...[
          _MyActionBanner(
            daret: daret,
            contribution: myContribution,
            iAmRecipient: iAmRecipient,
            progress: progress,
            onAction: onAction,
          ),
          const SizedBox(height: 18),
        ],
        _ProgressSummary(progress: progress),
        const SizedBox(height: 12),
        if (contributors.isEmpty)
          const EmptyBlock(
            title: 'Aucune contribution',
            body: 'Les lignes de paiement apparaîtront ici.',
          )
        else
          Column(
            children: [
              for (var index = 0; index < contributors.length; index++) ...[
                _ContributionRow(
                  contribution: contributors[index],
                  member: membersByUid[contributors[index].payerUid],
                  isMe: contributors[index].payerUid == currentUid,
                  canConfirm: iAmRecipient || isAdmin,
                  canNudge: iAmRecipient || isAdmin,
                  onAction: onAction,
                ),
                if (index != contributors.length - 1) const SizedBox(height: 7),
              ],
            ],
          ),
      ],
    );
  }
}

class _RecipientCard extends StatelessWidget {
  const _RecipientCard({
    required this.recipientUids,
    required this.membersByUid,
    required this.amount,
    required this.iAmRecipient,
  });

  final List<String> recipientUids;
  final Map<String, DaretMember> membersByUid;
  final int amount;
  final bool iAmRecipient;

  @override
  Widget build(BuildContext context) {
    final recipients = recipientUids
        .map((uid) => membersByUid[uid])
        .whereType<DaretMember>()
        .toList(growable: false);
    final title = recipients.isEmpty
        ? 'Bénéficiaire'
        : recipients.map((member) => member.prenom).join(' & ');

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TantinColors.saffron, TantinColors.saffronDeep],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: TantinColors.saffron.withValues(alpha: 0.32),
            offset: const Offset(0, 12),
            blurRadius: 28,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.28,
                child: TnArt.zelligeFaint(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BÉNÉFICIAIRE DE CE TOUR',
                    style: TextStyle(
                      color: Color(0x992A1B05),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      AvatarStack(
                        avatars: recipients
                            .map(_avatarData)
                            .toList(
                              growable: false,
                            ),
                        maxCount: 3,
                        size: 48,
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$title${iAmRecipient ? ' (vous)' : ''}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: const Color(0xFF2A1B05),
                                    fontSize: 21,
                                    letterSpacing: -0.42,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'reçoit ${TantinFormat.fmtDH(amount)}',
                              style: const TextStyle(
                                color: Color(0xB32A1B05),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _MyActionBanner extends StatelessWidget {
  const _MyActionBanner({
    required this.daret,
    required this.contribution,
    required this.iAmRecipient,
    required this.progress,
    required this.onAction,
  });

  final Daret daret;
  final Contribution? contribution;
  final bool iAmRecipient;
  final PeriodProgress progress;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    if (iAmRecipient) {
      final allIn =
          progress.totalCount > 0 && progress.paidCount >= progress.totalCount;
      return _BannerShell(
        background: TantinColors.majorelleSoft,
        iconBg: TantinColors.majorelle,
        icon: TnIcons.gift(size: 22, color: Colors.white),
        title: allIn ? 'Tout est confirmé' : "C'est votre tour !",
        body: allIn
            ? 'La période peut être clôturée par l’admin.'
            : 'Confirmez les paiements reçus ci-dessous.',
        actionLabel: 'Voir',
        actionColor: TantinColors.majorelle,
        onAction: onAction,
      );
    }

    final state = contribution?.state;
    if (state == ContributionState.apayer ||
        state == ContributionState.retard) {
      final overdue = state == ContributionState.retard;
      return _BannerShell(
        background: overdue
            ? TantinColors.danger.withValues(alpha: 0.1)
            : TantinColors.ivorySurface,
        border: true,
        iconBg: overdue
            ? TantinColors.danger.withValues(alpha: 0.12)
            : TantinColors.saffron.withValues(alpha: 0.18),
        icon: TnIcons.arrowUp(
          size: 22,
          color: overdue ? TantinColors.danger : TantinColors.saffronDeep,
        ),
        title: 'Votre part : ${TantinFormat.fmtDH(daret.montant)}',
        body: overdue
            ? 'En retard - à régler au plus vite'
            : daret.prochaineDate == null
            ? 'Échéance à venir'
            : 'Échéance le ${TantinDates.dayMonth(daret.prochaineDate!)}',
        actionLabel: "J'ai payé ma part",
        actionColor: TantinColors.saffron,
        actionTextColor: const Color(0xFF2A1B05),
        onAction: onAction,
      );
    }

    if (state == ContributionState.attente) {
      return _BannerShell(
        background: TantinColors.saffron.withValues(alpha: 0.12),
        iconBg: TantinColors.saffron.withValues(alpha: 0.18),
        icon: TnIcons.clock(size: 22, color: TantinColors.saffronDeep),
        title: 'En attente de confirmation',
        body: 'Le bénéficiaire confirmera la réception.',
      );
    }

    if (state == ContributionState.confirme) {
      return _BannerShell(
        background: TantinColors.success.withValues(alpha: 0.1),
        iconBg: TantinColors.success.withValues(alpha: 0.12),
        icon: TnIcons.checkCircle(size: 22, color: TantinColors.success),
        title: 'Votre paiement est confirmé',
        body: 'Merci, tout est à jour pour ce tour.',
      );
    }

    return const SizedBox.shrink();
  }
}

class _BannerShell extends StatelessWidget {
  const _BannerShell({
    required this.background,
    required this.iconBg,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.actionColor,
    this.actionTextColor = Colors.white,
    this.onAction,
    this.border = false,
  });

  final Color background;
  final Color iconBg;
  final Widget icon;
  final String title;
  final String body;
  final String? actionLabel;
  final Color? actionColor;
  final Color actionTextColor;
  final VoidCallback? onAction;
  final bool border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: border ? Border.all(color: TantinColors.hairline) : null,
        boxShadow: border ? TantinShadows.sm : null,
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: icon,
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: TantinColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: const TextStyle(
                    color: TantinColors.inkMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(width: 10),
            _TinyButton(
              label: actionLabel!,
              background: actionColor ?? TantinColors.majorelle,
              foreground: actionTextColor,
              onPressed: onAction!,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.progress});

  final PeriodProgress progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Contributions',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  color: TantinColors.ink,
                  fontSize: 17,
                  letterSpacing: -0.34,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${progress.paidCount}/${progress.totalCount} ont payé',
                style: const TextStyle(
                  color: TantinColors.inkMuted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ProgressRing(
          value: progress.paidCount.toDouble(),
          total: progress.totalCount.toDouble(),
          color: TantinColors.success,
          child: Text(
            progress.totalCount == 0
                ? '0%'
                : '${(progress.ratio * 100).round()}%',
            style: const TextStyle(
              color: TantinColors.success,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContributionRow extends StatelessWidget {
  const _ContributionRow({
    required this.contribution,
    required this.member,
    required this.isMe,
    required this.canConfirm,
    required this.canNudge,
    required this.onAction,
  });

  final Contribution contribution;
  final DaretMember? member;
  final bool isMe;
  final bool canConfirm;
  final bool canNudge;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final name = member?.name ?? contribution.payerUid;
    final firstName = member?.prenom ?? name;
    final state = contribution.state;
    Widget? action;

    if (isMe &&
        (state == ContributionState.apayer ||
            state == ContributionState.retard)) {
      action = _TinyButton(
        label: "J'ai payé",
        background: TantinColors.saffron,
        foreground: const Color(0xFF2A1B05),
        onPressed: onAction,
      );
    } else if (state == ContributionState.attente && canConfirm) {
      action = _TinyButton(
        label: 'Reçu',
        icon: TnIcons.check(size: 15, color: Colors.white, strokeWidth: 2.6),
        background: TantinColors.success,
        foreground: Colors.white,
        onPressed: onAction,
      );
    } else if (!isMe &&
        canNudge &&
        (state == ContributionState.apayer ||
            state == ContributionState.retard)) {
      action = _TinyButton(
        label: 'Relancer',
        icon: TnIcons.bell(size: 14, color: TantinColors.majorelleDeep),
        background: TantinColors.majorelleSoft,
        foreground: TantinColors.majorelleDeep,
        onPressed: onAction,
      );
    } else if (state == ContributionState.attente && isMe) {
      action = const Text(
        'En attente',
        style: TextStyle(
          color: TantinColors.saffronDeep,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 10, 13, 10),
      decoration: BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: TantinColors.hairline),
        boxShadow: TantinShadows.sm,
      ),
      child: Row(
        children: [
          Avatar(data: _avatarData(member), size: 38),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    text: firstName,
                    children: [
                      if (isMe)
                        const TextSpan(
                          text: ' (vous)',
                          style: TextStyle(
                            color: TantinColors.inkMuted,
                            fontWeight: FontWeight.w500,
                            fontSize: 12.5,
                          ),
                        ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TantinColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                StateBadge(state: _badgeState(state), small: true),
              ],
            ),
          ),
          if (action != null) ...[
            const SizedBox(width: 10),
            action,
          ],
        ],
      ),
    );
  }
}

class _TinyButton extends StatelessWidget {
  const _TinyButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onPressed;
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeriodsTimelineTab extends StatelessWidget {
  const _PeriodsTimelineTab({
    required this.daret,
    required this.periods,
    required this.membersByUid,
    required this.currentUid,
    required this.accent,
  });

  final Daret daret;
  final List<DaretPeriod> periods;
  final Map<String, DaretMember> membersByUid;
  final String? currentUid;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (periods.isEmpty) {
      return const EmptyBlock(
        title: 'Aucune période',
        body: 'Le calendrier du daret apparaîtra ici.',
      );
    }

    return Stack(
      children: [
        Positioned(
          left: 19,
          top: 16,
          bottom: 16,
          child: Container(width: 2, color: TantinColors.hairline),
        ),
        Column(
          children: [
            for (var index = 0; index < periods.length; index++) ...[
              _PeriodTimelineRow(
                daret: daret,
                period: periods[index],
                membersByUid: membersByUid,
                currentUid: currentUid,
                accent: accent,
              ),
              if (index != periods.length - 1) const SizedBox(height: 9),
            ],
          ],
        ),
      ],
    );
  }
}

class _PeriodTimelineRow extends StatelessWidget {
  const _PeriodTimelineRow({
    required this.daret,
    required this.period,
    required this.membersByUid,
    required this.currentUid,
    required this.accent,
  });

  final Daret daret;
  final DaretPeriod period;
  final Map<String, DaretMember> membersByUid;
  final String? currentUid;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final past =
        period.status == PeriodStatus.closed ||
        period.index < daret.currentPeriode;
    final current =
        period.status == PeriodStatus.current ||
        period.index == daret.currentPeriode;
    final recipients = period.recipientUids
        .map((uid) => membersByUid[uid])
        .whereType<DaretMember>()
        .toList(growable: false);
    final names = recipients.isEmpty
        ? 'Bénéficiaire à venir'
        : recipients.map((member) => member.prenom).join(' & ');
    final includesMe =
        currentUid != null && period.recipientUids.contains(currentUid);
    final status = past
        ? ('Versé', TantinColors.success)
        : current
        ? ('En cours', accent)
        : ('À venir', TantinColors.inkMuted);
    final dateLabel = TantinDates.dayMonth(period.scheduledDate);
    final groupSuffix = period.recipientUids.length >= 2 ? ' · Groupe' : '';

    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: past
                    ? TantinColors.success
                    : current
                    ? accent
                    : TantinColors.ivorySurface,
                borderRadius: BorderRadius.circular(11),
                border: past || current
                    ? null
                    : Border.all(color: TantinColors.hairline, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: TantinColors.ivoryBg,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: past
                  ? TnIcons.check(
                      size: 17,
                      color: Colors.white,
                      strokeWidth: 2.6,
                    )
                  : Text(
                      '${period.index}',
                      style: TextStyle(
                        color: current ? Colors.white : TantinColors.inkMuted,
                        fontFamily: 'Fraunces',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Container(
            padding: current
                ? const EdgeInsets.fromLTRB(14, 12, 14, 12)
                : const EdgeInsets.fromLTRB(4, 8, 4, 8),
            decoration: BoxDecoration(
              color: current ? TantinColors.ivorySurface : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: current ? Border.all(color: accent, width: 1.5) : null,
              boxShadow: current ? TantinShadows.sm : null,
            ),
            child: Row(
              children: [
                AvatarStack(
                  avatars: recipients
                      .map(_avatarData)
                      .toList(
                        growable: false,
                      ),
                  maxCount: 3,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$names${includesMe ? ' (vous)' : ''}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: TantinColors.ink,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$dateLabel$groupSuffix',
                        style: const TextStyle(
                          color: TantinColors.inkMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  status.$1,
                  style: TextStyle(
                    color: status.$2,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MembersTab extends StatelessWidget {
  const _MembersTab({
    required this.daret,
    required this.periods,
    required this.members,
    required this.currentUid,
    required this.accent,
  });

  final Daret daret;
  final List<DaretPeriod> periods;
  final List<DaretMember> members;
  final String? currentUid;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const EmptyBlock(
        title: 'Aucun membre',
        body: 'Les membres approuvés apparaîtront ici.',
      );
    }

    final ordered = members.toList()
      ..sort(
        (left, right) => _memberOrder(
          daret.memberUids,
          left.uid,
        ).compareTo(_memberOrder(daret.memberUids, right.uid)),
      );

    return Column(
      children: [
        for (var index = 0; index < ordered.length; index++) ...[
          _MemberRow(
            member: ordered[index],
            turnIndex: periods
                .firstWhereOrNull(
                  (period) => period.recipientUids.contains(ordered[index].uid),
                )
                ?.index,
            isCurrentRecipient: periods.any(
              (period) =>
                  period.index == daret.currentPeriode &&
                  period.recipientUids.contains(ordered[index].uid),
            ),
            isMe: ordered[index].uid == currentUid,
            accent: accent,
          ),
          if (index != ordered.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.turnIndex,
    required this.isCurrentRecipient,
    required this.isMe,
    required this.accent,
  });

  final DaretMember member;
  final int? turnIndex;
  final bool isCurrentRecipient;
  final bool isMe;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final isAdmin = member.role == MemberRole.admin;
    final approved = member.approvalStatus == ApprovalStatus.approved;
    final subtitle = [
      if (isAdmin) 'Admin',
      if (isCurrentRecipient) 'Bénéficiaire actuel',
      if (!isCurrentRecipient && turnIndex != null) 'Tour $turnIndex',
      if (!approved) 'En attente',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      decoration: BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: TantinColors.hairline),
        boxShadow: TantinShadows.sm,
      ),
      child: Row(
        children: [
          Avatar(data: _avatarData(member), size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${member.name}${isMe ? ' (vous)' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TantinColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle.isEmpty ? 'Membre' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: TantinColors.inkMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isAdmin)
            const _Pill(
              label: 'Admin',
              color: TantinColors.majorelle,
              background: TantinColors.majorelleSoft,
            )
          else if (isCurrentRecipient)
            _Pill(
              label: 'Bénéficiaire',
              color: const Color(0xFF2A1B05),
              background: TantinColors.saffron.withValues(alpha: 0.22),
            )
          else
            _Pill(
              label: approved ? 'Membre' : 'Attente',
              color: approved ? accent : TantinColors.saffronDeep,
              background: approved
                  ? accent.withValues(alpha: 0.12)
                  : TantinColors.saffron.withValues(alpha: 0.14),
            ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({
    required this.events,
    required this.membersByUid,
    required this.accent,
  });

  final List<ActivityEvent> events;
  final Map<String, DaretMember> membersByUid;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return const EmptyBlock(
        title: 'Aucune activité',
        body: 'Les confirmations, rappels et tours seront listés ici.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < events.length; index++) ...[
          _ActivityRow(
            event: events[index],
            actor: membersByUid[events[index].actorUid],
            accent: accent,
          ),
          if (index != events.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.event,
    required this.actor,
    required this.accent,
  });

  final ActivityEvent event;
  final DaretMember? actor;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final iconColor = _activityColor(event.type, accent);
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.circular(15),
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
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: _activityIcon(event.type, iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.text,
                  style: const TextStyle(
                    color: TantinColors.ink,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    TantinDates.relative(event.createdAt),
                    if (actor != null) actor!.prenom,
                    if (event.amount != null) TantinFormat.fmtDH(event.amount!),
                  ].join(' · '),
                  style: const TextStyle(
                    color: TantinColors.inkMuted,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

Color _shade(Color color, double pct) {
  final r = (color.r * 255 + (255 * pct)).round().clamp(0, 255);
  final g = (color.g * 255 + (255 * pct)).round().clamp(0, 255);
  final b = (color.b * 255 + (255 * pct)).round().clamp(0, 255);
  return Color.fromRGBO(r, g, b, color.a);
}

AvatarData _avatarData(DaretMember? member) {
  final palette = member?.avatarPalette ?? const <String>[];
  return AvatarData(
    initials: member?.initials ?? '??',
    bgColor: palette.isEmpty
        ? TantinColors.majorelle
        : hexToColor(palette.first),
  );
}

DaretState _badgeState(ContributionState state) {
  return switch (state) {
    ContributionState.apayer => DaretState.apayer,
    ContributionState.attente => DaretState.attente,
    ContributionState.confirme => DaretState.confirme,
    ContributionState.retard => DaretState.retard,
    ContributionState.recipient => DaretState.recipient,
  };
}

int _memberOrder(List<String> orderedUids, String uid) {
  final index = orderedUids.indexOf(uid);
  return index == -1 ? orderedUids.length + 1 : index;
}

Color _activityColor(ActivityType type, Color accent) {
  return switch (type) {
    ActivityType.paiement => TantinColors.success,
    ActivityType.tour => accent,
    ActivityType.rappel => TantinColors.saffronDeep,
    ActivityType.membre => TantinColors.majorelle,
    ActivityType.demarre => TantinColors.terracotta,
    ActivityType.cloture => TantinColors.success,
  };
}

Widget _activityIcon(ActivityType type, Color color) {
  return switch (type) {
    ActivityType.paiement => TnIcons.checkCircle(size: 19, color: color),
    ActivityType.tour => TnIcons.gift(size: 19, color: color),
    ActivityType.rappel => TnIcons.bell(size: 19, color: color),
    ActivityType.membre => TnIcons.users(size: 19, color: color),
    ActivityType.demarre => TnIcons.sparkle(size: 19, color: color),
    ActivityType.cloture => TnIcons.checkCircle(size: 19, color: color),
  };
}

extension _FirstWhereOrNull<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T value) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }
}
