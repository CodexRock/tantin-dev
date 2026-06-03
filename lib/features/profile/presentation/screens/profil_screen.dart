import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/profile/data/user_providers.dart';

/// Profil — identity header, lifetime stats, settings list, and logout.
class ProfilScreen extends ConsumerWidget {
  const ProfilScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final palette = user?.avatarPalette ?? const <String>[];
    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.only(bottom: 120),
          children: [
            const ScreenHeader(title: 'Profil'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TantinColors.ivorySurface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: TantinColors.hairline),
                  boxShadow: TantinShadows.md,
                ),
                child: Row(
                  children: [
                    Avatar(
                      data: AvatarData(
                        initials: user?.initials ?? '',
                        bgColor: palette.isNotEmpty
                            ? hexToColor(palette.first)
                            : TantinColors.majorelle,
                      ),
                      size: 60,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            user?.name ?? '',
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontSize: 21,
                                  letterSpacing: -0.42,
                                  color: TantinColors.ink,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.phone ?? '',
                            style: const TextStyle(
                              fontSize: 14,
                              color: TantinColors.inkMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Darets actifs',
                      value: '${user?.stats.daretsActifs ?? 0}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Reçu à vie',
                      value: TantinFormat.fmtDH(user?.stats.totalRecuVie ?? 0),
                    ),
                  ),
                ],
              ),
            ),
            const _SettingsTile(icon: 'settings', label: 'Réglages des darets'),
            const _SettingsTile(icon: 'globe', label: 'Langue · Français'),
            const _SettingsTile(icon: 'bell', label: 'Notifications'),
            const _SettingsTile(icon: 'help', label: 'Aide & support'),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TnButton(
                variant: ButtonVariant.danger,
                full: true,
                onPressed: () => FirebaseAuth.instance.signOut(),
                child: const Text('Se déconnecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Text(
            value,
            style: const TextStyle(
              fontFamily: 'Fraunces',
              fontSize: 22,
              letterSpacing: -0.44,
              color: TantinColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: TantinColors.inkMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({required this.icon, required this.label});

  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: Row(
          children: [
            _icon(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: TantinColors.ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TnIcons.chevR(size: 18, color: TantinColors.inkMuted),
          ],
        ),
      ),
    );
  }

  Widget _icon() {
    switch (icon) {
      case 'globe':
        return TnIcons.globe(size: 20, color: TantinColors.majorelle);
      case 'bell':
        return TnIcons.bell(size: 20, color: TantinColors.majorelle);
      case 'help':
        return TnIcons.help(size: 20, color: TantinColors.majorelle);
      case 'settings':
      default:
        return TnIcons.settings(size: 20, color: TantinColors.majorelle);
    }
  }
}
