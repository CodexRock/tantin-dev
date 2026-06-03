import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_callable_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

class ApprovalScreen extends ConsumerWidget {
  const ApprovalScreen({
    required this.daretId,
    super.key,
    this.inviteCode,
  });

  final String daretId;
  final String? inviteCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daretAsync = ref.watch(daretProvider(daretId));
    final members =
        ref.watch(daretMembersProvider(daretId)).valueOrNull ??
        const <DaretMember>[];
    final periods =
        ref.watch(periodsProvider(daretId)).valueOrNull ??
        const <DaretPeriod>[];
    final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        child: daretAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(child: Text('$error')),
          data: (daret) {
            if (daret == null) {
              return const Center(child: Text('Daret introuvable'));
            }
            DaretMember? currentMember;
            for (final member in members) {
              if (member.uid == uid) {
                currentMember = member;
                break;
              }
            }
            final code = inviteCode ?? daret.inviteCode;
            final approved = members
                .where(
                  (member) => member.approvalStatus == ApprovalStatus.approved,
                )
                .length;
            final progress = members.isEmpty ? 0.0 : approved / members.length;

            return Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(22, 12, 22, 110),
                  children: [
                    Row(
                      children: [
                        _IconButton(
                          icon: TnIcons.chevL(
                            size: 21,
                            color: TantinColors.ink,
                          ),
                          onPressed: () => context.go('/darets'),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ApprovalHeader(daret: daret),
                    const SizedBox(height: 18),
                    _ProgressCard(
                      approved: approved,
                      total: members.length,
                      progress: progress,
                    ),
                    if (code != null) ...[
                      const SizedBox(height: 18),
                      _InviteCard(code: code, daret: daret),
                    ],
                    const SizedBox(height: 18),
                    const _Label('Membres'),
                    for (final member in members)
                      _ApprovalMemberRow(
                        member: member,
                        current: member.uid == uid,
                      ),
                    const SizedBox(height: 18),
                    const _Label('Ordre & calendrier'),
                    TnCard(
                      child: Column(
                        children: [
                          for (var i = 0; i < periods.length; i += 1)
                            _PeriodReviewRow(
                              period: periods[i],
                              members: members,
                              last: i == periods.length - 1,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _ApprovalFooter(
                    daret: daret,
                    currentMember: currentMember,
                    onApprove: () => _approve(context, ref),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _approve(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(daretCallableRepositoryProvider).approveDaret(daretId);
      messenger.showSnackBar(
        const SnackBar(content: Text('Approbation enregistrée')),
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Approbation impossible : $error')),
      );
    }
  }
}

class _ApprovalHeader extends StatelessWidget {
  const _ApprovalHeader({required this.daret});

  final Daret daret;

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(daret.accent);
    return Column(
      children: [
        Container(
          width: 70,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(daret.cover, style: const TextStyle(fontSize: 36)),
        ),
        const SizedBox(height: 12),
        Text(
          daret.nom,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
            fontSize: 24,
            color: TantinColors.ink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          daret.statut == DaretStatus.actif
              ? 'Daret démarré'
              : 'En attente d’approbation des membres',
          textAlign: TextAlign.center,
          style: const TextStyle(color: TantinColors.inkMuted),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.approved,
    required this.total,
    required this.progress,
  });

  final int approved;
  final int total;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return TnCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Progression',
                  style: TextStyle(
                    color: TantinColors.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  '$approved/$total approuvé',
                  style: const TextStyle(
                    color: TantinColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 8,
                value: progress,
                color: TantinColors.success,
                backgroundColor: TantinColors.ivorySunken,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteCard extends StatelessWidget {
  const _InviteCard({required this.code, required this.daret});

  final String code;
  final Daret daret;

  @override
  Widget build(BuildContext context) {
    return TnCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                TnIcons.qr(size: 20, color: TantinColors.majorelle),
                const SizedBox(width: 8),
                const Text(
                  'Code d’invitation',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DecoratedBox(
              decoration: BoxDecoration(
                color: TantinColors.ivorySunken,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Text(
                  code,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 24,
                    letterSpacing: 2.6,
                    color: TantinColors.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TnButton(
                    variant: ButtonVariant.ghost,
                    icon: TnIcons.copy(size: 18),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Code copié')),
                        );
                      }
                    },
                    child: const Text('Copier'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TnButton(
                    variant: ButtonVariant.saffron,
                    icon: TnIcons.share(size: 18),
                    onPressed: () => _share(context),
                    child: const Text('Partager'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    final text =
        'Rejoins "${daret.nom}" sur Tant’in avec le code $code. '
        'Tu pourras vérifier le daret et approuver l’ordre avant démarrage.';
    return SharePlus.instance.share(
      ShareParams(
        text: text,
        subject: 'Invitation Tant’in',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

class _ApprovalMemberRow extends StatelessWidget {
  const _ApprovalMemberRow({required this.member, required this.current});

  final DaretMember member;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final approved = member.approvalStatus == ApprovalStatus.approved;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: TantinColors.hairline),
      ),
      child: Row(
        children: [
          Avatar(
            data: AvatarData(
              initials: member.initials,
              bgColor: member.avatarPalette.isEmpty
                  ? TantinColors.majorelle
                  : hexToColor(member.avatarPalette.first),
            ),
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${member.name}${current ? ' (vous)' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          if (approved)
            Row(
              children: [
                TnIcons.checkCircle(size: 17, color: TantinColors.success),
                const SizedBox(width: 5),
                const Text(
                  'Approuvé',
                  style: TextStyle(
                    color: TantinColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            )
          else
            const Text(
              'En attente',
              style: TextStyle(
                color: TantinColors.saffronDeep,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _PeriodReviewRow extends StatelessWidget {
  const _PeriodReviewRow({
    required this.period,
    required this.members,
    required this.last,
  });

  final DaretPeriod period;
  final List<DaretMember> members;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final recipients = period.recipientUids
        .map((uid) {
          return members.firstWhere(
            (member) => member.uid == uid,
            orElse: () => DaretMember(
              uid: uid,
              role: MemberRole.member,
              approvalStatus: ApprovalStatus.pending,
              name: 'Invitation',
              prenom: 'Invitation',
              initials: 'IN',
              avatarPalette: const ['#F5A623', '#FBEFD6'],
            ),
          );
        })
        .toList(growable: false);
    final avatars = recipients
        .map(
          (member) => AvatarData(
            initials: member.initials,
            bgColor: member.avatarPalette.isEmpty
                ? TantinColors.majorelle
                : hexToColor(member.avatarPalette.first),
          ),
        )
        .toList(growable: false);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : const BorderSide(color: TantinColors.hairline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              child: Text(
                '${period.index}',
                style: const TextStyle(
                  color: TantinColors.majorelle,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              width: 74,
              child: Text(
                TantinDates.dayMonth(period.scheduledDate),
                style: const TextStyle(
                  fontSize: 12,
                  color: TantinColors.inkMuted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AvatarStack(avatars: avatars, size: 26, maxCount: 3),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                recipients.map((member) => member.prenom).join(', '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (recipients.length > 1)
              const Text(
                'GROUPE',
                style: TextStyle(
                  color: TantinColors.terracotta,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ApprovalFooter extends StatelessWidget {
  const _ApprovalFooter({
    required this.daret,
    required this.currentMember,
    required this.onApprove,
  });

  final Daret daret;
  final DaretMember? currentMember;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final approved =
        currentMember?.approvalStatus == ApprovalStatus.approved ||
        daret.statut == DaretStatus.actif;
    final label = daret.statut == DaretStatus.actif
        ? 'Daret démarré'
        : approved
        ? 'Vous avez approuvé'
        : 'J’approuve';
    return Container(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 18 + bottom),
      decoration: const BoxDecoration(
        color: TantinColors.ivorySurface,
        border: Border(top: BorderSide(color: TantinColors.hairline)),
      ),
      child: TnButton(
        full: true,
        size: ButtonSize.lg,
        disabled: approved || currentMember == null,
        onPressed: approved ? null : onApprove,
        child: Text(label),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onPressed});

  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: icon,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12.5,
          color: TantinColors.inkMuted,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
