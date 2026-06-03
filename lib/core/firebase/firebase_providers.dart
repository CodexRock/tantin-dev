import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Manual Riverpod 2 providers (no codegen; see DECISIONS D025).

final AutoDisposeProvider<FirebaseAuth> firebaseAuthProvider =
    Provider.autoDispose<FirebaseAuth>((ref) => FirebaseAuth.instance);

final AutoDisposeProvider<FirebaseFirestore> firebaseFirestoreProvider =
    Provider.autoDispose<FirebaseFirestore>(
      (ref) => FirebaseFirestore.instance,
    );

final AutoDisposeProvider<FirebaseFunctions> firebaseFunctionsProvider =
    Provider.autoDispose<FirebaseFunctions>(
      (ref) => FirebaseFunctions.instanceFor(region: 'europe-west1'),
    );

final AutoDisposeProvider<FirebaseMessaging> firebaseMessagingProvider =
    Provider.autoDispose<FirebaseMessaging>(
      (ref) => FirebaseMessaging.instance,
    );

final AutoDisposeProvider<FirebaseStorage> firebaseStorageProvider =
    Provider.autoDispose<FirebaseStorage>((ref) => FirebaseStorage.instance);
