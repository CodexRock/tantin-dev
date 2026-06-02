import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_callable_repository.dart';

part 'daret_callable_providers.g.dart';

@riverpod
DaretCallableRepository daretCallableRepository(Ref ref) {
  return DaretCallableRepository(ref.watch(firebaseFunctionsProvider));
}
