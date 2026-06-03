import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/notifications/data/notification_repository.dart';
import 'package:tantin_flutter/features/notifications/domain/app_notification.dart';

// Manual Riverpod 2 providers (no codegen; see DECISIONS D025).

final AutoDisposeProvider<NotificationRepository>
notificationRepositoryProvider = Provider.autoDispose<NotificationRepository>(
  (ref) => NotificationRepository(ref.watch(firebaseFirestoreProvider)),
);

final AutoDisposeStreamProvider<List<AppNotification>> notificationsProvider =
    StreamProvider.autoDispose<List<AppNotification>>((ref) {
      final user = ref.watch(authStateChangesProvider).value;
      if (user == null) return Stream.value(const []);
      return ref
          .watch(notificationRepositoryProvider)
          .watchNotifications(user.uid);
    });
