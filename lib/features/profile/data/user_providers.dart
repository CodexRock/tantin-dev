import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/profile/data/user_repository.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

part 'user_providers.g.dart';

@riverpod
UserRepository userRepository(Ref ref) {
  return UserRepository(ref.watch(firebaseFirestoreProvider));
}

@riverpod
Stream<AppUser?> currentAppUser(Ref ref) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(null);
  return ref.watch(userRepositoryProvider).watchUser(user.uid);
}
