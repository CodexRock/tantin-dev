import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/router/router.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/darets/data/daret_callable_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_callable_repository.dart';

class JoinDaretScreen extends ConsumerStatefulWidget {
  const JoinDaretScreen({super.key});

  @override
  ConsumerState<JoinDaretScreen> createState() => _JoinDaretScreenState();
}

class _JoinDaretScreenState extends ConsumerState<JoinDaretScreen> {
  var _code = '';
  DaretPreview? _preview;
  String? _error;
  bool _loading = false;
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
          children: [
            Row(
              children: [
                _IconButton(
                  icon: TnIcons.chevL(size: 21, color: TantinColors.ink),
                  onPressed: () => context.pop(),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: TantinColors.saffron.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(18),
              ),
              child: TnIcons.link(size: 28, color: TantinColors.saffronDeep),
            ),
            const SizedBox(height: 16),
            Text(
              'Rejoindre un daret',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 27,
                letterSpacing: -0.81,
                color: TantinColors.ink,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Entrez le code d’invitation reçu par un proche.',
              style: TextStyle(
                fontSize: 15,
                color: TantinColors.inkMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              autofocus: true,
              textAlign: TextAlign.center,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9-]')),
              ],
              onChanged: (value) {
                setState(() {
                  _code = value.toUpperCase().trim();
                  _preview = null;
                  _error = null;
                });
              },
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 26,
                letterSpacing: 3,
                color: TantinColors.ink,
              ),
              decoration: InputDecoration(
                hintText: 'TANTIN-7K2P',
                filled: true,
                fillColor: TantinColors.ivorySurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: TantinColors.hairline,
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: TantinColors.majorelle,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TnButton(
              full: true,
              disabled: _loading || _code.length < 8,
              onPressed: _previewCode,
              iconRight: TnIcons.search(size: 18),
              child: Text(_loading ? 'Vérification…' : 'Prévisualiser'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: TantinColors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            if (_preview != null) ...[
              const SizedBox(height: 22),
              _PreviewCard(
                preview: _preview!,
                joining: _joining,
                onJoin: _join,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _previewCode() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final preview = await ref
          .read(daretCallableRepositoryProvider)
          .previewDaret(_code);
      setState(() {
        _preview = preview;
        _loading = false;
      });
    } on Object catch (error) {
      setState(() {
        _error = 'Code invalide, expiré ou daret complet : $error';
        _loading = false;
      });
    }
  }

  Future<void> _join() async {
    setState(() {
      _joining = true;
      _error = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      final daretId = await ref
          .read(daretCallableRepositoryProvider)
          .joinDaret(_code);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Demande envoyée à l’administrateur')),
      );
      context.go('${AppRoutes.approval}/$daretId');
    } on Object catch (error) {
      setState(() {
        _error = 'Impossible de rejoindre : $error';
        _joining = false;
      });
    }
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({
    required this.preview,
    required this.joining,
    required this.onJoin,
  });

  final DaretPreview preview;
  final bool joining;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(preview.accent);
    final invitesLabel = preview.pendingInvitesCount == 1
        ? '1 place en attente d’invitation'
        : '${preview.pendingInvitesCount} places en attente d’invitation';
    return TnCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    preview.cover,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preview.nom,
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontSize: 19, color: TantinColors.ink),
                      ),
                      Text(
                        '${TantinFormat.fmtDH(preview.montant)} · '
                        '${preview.frequence} · '
                        '${preview.periodesCount} tours',
                        style: const TextStyle(
                          color: TantinColors.inkMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: TantinColors.hairline),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Membres',
                      style: TextStyle(
                        color: TantinColors.inkMuted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${preview.membersCount}/${preview.periodesCount}',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                if (preview.pendingInvitesCount > 0) ...[
                  const SizedBox(height: 6),
                  Text(
                    invitesLabel,
                    style: const TextStyle(
                      color: TantinColors.saffronDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TnButton(
                  full: true,
                  variant: ButtonVariant.saffron,
                  disabled: joining,
                  onPressed: onJoin,
                  child: Text(joining ? 'Envoi…' : 'Demander à rejoindre'),
                ),
              ],
            ),
          ),
        ],
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
