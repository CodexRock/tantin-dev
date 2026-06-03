import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';

// Manual Riverpod 2 providers (no codegen; see DECISIONS D025).

final authControllerProvider =
    AutoDisposeNotifierProvider<AuthController, AsyncValue<void>>(
      AuthController.new,
    );

class AuthController extends AutoDisposeNotifier<AsyncValue<void>> {
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
          'users/${user.uid}/avatar.jpg',
        );
        await storageRef.putFile(photo);
        photoUrl = await storageRef.getDownloadURL();
      }

      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();
      final initials =
          '${trimmedFirstName[0]}'
                  '${trimmedLastName.isEmpty ? '' : trimmedLastName[0]}'
              .toUpperCase();

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'prenom': trimmedFirstName,
        'nom': trimmedLastName,
        'name': '$trimmedFirstName $trimmedLastName'.trim(),
        'initials': initials,
        'photoUrl': photoUrl,
        'phone': user.phoneNumber ?? ref.read(currentPhoneProvider),
        'avatarPalette': ['#5247E6', '#E7E5FB'],
        'fcmTokens': <String>[],
        'settings': {
          'defaultEcheanceDay': 5,
          'graceDays': 2,
          'lang': 'fr',
          'notifPrefs': {
            'contributions': true,
            'reminders': true,
            'turns': true,
          },
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      state = const AsyncData(null);
    } on Exception catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }
}

final currentPhoneProvider = NotifierProvider<CurrentPhone, String>(
  CurrentPhone.new,
);

class CurrentPhone extends Notifier<String> {
  @override
  String build() => '';

  // ignore: use_setters_to_change_properties, Riverpod notifier state mutation needs a method
  void updatePhone(String phone) => state = phone;
}

final currentVerificationIdProvider =
    NotifierProvider<CurrentVerificationId, String>(
      CurrentVerificationId.new,
    );

class CurrentVerificationId extends Notifier<String> {
  @override
  String build() => '';

  // ignore: use_setters_to_change_properties, Riverpod notifier state mutation needs a method
  void updateId(String id) => state = id;
}
