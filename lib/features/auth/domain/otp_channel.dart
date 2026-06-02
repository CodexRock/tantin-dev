import 'package:firebase_auth/firebase_auth.dart';

abstract class OtpChannel {
  Future<void> sendCode(
    String phone, {
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(FirebaseAuthException e) verificationFailed,
    required void Function(PhoneAuthCredential credential)
    verificationCompleted,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  });

  Future<UserCredential> verify(String verificationId, String smsCode);
}
