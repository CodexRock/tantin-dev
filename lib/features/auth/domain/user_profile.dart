import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  UserProfile({
    required this.uid,
    required this.firstName,
    required this.phone,
    this.lastName,
    this.photoUrl,
    this.createdAt,
  });

  factory UserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      throw Exception('Document data is null');
    }

    return UserProfile(
      uid: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String?,
      photoUrl: data['photoUrl'] as String?,
      phone: data['phone'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  final String uid;
  final String firstName;
  final String? lastName;
  final String? photoUrl;
  final String phone;
  final DateTime? createdAt;
}
