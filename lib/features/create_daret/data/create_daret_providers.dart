import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/create_daret/data/create_daret_repository.dart';
import 'package:tantin_flutter/features/create_daret/domain/create_daret_models.dart';
import 'package:tantin_flutter/features/create_daret/presentation/create_daret_controller.dart';

final createDaretRepositoryProvider = Provider<CreateDaretRepository>((ref) {
  return CreateDaretRepository(ref.watch(firebaseFirestoreProvider));
});

final AutoDisposeStateNotifierProvider<CreateDaretController, CreateDaretState>
createDaretControllerProvider =
    StateNotifierProvider.autoDispose<CreateDaretController, CreateDaretState>((
      ref,
    ) {
      return CreateDaretController();
    });
