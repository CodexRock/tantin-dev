import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tantin_flutter/features/activity/data/activity_firestore_mapper.dart';
import 'package:tantin_flutter/features/activity/domain/activity_event.dart';

class ActivityRepository {
  const ActivityRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<ActivityEvent>> watchActivity(String daretId) {
    return _firestore
        .collection('darets')
        .doc(daretId)
        .collection('activity')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(ActivityFirestoreMapper.fromSnapshot)
              .toList(growable: false);
        });
  }
}
