import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/motion/confetti.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/activity/data/activity_providers.dart';
import 'package:tantin_flutter/features/activity/domain/activity_event.dart';
import 'package:tantin_flutter/features/darets/data/daret_callable_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_logic.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/onboarding/presentation/widgets/big_wordmark.dart';
import 'package:tantin_flutter/features/profile/data/user_providers.dart';

enum _HubTab { courant, periodes, membres, activite }

typedef _ContributionAction = void Function(Contribution contribution);

class DaretHubScreen extends ConsumerStatefulWidget {
  const DaretHubScreen({required this.daretId, super.key});

  final String daretId;

  @override
  ConsumerState<DaretHubScreen> createState() => _DaretHubScreenState();
}

class _DaretHubScreenState extends ConsumerState<DaretHubScreen> {
  _HubTab _tab = _HubTab.courant;
  final Map<String, ContributionState> _optimisticStates = {};
  final Set<String> _busyKeys = {};
  String? _dismissedPayoutKey;
  bool _showClosureThanks = false;

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
    final contributions = _withOptimisticStates(
      daret.currentPeriode,
      ref
              .watch(
                currentContributionsProvider((daret.id, daret.currentPeriode)),
              )
              .valueOrNull ??
          const <Contribution>[],
    );
    final activity =
        ref.watch(activityProvider(daret.id)).valueOrNull ??
        const <ActivityEvent>[];

    final currentPeriod = periods.firstWhereOrNull(
      (period) => period.index == daret.currentPeriode,
    );
    final membersByUid = {for (final member in members) member.uid: member};
    final accent = hexToColor(daret.accent);
    final isAdmin = uid != null && uid == daret.adminUid;
    final currentMember = uid == null ? null : membersByUid[uid];
    final currentShare = uid == null ? 0 : currentPeriod?.shares[uid] ?? 0;
    final payoutAmount = currentPeriod == null
        ? 0
        : amountForShare(
            amount: currentPeriod.potAmount,
            share: currentShare == 0 ? 100 : currentShare,
          );
    final payoutKey = currentPeriod == null || uid == null
        ? null
        : '${daret.id}:${currentPeriod.id}:$uid';
    final showPayoutTakeover =
        daret.statut == DaretStatus.actif &&
        currentPeriod != null &&
        uid != null &&
        currentPeriod.recipientUids.contains(uid) &&
        _dismissedPayoutKey != payoutKey;

    if (_showClosureThanks || daret.statut == DaretStatus.termine) {
      return _ClotureThanksScreen(
        daret: daret,
        members: members,
        periods: periods,
        accent: accent,
        onBackToDarets: () => context.go('/darets'),
      );
    }

    if (showPayoutTakeover && currentMember != null) {
      return _PayoutTakeoverScreen(
        daret: daret,
        period: currentPeriod,
        member: currentMember,
        amount: payoutAmount,
        accent: accent,
        onShare: () => _showPayoutShareSheet(
          context,
          daret: daret,
          period: currentPeriod,
          member: currentMember,
          amount: payoutAmount,
          accent: accent,
        ),
        onContinue: () => setState(() => _dismissedPayoutKey = payoutKey),
      );
    }

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
            onHeaderAction: null,
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
                    busyKeys: _busyKeys,
                    onDeclarePaid: (contribution) {
                      if (currentPeriod == null) return;
                      unawaited(
                        _handleDeclarePaid(
                          daret: daret,
                          period: currentPeriod,
                          contribution: contribution,
                        ),
                      );
                    },
                    onConfirmReceived: (contribution) {
                      if (currentPeriod == null || uid == null) return;
                      unawaited(
                        _handleConfirmReceived(
                          daret: daret,
                          period: currentPeriod,
                          contribution: contribution,
                          payer: membersByUid[contribution.payerUid],
                          confirmerUid: uid,
                          adminDirectConfirm:
                              isAdmin &&
                              contribution.state != ContributionState.attente,
                        ),
                      );
                    },
                    onSendNudge: (contribution) {
                      if (currentPeriod == null) return;
                      unawaited(
                        _handleSendNudge(
                          daret: daret,
                          period: currentPeriod,
                          contribution: contribution,
                          payer: membersByUid[contribution.payerUid],
                        ),
                      );
                    },
                    advanceBusy: _busyKeys.contains(_advanceKey(daret.id)),
                    onAdvancePeriod: () =>
                        unawaited(_handleAdvancePeriod(daret)),
                    closeBusy: _busyKeys.contains(_closeDaretKey(daret.id)),
                    onCloseDaret: () => unawaited(_handleCloseDaret(daret)),
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

  List<Contribution> _withOptimisticStates(
    int periodIndex,
    List<Contribution> contributions,
  ) {
    return [
      for (final contribution in contributions)
        if (_optimisticStates[_contributionKey(
              periodIndex,
              contribution.payerUid,
            )]
            case final state?)
          contribution.copyWith(state: state)
        else
          contribution,
    ];
  }

  Future<void> _handleDeclarePaid({
    required Daret daret,
    required DaretPeriod period,
    required Contribution contribution,
  }) async {
    final confirmed = await _showConfirmPaySheet(
      context,
      daret: daret,
      contribution: contribution,
    );
    if (confirmed != true || !mounted) return;

    final key = _contributionKey(period.index, contribution.payerUid);
    await _runHubAction(
      busyKey: key,
      optimisticKey: key,
      optimisticState: ContributionState.attente,
      successMessage: 'Marqué comme payé - en attente de confirmation',
      failurePrefix: 'Paiement impossible',
      action: () => ref
          .read(daretRepositoryProvider)
          .declarePaid(
            daretId: daret.id,
            periodIndex: period.index,
            payerUid: contribution.payerUid,
          ),
    );
  }

  Future<void> _handleConfirmReceived({
    required Daret daret,
    required DaretPeriod period,
    required Contribution contribution,
    required DaretMember? payer,
    required String confirmerUid,
    required bool adminDirectConfirm,
  }) async {
    final confirmed = await _showReceivedSheet(
      context,
      daret: daret,
      contribution: contribution,
      payer: payer,
      adminDirectConfirm: adminDirectConfirm,
    );
    if (confirmed != true || !mounted) return;

    final key = _contributionKey(period.index, contribution.payerUid);
    await _runHubAction(
      busyKey: key,
      optimisticKey: key,
      optimisticState: ContributionState.confirme,
      successMessage: 'Paiement confirmé pour ${payer?.prenom ?? 'ce membre'}',
      failurePrefix: 'Confirmation impossible',
      action: () => ref
          .read(daretRepositoryProvider)
          .confirmReceived(
            daretId: daret.id,
            periodIndex: period.index,
            payerUid: contribution.payerUid,
            confirmedByUid: confirmerUid,
          ),
    );
  }

  Future<void> _handleSendNudge({
    required Daret daret,
    required DaretPeriod period,
    required Contribution contribution,
    required DaretMember? payer,
  }) async {
    await _runHubAction(
      busyKey: _nudgeKey(period.index, contribution.payerUid),
      successMessage: 'Rappel envoyé à ${payer?.prenom ?? 'ce membre'}',
      failurePrefix: 'Rappel impossible',
      action: () => ref
          .read(daretCallableRepositoryProvider)
          .sendNudge(
            daretId: daret.id,
            periodIndex: period.index,
            targetUid: contribution.payerUid,
          ),
    );
  }

  Future<void> _handleAdvancePeriod(Daret daret) async {
    await _runHubAction(
      busyKey: _advanceKey(daret.id),
      successMessage: 'Période clôturée - tour suivant',
      failurePrefix: 'Passage au tour suivant impossible',
      action: () =>
          ref.read(daretCallableRepositoryProvider).advancePeriod(daret.id),
    );
  }

  Future<void> _handleCloseDaret(Daret daret) async {
    final confirmed = await _showCloseDaretSheet(context, daret: daret);
    if (confirmed != true || !mounted) return;

    final closed = await _runHubAction(
      busyKey: _closeDaretKey(daret.id),
      successMessage: 'Daret clôturé - merci à tous',
      failurePrefix: 'Clôture impossible',
      action: () =>
          ref.read(daretCallableRepositoryProvider).closeDaret(daret.id),
    );
    if (closed && mounted) {
      setState(() => _showClosureThanks = true);
    }
  }

  Future<bool> _runHubAction({
    required String busyKey,
    required String successMessage,
    required String failurePrefix,
    required Future<void> Function() action,
    String? optimisticKey,
    ContributionState? optimisticState,
  }) async {
    if (_busyKeys.contains(busyKey)) return false;

    setState(() {
      _busyKeys.add(busyKey);
      if (optimisticKey != null && optimisticState != null) {
        _optimisticStates[optimisticKey] = optimisticState;
      }
    });

    try {
      await action();
    } on Object catch (error) {
      if (!mounted) return false;
      setState(() {
        _busyKeys.remove(busyKey);
        if (optimisticKey != null) _optimisticStates.remove(optimisticKey);
      });
      _showSnack('$failurePrefix : $error');
      return false;
    }

    if (!mounted) return false;
    setState(() {
      _busyKeys.remove(busyKey);
      if (optimisticKey != null) _optimisticStates.remove(optimisticKey);
    });
    _showSnack(successMessage);
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

Future<bool?> _showConfirmPaySheet(
  BuildContext context, {
  required Daret daret,
  required Contribution contribution,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ConfirmPaySheet(
      daret: daret,
      contribution: contribution,
    ),
  );
}

Future<bool?> _showReceivedSheet(
  BuildContext context, {
  required Daret daret,
  required Contribution contribution,
  required DaretMember? payer,
  required bool adminDirectConfirm,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ReceivedSheet(
      daret: daret,
      contribution: contribution,
      payer: payer,
      adminDirectConfirm: adminDirectConfirm,
    ),
  );
}

Future<void> _showPayoutShareSheet(
  BuildContext context, {
  required Daret daret,
  required DaretPeriod period,
  required DaretMember member,
  required int amount,
  required Color accent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ShareCardSheet(
      daret: daret,
      period: period,
      member: member,
      amount: amount,
      accent: accent,
    ),
  );
}

Future<bool?> _showCloseDaretSheet(
  BuildContext context, {
  required Daret daret,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CloseDaretSheet(daret: daret),
  );
}

class _ConfirmPaySheet extends StatelessWidget {
  const _ConfirmPaySheet({
    required this.daret,
    required this.contribution,
  });

  final Daret daret;
  final Contribution contribution;

  @override
  Widget build(BuildContext context) {
    return _ActionSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeroIcon(
            background: TantinColors.majorelleSoft,
            child: TnIcons.shield(size: 30, color: TantinColors.majorelle),
          ),
          const SizedBox(height: 14),
          Text(
            'Confirmer votre paiement',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: TantinColors.ink,
              fontSize: 22,
              letterSpacing: -0.44,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Vous confirmez avoir versé ',
              children: [
                TextSpan(
                  text: TantinFormat.fmtDH(contribution.amount),
                  style: const TextStyle(
                    color: TantinColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: ' au bénéficiaire de '),
                TextSpan(
                  text: daret.nom,
                  style: const TextStyle(
                    color: TantinColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TantinColors.inkMuted,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const _TrustNotice(
            text:
                "Tant'in ne traite pas d'argent. "
                'Le bénéficiaire confirmera la réception.',
          ),
          const SizedBox(height: 18),
          TnButton(
            full: true,
            variant: ButtonVariant.saffron,
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("J'ai payé ma part"),
          ),
          const SizedBox(height: 10),
          _CancelSheetButton(onPressed: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}

class _ReceivedSheet extends StatelessWidget {
  const _ReceivedSheet({
    required this.daret,
    required this.contribution,
    required this.payer,
    required this.adminDirectConfirm,
  });

  final Daret daret;
  final Contribution contribution;
  final DaretMember? payer;
  final bool adminDirectConfirm;

  @override
  Widget build(BuildContext context) {
    final payerName = payer?.prenom ?? 'ce membre';
    return _ActionSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeroIcon(
            background: TantinColors.success.withValues(alpha: 0.12),
            child: TnIcons.checkCircle(size: 31, color: TantinColors.success),
          ),
          const SizedBox(height: 14),
          Text(
            'Confirmer la réception',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: TantinColors.ink,
              fontSize: 22,
              letterSpacing: -0.44,
            ),
          ),
          const SizedBox(height: 8),
          Text.rich(
            TextSpan(
              text: 'Vous confirmez avoir reçu ',
              children: [
                TextSpan(
                  text: TantinFormat.fmtDH(contribution.amount),
                  style: const TextStyle(
                    color: TantinColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                TextSpan(text: ' de $payerName pour '),
                TextSpan(
                  text: daret.nom,
                  style: const TextStyle(
                    color: TantinColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TantinColors.inkMuted,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          _TrustNotice(
            text: adminDirectConfirm
                ? 'Validation admin : cette action confirme directement ce '
                      'paiement dans le suivi du daret.'
                : 'Cette confirmation sert uniquement au suivi de confiance. '
                      "Tant'in ne déplace jamais d'argent.",
          ),
          const SizedBox(height: 18),
          TnButton(
            full: true,
            icon: TnIcons.check(size: 18, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reçu'),
          ),
          const SizedBox(height: 10),
          _CancelSheetButton(onPressed: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}

class _PayoutTakeoverScreen extends StatelessWidget {
  const _PayoutTakeoverScreen({
    required this.daret,
    required this.period,
    required this.member,
    required this.amount,
    required this.accent,
    required this.onShare,
    required this.onContinue,
  });

  final Daret daret;
  final DaretPeriod period;
  final DaretMember member;
  final int amount;
  final Color accent;
  final VoidCallback onShare;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final deep = _shade(accent, -0.28);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: DecoratedBox(
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
                opacity: 0.35,
                child: TnArt.zelligeFaint(),
              ),
            ),
            Positioned(
              right: -30,
              top: 58,
              child: Opacity(
                opacity: 0.24,
                child: TnArt.starTile(
                  size: 142,
                  c1: Colors.white,
                  c3: Colors.white,
                ),
              ),
            ),
            const Positioned.fill(child: PayoutConfetti()),
            SafeArea(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 10, 18, 0),
                      child: _HeaderIconButton(
                        onPressed: onContinue,
                        child: TnIcons.close(size: 22, color: Colors.white),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: TantinColors.saffron,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: TantinColors.saffron.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: TnIcons.gift(
                              size: 48,
                              color: const Color(0xFF2A1B05),
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            "C'EST VOTRE TOUR !",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFFFCDFA6),
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.34,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Vous recevez',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 30,
                                  letterSpacing: -0.6,
                                ),
                          ),
                          const SizedBox(height: 12),
                          CountUp(
                            value: amount.toDouble(),
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontSize: 54,
                                  letterSpacing: -1.08,
                                  height: 1,
                                ),
                          ),
                          const SizedBox(height: 16),
                          Text.rich(
                            TextSpan(
                              text:
                                  'Félicitations ${member.prenom} ! '
                                  'La cagnotte de ',
                              children: [
                                TextSpan(
                                  text: daret.nom,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                TextSpan(
                                  text:
                                      ' vous revient '
                                      '${_periodMoment(daret)}.',
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xD1FFFFFF),
                              fontSize: 15,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 24 + bottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TnButton(
                          full: true,
                          variant: ButtonVariant.saffron,
                          icon: TnIcons.share(
                            size: 20,
                            color: const Color(0xFF2A1B05),
                          ),
                          onPressed: onShare,
                          child: const Text('Partager ma carte'),
                        ),
                        const SizedBox(height: 11),
                        _PayoutSecondaryButton(onPressed: onContinue),
                      ],
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

class _PayoutSecondaryButton extends StatelessWidget {
  const _PayoutSecondaryButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          'Continuer',
          style: TextStyle(
            color: Colors.white,
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ShareCardSheet extends StatefulWidget {
  const _ShareCardSheet({
    required this.daret,
    required this.period,
    required this.member,
    required this.amount,
    required this.accent,
  });

  final Daret daret;
  final DaretPeriod period;
  final DaretMember member;
  final int amount;
  final Color accent;

  @override
  State<_ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<_ShareCardSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _sharing = false;

  @override
  Widget build(BuildContext context) {
    return _ActionSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Votre carte',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: TantinColors.ink,
              fontSize: 22,
              letterSpacing: -0.44,
            ),
          ),
          const SizedBox(height: 14),
          RepaintBoundary(
            key: _cardKey,
            child: _PayoutShareCard(
              daret: widget.daret,
              period: widget.period,
              member: widget.member,
              amount: widget.amount,
              accent: widget.accent,
            ),
          ),
          const SizedBox(height: 16),
          TnButton(
            full: true,
            disabled: _sharing,
            icon: _sharing
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : TnIcons.send(size: 18, color: Colors.white),
            onPressed: _sharing ? null : _shareCard,
            child: Text(_sharing ? 'Préparation...' : 'Partager sur WhatsApp'),
          ),
        ],
      ),
    );
  }

  Future<void> _shareCard() async {
    if (_sharing) return;
    final pixelRatio = (View.of(context).devicePixelRatio * 2).clamp(2.0, 4.0);
    setState(() => _sharing = true);

    try {
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = _cardKey.currentContext?.findRenderObject();
      final boundary = renderObject is RenderRepaintBoundary
          ? renderObject
          : null;
      if (boundary == null) {
        throw StateError('Carte indisponible.');
      }

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final bytes = byteData?.buffer.asUint8List();
      if (bytes == null) {
        throw StateError('Image indisponible.');
      }

      if (!mounted) return;
      final box = context.findRenderObject();
      final origin = box is RenderBox
          ? box.localToGlobal(Offset.zero) & box.size
          : null;

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: 'image/png',
            ),
          ],
          fileNameOverrides: const ['tantin-tour-recu.png'],
          subject: "Tour reçu Tant'in",
          text:
              "Tour reçu sur Tant'in : "
              '${TantinFormat.fmtDH(widget.amount)} - ${widget.daret.nom}.',
          sharePositionOrigin: origin,
        ),
      );
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Partage impossible : $error')),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _sharing = false);
      }
    }
  }
}

class _PayoutShareCard extends StatelessWidget {
  const _PayoutShareCard({
    required this.daret,
    required this.period,
    required this.member,
    required this.amount,
    required this.accent,
  });

  final Daret daret;
  final DaretPeriod period;
  final DaretMember member;
  final int amount;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final deep = _shade(accent, -0.24);
    final periodDate = TantinDates.monthYear(period.scheduledDate);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, deep],
        ),
        borderRadius: BorderRadius.circular(22),
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
            Positioned(
              right: -20,
              top: -16,
              child: Opacity(
                opacity: 0.25,
                child: TnArt.starTile(
                  c1: Colors.white,
                  c3: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const BigWordmark(size: 22, light: true),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Avatar(data: _avatarData(member), size: 48),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tour reçu',
                              style: TextStyle(
                                color: Color(0xCCFFFFFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              member.prenom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    TantinFormat.fmtDH(amount),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontSize: 40,
                      letterSpacing: -0.8,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${daret.nom} · $periodDate',
                    style: const TextStyle(
                      color: Color(0xC7FFFFFF),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
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

class _CloseDaretSheet extends StatelessWidget {
  const _CloseDaretSheet({required this.daret});

  final Daret daret;

  @override
  Widget build(BuildContext context) {
    return _ActionSheetShell(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeroIcon(
            background: TantinColors.success.withValues(alpha: 0.12),
            child: TnIcons.checkCircle(size: 31, color: TantinColors.success),
          ),
          const SizedBox(height: 14),
          Text(
            'Clôturer le daret ?',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: TantinColors.ink,
              fontSize: 22,
              letterSpacing: -0.44,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous les tours de ${daret.nom} sont confirmés. '
            'Le daret passera dans Terminés et la clôture sera inscrite '
            "dans l'activité.",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TantinColors.inkMuted,
              fontSize: 14.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 14),
          const _TrustNotice(
            text:
                "Tant'in ne déplace jamais d'argent. "
                'Cette action termine seulement le suivi de confiance.',
          ),
          const SizedBox(height: 18),
          TnButton(
            full: true,
            icon: TnIcons.check(size: 18, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clôturer le daret'),
          ),
          const SizedBox(height: 10),
          _CancelSheetButton(onPressed: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
  }
}

class _ClotureThanksScreen extends StatelessWidget {
  const _ClotureThanksScreen({
    required this.daret,
    required this.members,
    required this.periods,
    required this.accent,
    required this.onBackToDarets,
  });

  final Daret daret;
  final List<DaretMember> members;
  final List<DaretPeriod> periods;
  final Color accent;
  final VoidCallback onBackToDarets;

  @override
  Widget build(BuildContext context) {
    final totalReceived = periods.isEmpty
        ? daret.cagnotteParPeriode * daret.periodesCount
        : periods.fold<int>(0, (sum, period) => sum + period.potAmount);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _HeaderIconButton(
                  onPressed: onBackToDarets,
                  child: TnIcons.chevL(size: 22, color: TantinColors.ink),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                children: [
                  Center(
                    child: TnArt.starTile(
                      size: 110,
                      c1: TantinColors.success,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Daret terminé',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: TantinColors.ink,
                      fontSize: 28,
                      letterSpacing: -0.56,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text.rich(
                    TextSpan(
                      text: 'Tout le monde a reçu son tour dans ',
                      children: [
                        TextSpan(
                          text: daret.nom,
                          style: const TextStyle(
                            color: TantinColors.ink,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(
                          text: '. Merci pour votre confiance !',
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: TantinColors.inkMuted,
                      fontSize: 15,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryTile(
                          label: 'Cagnotte totale',
                          value: TantinFormat.fmtDH(totalReceived),
                          accent: TantinColors.success,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: _SummaryTile(
                          label: 'Tours bouclés',
                          value: '${daret.periodesCount}',
                          accent: accent,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                    decoration: BoxDecoration(
                      color: TantinColors.ivorySurface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: TantinColors.hairline),
                      boxShadow: TantinShadows.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Membres (${members.length})',
                          style: const TextStyle(
                            color: TantinColors.inkMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AvatarStack(
                          avatars: members.map(_avatarData).toList(),
                          maxCount: 8,
                          size: 32,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(24, 12, 24, 20 + bottom),
              child: TnButton(
                full: true,
                size: ButtonSize.lg,
                onPressed: onBackToDarets,
                child: const Text('Retour aux darets'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TantinColors.hairline),
        boxShadow: TantinShadows.sm,
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              color: accent,
              fontSize: 21,
              letterSpacing: -0.42,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TantinColors.inkMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionSheetShell extends StatelessWidget {
  const _ActionSheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
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
              margin: const EdgeInsets.only(top: 4, bottom: 14),
              decoration: BoxDecoration(
                color: TantinColors.ivorySunken,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _SheetHeroIcon extends StatelessWidget {
  const _SheetHeroIcon({required this.background, required this.child});

  final Color background;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 64,
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: child,
      ),
    );
  }
}

class _TrustNotice extends StatelessWidget {
  const _TrustNotice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TantinColors.ivorySunken,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          TnIcons.info(size: 26, color: TantinColors.inkMuted),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: TantinColors.inkMuted,
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CancelSheetButton extends StatelessWidget {
  const _CancelSheetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: const Padding(
        padding: EdgeInsets.all(10),
        child: Text(
          'Annuler',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: TantinColors.inkMuted,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
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
  final VoidCallback? onHeaderAction;

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

  final VoidCallback? onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.52 : 1,
      child: Pressable(
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
    required this.busyKeys,
    required this.onDeclarePaid,
    required this.onConfirmReceived,
    required this.onSendNudge,
    required this.advanceBusy,
    required this.onAdvancePeriod,
    required this.closeBusy,
    required this.onCloseDaret,
  });

  final Daret daret;
  final DaretPeriod? currentPeriod;
  final Map<String, DaretMember> membersByUid;
  final List<Contribution> contributions;
  final String? currentUid;
  final bool isAdmin;
  final Color accent;
  final Set<String> busyKeys;
  final _ContributionAction onDeclarePaid;
  final _ContributionAction onConfirmReceived;
  final _ContributionAction onSendNudge;
  final bool advanceBusy;
  final VoidCallback onAdvancePeriod;
  final bool closeBusy;
  final VoidCallback onCloseDaret;

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
    final allIn =
        progress.totalCount > 0 && progress.paidCount >= progress.totalCount;
    final lastPeriod = currentPeriod!.index >= daret.periodesCount;
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
            isAdmin: isAdmin,
            progress: progress,
            busy:
                myContribution != null &&
                busyKeys.contains(
                  _contributionKey(
                    currentPeriod!.index,
                    myContribution.payerUid,
                  ),
                ),
            advanceBusy: advanceBusy,
            closeBusy: closeBusy,
            lastPeriod: lastPeriod,
            onDeclarePaid: myContribution == null
                ? null
                : () => onDeclarePaid(myContribution),
            onAdvancePeriod: onAdvancePeriod,
            onCloseDaret: onCloseDaret,
          ),
          const SizedBox(height: 18),
        ],
        _ProgressSummary(progress: progress),
        if (!iAmRecipient && isAdmin && allIn) ...[
          const SizedBox(height: 12),
          _AdvancePeriodBanner(
            busy: lastPeriod ? closeBusy : advanceBusy,
            lastPeriod: lastPeriod,
            onAdvancePeriod: onAdvancePeriod,
            onCloseDaret: onCloseDaret,
          ),
        ],
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
                  canConfirm:
                      (contributors[index].state == ContributionState.attente &&
                          (iAmRecipient || isAdmin)) ||
                      (isAdmin &&
                          {
                            ContributionState.apayer,
                            ContributionState.retard,
                          }.contains(contributors[index].state)),
                  canNudge: iAmRecipient || isAdmin,
                  writeBusy: busyKeys.contains(
                    _contributionKey(
                      currentPeriod!.index,
                      contributors[index].payerUid,
                    ),
                  ),
                  nudgeBusy: busyKeys.contains(
                    _nudgeKey(
                      currentPeriod!.index,
                      contributors[index].payerUid,
                    ),
                  ),
                  onDeclarePaid: () => onDeclarePaid(contributors[index]),
                  onConfirmReceived: () =>
                      onConfirmReceived(contributors[index]),
                  onSendNudge: () => onSendNudge(contributors[index]),
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
    required this.isAdmin,
    required this.progress,
    required this.busy,
    required this.advanceBusy,
    required this.closeBusy,
    required this.lastPeriod,
    required this.onDeclarePaid,
    required this.onAdvancePeriod,
    required this.onCloseDaret,
  });

  final Daret daret;
  final Contribution? contribution;
  final bool iAmRecipient;
  final bool isAdmin;
  final PeriodProgress progress;
  final bool busy;
  final bool advanceBusy;
  final bool closeBusy;
  final bool lastPeriod;
  final VoidCallback? onDeclarePaid;
  final VoidCallback onAdvancePeriod;
  final VoidCallback onCloseDaret;

  @override
  Widget build(BuildContext context) {
    if (iAmRecipient) {
      final allIn =
          progress.totalCount > 0 && progress.paidCount >= progress.totalCount;
      final actionBusy = lastPeriod ? closeBusy : advanceBusy;
      return _BannerShell(
        background: TantinColors.majorelleSoft,
        iconBg: TantinColors.majorelle,
        icon: TnIcons.gift(size: 22, color: Colors.white),
        title: allIn ? 'Tout est confirmé' : "C'est votre tour !",
        body: allIn
            ? (isAdmin
                  ? lastPeriod
                        ? 'Vous pouvez clôturer ce daret.'
                        : 'Vous pouvez passer au tour suivant.'
                  : 'La période peut être clôturée par l’admin.')
            : 'Confirmez les paiements reçus ci-dessous.',
        actionLabel: allIn && isAdmin
            ? lastPeriod
                  ? 'Clôturer'
                  : 'Tour suivant'
            : null,
        actionColor: TantinColors.majorelle,
        onAction: allIn && isAdmin && !actionBusy
            ? lastPeriod
                  ? onCloseDaret
                  : onAdvancePeriod
            : null,
        busy: actionBusy,
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
        onAction: busy ? null : onDeclarePaid,
        busy: busy,
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
    this.busy = false,
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
  final bool busy;

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
          if (actionLabel != null) ...[
            const SizedBox(width: 10),
            _TinyButton(
              label: actionLabel!,
              background: actionColor ?? TantinColors.majorelle,
              foreground: actionTextColor,
              onPressed: onAction,
              busy: busy,
            ),
          ],
        ],
      ),
    );
  }
}

class _AdvancePeriodBanner extends StatelessWidget {
  const _AdvancePeriodBanner({
    required this.busy,
    required this.lastPeriod,
    required this.onAdvancePeriod,
    required this.onCloseDaret,
  });

  final bool busy;
  final bool lastPeriod;
  final VoidCallback onAdvancePeriod;
  final VoidCallback onCloseDaret;

  @override
  Widget build(BuildContext context) {
    return _BannerShell(
      background: TantinColors.success.withValues(alpha: 0.1),
      iconBg: TantinColors.success.withValues(alpha: 0.12),
      icon: TnIcons.checkCircle(size: 22, color: TantinColors.success),
      title: 'Tous les paiements sont confirmés',
      body: lastPeriod
          ? 'Clôturez le daret pour le classer dans Terminés.'
          : 'Clôturez ce tour pour afficher la nouvelle période.',
      actionLabel: lastPeriod ? 'Clôturer' : 'Tour suivant',
      actionColor: TantinColors.success,
      onAction: busy
          ? null
          : lastPeriod
          ? onCloseDaret
          : onAdvancePeriod,
      busy: busy,
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
    required this.writeBusy,
    required this.nudgeBusy,
    required this.onDeclarePaid,
    required this.onConfirmReceived,
    required this.onSendNudge,
  });

  final Contribution contribution;
  final DaretMember? member;
  final bool isMe;
  final bool canConfirm;
  final bool canNudge;
  final bool writeBusy;
  final bool nudgeBusy;
  final VoidCallback onDeclarePaid;
  final VoidCallback onConfirmReceived;
  final VoidCallback onSendNudge;

  @override
  Widget build(BuildContext context) {
    final name = member?.name ?? contribution.payerUid;
    final firstName = member?.prenom ?? name;
    final state = contribution.state;
    final actions = <Widget>[];

    if (isMe &&
        (state == ContributionState.apayer ||
            state == ContributionState.retard)) {
      actions.add(
        _TinyButton(
          label: "J'ai payé",
          background: TantinColors.saffron,
          foreground: const Color(0xFF2A1B05),
          onPressed: writeBusy ? null : onDeclarePaid,
          busy: writeBusy,
        ),
      );
    } else if (canConfirm) {
      actions.add(
        _TinyButton(
          label: 'Reçu',
          icon: TnIcons.check(size: 15, color: Colors.white, strokeWidth: 2.6),
          background: TantinColors.success,
          foreground: Colors.white,
          onPressed: writeBusy ? null : onConfirmReceived,
          busy: writeBusy,
        ),
      );
    }

    if (!isMe &&
        canNudge &&
        (state == ContributionState.apayer ||
            state == ContributionState.retard)) {
      actions.add(
        _TinyButton(
          label: 'Relancer',
          icon: TnIcons.bell(size: 14, color: TantinColors.majorelleDeep),
          background: TantinColors.majorelleSoft,
          foreground: TantinColors.majorelleDeep,
          onPressed: nudgeBusy ? null : onSendNudge,
          busy: nudgeBusy,
        ),
      );
    } else if (state == ContributionState.attente && isMe) {
      actions.add(
        const Text(
          'En attente',
          style: TextStyle(
            color: TantinColors.saffronDeep,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
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
          if (actions.isNotEmpty) ...[
            const SizedBox(width: 10),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 6,
              runSpacing: 6,
              children: actions,
            ),
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
    this.busy = false,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.56 : 1,
      child: Pressable(
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
              if (busy) ...[
                SizedBox.square(
                  dimension: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: foreground,
                  ),
                ),
                const SizedBox(width: 6),
              ] else if (icon != null) ...[
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

String _contributionKey(int periodIndex, String payerUid) {
  return '$periodIndex:$payerUid';
}

String _nudgeKey(int periodIndex, String payerUid) {
  return 'nudge:${_contributionKey(periodIndex, payerUid)}';
}

String _advanceKey(String daretId) {
  return 'advance:$daretId';
}

String _closeDaretKey(String daretId) {
  return 'close:$daretId';
}

String _periodMoment(Daret daret) {
  return daret.frequence == DaretFrequency.mensuel
      ? 'ce mois-ci'
      : 'ce tour-ci';
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
