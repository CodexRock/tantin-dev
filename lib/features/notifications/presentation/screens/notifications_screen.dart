import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/notifications/data/notification_providers.dart';
import 'package:tantin_flutter/features/notifications/domain/app_notification.dart';

/// Notifications — the bell destination. A simple chronological list; marking
/// read/unread is wired in a later sprint.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifs =
        ref.watch(notificationsProvider).valueOrNull ??
        const <AppNotification>[];
    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      appBar: AppBar(
        backgroundColor: TantinColors.ivoryBg,
        elevation: 0,
        leading: const BackButton(color: TantinColors.ink),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: TantinColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: notifs.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: EmptyBlock(
                  title: 'Aucune notification',
                  body: 'Vous êtes à jour.',
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                for (final n in notifs) _Row(notification: n),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.unread
              ? TantinColors.majorelleSoft
              : TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _icon(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    notification.text,
                    style: const TextStyle(
                      fontSize: 14.5,
                      color: TantinColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    TantinDates.relative(notification.createdAt),
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: TantinColors.inkMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            if (notification.unread)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: const BoxDecoration(
                  color: TantinColors.majorelle,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _icon() {
    final Widget glyph;
    switch (notification.icon) {
      case 'clock':
        glyph = TnIcons.clock(size: 19, color: TantinColors.terracotta);
      case 'user':
        glyph = TnIcons.user(size: 19, color: TantinColors.majorelle);
      case 'gift':
        glyph = TnIcons.gift(size: 19, color: TantinColors.saffronDeep);
      default:
        glyph = TnIcons.bell(size: 19, color: TantinColors.majorelle);
    }
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: TantinColors.ivoryBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: glyph,
    );
  }
}
