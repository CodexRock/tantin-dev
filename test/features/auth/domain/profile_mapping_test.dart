import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/features/auth/domain/user_profile.dart';

// ignore: subtype_of_sealed_class, Firestore DocumentSnapshot is sealed but we need a fake for testing
class FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  FakeDocumentSnapshot(this._id, this._data, {bool exists = true})
    : _exists = exists;
  final String _id;
  final Map<String, dynamic>? _data;
  final bool _exists;

  @override
  String get id => _id;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => _exists;

  @override
  dynamic get(Object field) => _data?[field];

  @override
  dynamic operator [](Object field) => _data?[field];

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  DocumentReference<Map<String, dynamic>> get reference =>
      throw UnimplementedError();
}

void main() {
  group('UserProfile', () {
    test('fromFirestore parses valid data', () {
      final timestamp = Timestamp.now();
      final doc = FakeDocumentSnapshot('user123', {
        'prenom': 'John',
        'nom': 'Doe',
        'photoUrl': 'https://example.com/photo.jpg',
        'phone': '+212600000000',
        'createdAt': timestamp,
      });

      final profile = UserProfile.fromFirestore(doc);

      expect(profile.uid, 'user123');
      expect(profile.firstName, 'John');
      expect(profile.lastName, 'Doe');
      expect(profile.photoUrl, 'https://example.com/photo.jpg');
      expect(profile.phone, '+212600000000');
      expect(profile.createdAt, timestamp.toDate());
    });

    test('fromFirestore provides defaults for missing fields', () {
      final doc = FakeDocumentSnapshot('user456', {});

      final profile = UserProfile.fromFirestore(doc);

      expect(profile.uid, 'user456');
      expect(profile.firstName, '');
      expect(profile.lastName, isNull);
      expect(profile.photoUrl, isNull);
      expect(profile.phone, '');
      expect(profile.createdAt, isNull);
    });

    test('fromFirestore throws if data is null', () {
      final doc = FakeDocumentSnapshot('user789', null);

      expect(() => UserProfile.fromFirestore(doc), throwsException);
    });
  });
}
