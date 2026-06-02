import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tantin_flutter/core/firebase/firestore_helpers.dart';
import 'package:tantin_flutter/features/notifications/domain/app_notification.dart';

abstract class NotificationFirestoreMapper {
  static AppNotification fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Firestore document ${snapshot.reference.path} is empty',
      );
    }
    final createdAt = dateTimeFromFirestore(data['createdAt']);
    if (createdAt == null) {
      throw StateError('Notification createdAt must be a Timestamp');
    }
    return AppNotification(
      id: snapshot.id,
      icon: data['icon'] as String,
      text: data['text'] as String,
      action: data['action'] as String?,
      daretId: data['daretId'] as String?,
      unread: data['unread'] as bool,
      createdAt: createdAt,
    );
  }

  static Map<String, dynamic> toFirestore(AppNotification notification) {
    return <String, dynamic>{
      'icon': notification.icon,
      'text': notification.text,
      'action': notification.action,
      'daretId': notification.daretId,
      'unread': notification.unread,
      'createdAt': timestampFromDateTime(notification.createdAt),
    };
  }
}
