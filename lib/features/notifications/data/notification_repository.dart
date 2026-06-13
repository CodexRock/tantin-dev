import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tantin_flutter/features/notifications/data/notification_firestore_mapper.dart';
import 'package:tantin_flutter/features/notifications/domain/app_notification.dart';

class NotificationRepository {
  const NotificationRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<AppNotification>> watchNotifications(String uid) {
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(NotificationFirestoreMapper.fromSnapshot)
              .toList(growable: false);
        });
  }

  Future<void> setUnread({
    required String uid,
    required String notificationId,
    required bool unread,
  }) {
    return _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items')
        .doc(notificationId)
        .update({'unread': unread});
  }

  /// Marks every currently-unread notification as read in a single batch so the
  /// Accueil bell badge clears. Only the `unread` field is touched, which the
  /// security rules allow the owner to write.
  Future<void> markAllRead({
    required String uid,
    required Iterable<String> unreadIds,
  }) async {
    final ids = unreadIds.toList(growable: false);
    if (ids.isEmpty) return;
    final batch = _firestore.batch();
    final items = _firestore
        .collection('notifications')
        .doc(uid)
        .collection('items');
    for (final id in ids) {
      batch.update(items.doc(id), {'unread': false});
    }
    await batch.commit();
  }
}
