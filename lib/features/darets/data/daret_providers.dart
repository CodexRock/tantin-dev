import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_repository.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

part 'daret_providers.g.dart';

@riverpod
DaretRepository daretRepository(Ref ref) {
  return DaretRepository(ref.watch(firebaseFirestoreProvider));
}

@riverpod
Stream<List<Daret>> myDarets(Ref ref, {DaretStatus? status}) {
  final user = ref.watch(authStateChangesProvider).value;
  if (user == null) return Stream.value(const []);
  return ref
      .watch(daretRepositoryProvider)
      .watchMyDarets(
        user.uid,
        status: status,
      );
}

@riverpod
Stream<Daret?> daret(Ref ref, String daretId) {
  return ref.watch(daretRepositoryProvider).watchDaret(daretId);
}

@riverpod
Stream<List<DaretMember>> daretMembers(Ref ref, String daretId) {
  return ref.watch(daretRepositoryProvider).watchMembers(daretId);
}

@riverpod
Stream<List<DaretPeriod>> periods(Ref ref, String daretId) {
  return ref.watch(daretRepositoryProvider).watchPeriods(daretId);
}

@riverpod
Stream<List<Contribution>> currentContributions(
  Ref ref,
  String daretId,
  int periodIndex,
) {
  return ref
      .watch(daretRepositoryProvider)
      .watchContributions(daretId, periodIndex);
}
