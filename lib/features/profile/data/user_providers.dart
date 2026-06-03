import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/profile/data/user_repository.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

// Manual Riverpod 2 providers (no codegen; see DECISIONS D025).

final AutoDisposeProvider<UserRepository> userRepositoryProvider =
    Provider.autoDispose<UserRepository>(
      (ref) => UserRepository(ref.watch(firebaseFirestoreProvider)),
    );

final AutoDisposeStreamProvider<AppUser?> currentAppUserProvider =
    StreamProvider.autoDispose<AppUser?>((ref) {
      final user = ref.watch(authStateChangesProvider).value;
      if (user == null) return Stream.value(null);
      return ref.watch(userRepositoryProvider).watchUser(user.uid);
    });
