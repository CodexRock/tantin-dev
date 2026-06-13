import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/profile/data/user_providers.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

/// Shared chrome for the Profil settings bottom sheets.
Future<void> _showSheet(
  BuildContext context, {
  required String title,
  required Widget child,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        20 +
            MediaQuery.viewInsetsOf(sheetContext).bottom +
            MediaQuery.paddingOf(sheetContext).bottom,
      ),
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
            title,
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 22,
              letterSpacing: -0.44,
              color: TantinColors.ink,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

/// Notification preferences — three switches persisted to `users/{uid}.settings`.
Future<void> showNotifPrefsSheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Notifications',
    child: const _NotifPrefsBody(),
  );
}

/// Standard daret defaults (échéance day + grace days) shared across the user's
/// darets — persisted to `users/{uid}.settings`.
Future<void> showDaretDefaultsSheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Réglages des darets',
    child: const _DaretDefaultsBody(),
  );
}

Future<void> showLanguageSheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Langue',
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectedRow(label: 'Français'),
        SizedBox(height: 12),
        Text(
          "D'autres langues arriveront dans une prochaine version.",
          style: TextStyle(
            fontSize: 14,
            height: 1.4,
            color: TantinColors.inkMuted,
          ),
        ),
      ],
    ),
  );
}

Future<void> showHelpSheet(BuildContext context) {
  return _showSheet(
    context,
    title: 'Aide & support',
    child: const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Tant'in suit vos darets en toute confiance — l'app ne traite "
          "jamais d'argent. Les paiements se font entre vous, comme "
          "d'habitude.",
          style: TextStyle(
            fontSize: 14.5,
            height: 1.45,
            color: TantinColors.ink,
          ),
        ),
        SizedBox(height: 14),
        Text(
          'Une question ? Écrivez-nous à support@tantin.app',
          style: TextStyle(
            fontSize: 14,
            color: TantinColors.inkMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SelectedRow extends StatelessWidget {
  const _SelectedRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TantinColors.majorelleSoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TantinColors.hairline),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: TantinColors.ink,
              ),
            ),
          ),
          TnIcons.check(size: 20, color: TantinColors.majorelle),
        ],
      ),
    );
  }
}

class _NotifPrefsBody extends ConsumerWidget {
  const _NotifPrefsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final prefs = user?.settings.notifPrefs ?? const NotificationPreferences();

    void save(NotificationPreferences next) {
      if (user == null) return;
      unawaited(
        ref
            .read(userRepositoryProvider)
            .updateSettings(
              user.uid,
              user.settings.copyWith(notifPrefs: next),
            ),
      );
    }

    return Column(
      children: [
        _SwitchRow(
          label: 'Paiements confirmés',
          value: prefs.contributions,
          onChanged: (v) => save(prefs.copyWith(contributions: v)),
        ),
        _SwitchRow(
          label: 'Rappels d’échéance',
          value: prefs.reminders,
          onChanged: (v) => save(prefs.copyWith(reminders: v)),
        ),
        _SwitchRow(
          label: "C'est votre tour",
          value: prefs.turns,
          onChanged: (v) => save(prefs.copyWith(turns: v)),
        ),
      ],
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
        decoration: BoxDecoration(
          color: TantinColors.ivoryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: TantinColors.ink,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: TantinColors.majorelle,
            ),
          ],
        ),
      ),
    );
  }
}

class _DaretDefaultsBody extends ConsumerWidget {
  const _DaretDefaultsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentAppUserProvider).valueOrNull;
    final settings = user?.settings ?? const UserSettings();

    void save(UserSettings next) {
      if (user == null) return;
      unawaited(
        ref.read(userRepositoryProvider).updateSettings(user.uid, next),
      );
    }

    return Column(
      children: [
        _StepperRow(
          label: 'Jour d’échéance',
          value: settings.defaultEcheanceDay,
          min: 1,
          max: 28,
          suffix: 'du mois',
          onChanged: (v) => save(settings.copyWith(defaultEcheanceDay: v)),
        ),
        _StepperRow(
          label: 'Délai de grâce',
          value: settings.graceDays,
          min: 0,
          max: 15,
          suffix: 'jours',
          onChanged: (v) => save(settings.copyWith(graceDays: v)),
        ),
        const SizedBox(height: 6),
        const Text(
          'Ces valeurs servent de réglages par défaut pour vos nouveaux '
          'darets.',
          style: TextStyle(
            fontSize: 13,
            height: 1.4,
            color: TantinColors.inkMuted,
          ),
        ),
      ],
    );
  }
}

class _StepperRow extends StatelessWidget {
  const _StepperRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.suffix,
    required this.onChanged,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final String suffix;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
        decoration: BoxDecoration(
          color: TantinColors.ivoryBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: TantinColors.ink,
                    ),
                  ),
                  Text(
                    '$value $suffix',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: TantinColors.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            _StepButton(
              icon: TnIcons.minus(size: 18, color: TantinColors.majorelle),
              onPressed: value > min ? () => onChanged(value - 1) : null,
            ),
            const SizedBox(width: 8),
            _StepButton(
              icon: TnIcons.plus(size: 18, color: TantinColors.majorelle),
              onPressed: value < max ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onPressed});

  final Widget icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.35 : 1,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: TantinColors.majorelleSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: icon,
        ),
      ),
    );
  }
}
