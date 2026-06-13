import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Wraps [FirebaseMessaging] token lifecycle and persists tokens on the signed
/// in user's document so the backend can target them. All Firestore writes here
/// touch only `fcmTokens` + `updatedAt`, which the security rules allow the
/// user to write on their own document.
class PushMessaging {
  const PushMessaging(this._messaging, this._firestore);

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  /// Token refresh stream — re-persist the new token whenever it rotates.
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  /// Requests notification permission and persists the current FCM token for
  /// [uid]. Failures (permission denied, no Play Services, offline) are
  /// swallowed so a missing push setup never blocks the app.
  Future<void> registerForUser(String uid) async {
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await saveToken(uid, token);
    }
  }

  Future<void> saveToken(String uid, String token) {
    return _firestore.collection('users').doc(uid).set(
      <String, dynamic>{
        'fcmTokens': FieldValue.arrayUnion(<String>[token]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Removes the current device token on sign-out so a shared device stops
  /// receiving pushes for the previous account.
  Future<void> unregisterForUser(String uid) async {
    final token = await _messaging.getToken();
    if (token != null && token.isNotEmpty) {
      await _firestore.collection('users').doc(uid).set(
        <String, dynamic>{
          'fcmTokens': FieldValue.arrayRemove(<String>[token]),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await _messaging.deleteToken();
  }
}
