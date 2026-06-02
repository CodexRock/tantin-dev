import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/auth/data/sms_otp_channel.dart';
import 'package:tantin_flutter/features/auth/domain/otp_channel.dart';

part 'auth_providers.g.dart';

@riverpod
OtpChannel otpChannel(Ref ref) {
  final auth = ref.watch(firebaseAuthProvider);
  return SmsOtpChannel(auth);
}

@riverpod
Stream<User?> authStateChanges(Ref ref) {
  return ref.watch(firebaseAuthProvider).authStateChanges();
}

@riverpod
Stream<DocumentSnapshot<Map<String, dynamic>>?> userProfile(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(null);
  return ref
      .watch(firebaseFirestoreProvider)
      .collection('users')
      .doc(user.uid)
      .snapshots();
}
