import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tantin_flutter/features/profile/data/user_firestore_mapper.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

class UserRepository {
  const UserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<AppUser?> watchUser(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((snapshot) {
      return snapshot.exists
          ? UserFirestoreMapper.fromSnapshot(snapshot)
          : null;
    });
  }

  Future<void> updateSettings(String uid, UserSettings settings) {
    return _firestore.collection('users').doc(uid).update({
      'settings': settings.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
