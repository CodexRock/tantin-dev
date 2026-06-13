import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/notifications/data/notification_providers.dart';
import 'package:tantin_flutter/features/notifications/domain/app_notification.dart';

/// Notifications — the bell destination. A chronological list; tapping a row
/// marks it read and opens the related daret, and « Tout lire » clears the
/// unread badge.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateChangesProvider).valueOrNull?.uid;
    final notifs =
        ref.watch(notificationsProvider).valueOrNull ??
        const <AppNotification>[];
    final hasUnread = notifs.any((n) => n.unread);
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
        actions: [
          if (hasUnread && uid != null)
            TextButton(
              onPressed: () => _markAllRead(ref, uid, notifs),
              child: const Text(
                'Tout lire',
                style: TextStyle(
                  color: TantinColors.majorelle,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
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
                for (final n in notifs)
                  _Row(
                    notification: n,
                    onTap: () => _open(context, ref, uid, n),
                  ),
              ],
            ),
    );
  }

  void _markAllRead(
    WidgetRef ref,
    String uid,
    List<AppNotification> notifs,
  ) {
    final unreadIds = notifs
        .where((n) => n.unread)
        .map((n) => n.id)
        .toList(growable: false);
    unawaited(
      ref
          .read(notificationRepositoryProvider)
          .markAllRead(
            uid: uid,
            unreadIds: unreadIds,
          ),
    );
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    String? uid,
    AppNotification notification,
  ) {
    if (uid != null && notification.unread) {
      unawaited(
        ref
            .read(notificationRepositoryProvider)
            .setUnread(
              uid: uid,
              notificationId: notification.id,
              unread: false,
            ),
      );
    }
    final daretId = notification.daretId;
    if (daretId != null && daretId.isNotEmpty) {
      unawaited(context.push('/daret/$daretId'));
    }
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Pressable(
        onPressed: onTap,
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
