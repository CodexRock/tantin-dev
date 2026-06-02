import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tantin_flutter/core/firebase/firestore_helpers.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

abstract class UserFirestoreMapper {
  static AppUser fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw StateError(
        'Firestore document ${snapshot.reference.path} is empty',
      );
    }
    return AppUser(
      uid: snapshot.id,
      prenom: data['prenom'] as String,
      nom: data['nom'] as String,
      name: data['name'] as String,
      initials: data['initials'] as String,
      phone: data['phone'] as String,
      photoUrl: data['photoUrl'] as String?,
      avatarPalette: stringListFromFirestore(data['avatarPalette']),
      fcmTokens: stringListFromFirestore(data['fcmTokens']),
      settings: UserSettings.fromJson(
        mapFromFirestore(data['settings']),
      ),
      stats: UserStats.fromJson(
        mapFromFirestore(data['stats']),
      ),
      createdAt: dateTimeFromFirestore(data['createdAt']),
      updatedAt: dateTimeFromFirestore(data['updatedAt']),
    );
  }

  static Map<String, dynamic> toFirestore(AppUser user) {
    return <String, dynamic>{
      'prenom': user.prenom,
      'nom': user.nom,
      'name': user.name,
      'initials': user.initials,
      'phone': user.phone,
      'photoUrl': user.photoUrl,
      'avatarPalette': user.avatarPalette,
      'fcmTokens': user.fcmTokens,
      'settings': user.settings.toJson(),
      'stats': user.stats.toJson(),
      'createdAt': timestampFromDateTime(user.createdAt),
      'updatedAt': timestampFromDateTime(user.updatedAt),
    };
  }
}
