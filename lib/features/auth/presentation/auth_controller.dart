import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';

part 'auth_controller.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> sendCode(
    String phone, {
    required void Function(String verificationId) onCodeSent,
    required void Function(FirebaseAuthException) onError,
  }) async {
    state = const AsyncLoading();
    try {
      final channel = ref.read(otpChannelProvider);
      await channel.sendCode(
        phone,
        codeSent: (verificationId, resendToken) {
          state = const AsyncData(null);
          onCodeSent(verificationId);
        },
        verificationFailed: (e) {
          state = AsyncError(e, StackTrace.current);
          onError(e);
        },
        verificationCompleted: (credential) async {
          try {
            await FirebaseAuth.instance.signInWithCredential(credential);
            state = const AsyncData(null);
          } on FirebaseAuthException catch (e, st) {
            state = AsyncError(e, st);
            onError(e);
          } on Exception catch (e, st) {
            state = AsyncError(e, st);
            onError(
              FirebaseAuthException(
                code: 'auto-verify-failed',
                message: e.toString(),
              ),
            );
          }
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } on FirebaseAuthException catch (e, st) {
      state = AsyncError(e, st);
      onError(e);
    } on Object catch (e, st) {
      state = AsyncError(e, st);
      onError(
        FirebaseAuthException(
          code: 'auto-verify-failed',
          message: e.toString(),
        ),
      );
    }
  }

  Future<void> verifyCode(String verificationId, String smsCode) async {
    state = const AsyncLoading();
    try {
      final channel = ref.read(otpChannelProvider);
      await channel.verify(verificationId, smsCode);
      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateProfile(
    String firstName,
    String lastName,
    File? photo,
  ) async {
    state = const AsyncLoading();
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      String? photoUrl;
      if (photo != null) {
        final storageRef = FirebaseStorage.instance.ref().child(
          r'avatars/${user.uid}.jpg',
        );
        await storageRef.putFile(photo);
        photoUrl = await storageRef.getDownloadURL();
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'firstName': firstName,
        'lastName': lastName,
        'photoUrl': photoUrl,
        'phone': user.phoneNumber ?? ref.read(currentPhoneProvider),
        'createdAt': FieldValue.serverTimestamp(),
      });

      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

@Riverpod(keepAlive: true)
class CurrentPhone extends _$CurrentPhone {
  @override
  String build() => '';

  // ignore: use_setters_to_change_properties, Riverpod notifier state mutation needs a method
  void updatePhone(String phone) => state = phone;
}

@Riverpod(keepAlive: true)
class CurrentVerificationId extends _$CurrentVerificationId {
  @override
  String build() => '';

  // ignore: use_setters_to_change_properties, Riverpod notifier state mutation needs a method
  void updateId(String id) => state = id;
}
