import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/auth/data/sms_otp_channel.dart';
import 'package:tantin_flutter/features/auth/domain/otp_channel.dart';

// Manual Riverpod 2 providers (no codegen; see DECISIONS D025).

final AutoDisposeProvider<OtpChannel> otpChannelProvider =
    Provider.autoDispose<OtpChannel>(
      (ref) => SmsOtpChannel(ref.watch(firebaseAuthProvider)),
    );

final AutoDisposeStreamProvider<User?> authStateChangesProvider =
    StreamProvider.autoDispose<User?>(
      (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
    );

final AutoDisposeStreamProvider<DocumentSnapshot<Map<String, dynamic>>?>
userProfileProvider =
    StreamProvider.autoDispose<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
      final user = ref.watch(authStateChangesProvider).value;
      if (user == null) return Stream.value(null);
      return ref
          .watch(firebaseFirestoreProvider)
          .collection('users')
          .doc(user.uid)
          .snapshots();
    });
