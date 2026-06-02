import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tantin_flutter/core/firebase/firestore_helpers.dart';
import 'package:tantin_flutter/features/activity/domain/activity_event.dart';

abstract class ActivityFirestoreMapper {
  static ActivityEvent fromSnapshot(
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
      throw StateError('Activity createdAt must be a Timestamp');
    }
    return ActivityEvent(
      id: snapshot.id,
      type: ActivityType.values.firstWhere(
        (item) => item.firestoreValue == data['type'],
      ),
      actorUid: data['actorUid'] as String,
      text: data['text'] as String,
      amount: data['amount'] as int?,
      periodIndex: data['periodIndex'] as int?,
      createdAt: createdAt,
    );
  }

  static Map<String, dynamic> toFirestore(ActivityEvent event) {
    return <String, dynamic>{
      'type': event.type.firestoreValue,
      'actorUid': event.actorUid,
      'text': event.text,
      'amount': event.amount,
      'periodIndex': event.periodIndex,
      'createdAt': timestampFromDateTime(event.createdAt),
    };
  }
}
