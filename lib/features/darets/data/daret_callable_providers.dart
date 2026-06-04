import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_callable_repository.dart';

// Manual Riverpod 2 provider (no codegen; see DECISIONS D025).

final AutoDisposeProvider<DaretCallableRepository>
daretCallableRepositoryProvider = Provider.autoDispose<DaretCallableRepository>(
  (ref) => DaretCallableRepository(
    ref.watch(firebaseFunctionsProvider),
    ref.watch(firebaseAuthProvider),
  ),
);
