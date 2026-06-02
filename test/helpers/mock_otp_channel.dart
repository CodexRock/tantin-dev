import 'package:firebase_auth/firebase_auth.dart';
import 'package:tantin_flutter/features/auth/domain/otp_channel.dart';

class _FakeUserCredential implements UserCredential {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockOtpChannel implements OtpChannel {
  String? sentPhone;
  String? verifiedVerificationId;
  String? verifiedCode;

  bool shouldFailVerify = false;
  bool shouldFailSend = false;

  @override
  Future<void> sendCode(
    String phone, {
    required void Function(String verificationId, int? resendToken) codeSent,
    required void Function(FirebaseAuthException error) verificationFailed,
    required void Function(PhoneAuthCredential credential)
    verificationCompleted,
    required void Function(String verificationId) codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    sentPhone = phone;
    if (shouldFailSend) {
      verificationFailed(
        FirebaseAuthException(code: 'test', message: 'Mock send failure'),
      );
    } else {
      codeSent('mock-verification-id', 123);
    }
  }

  @override
  Future<UserCredential> verify(String verificationId, String smsCode) async {
    verifiedVerificationId = verificationId;
    verifiedCode = smsCode;

    if (shouldFailVerify) {
      throw FirebaseAuthException(code: 'test', message: 'Mock verify failure');
    }
    return _FakeUserCredential();
  }
}
