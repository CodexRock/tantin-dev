import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/auth/data/auth_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_repository.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

// Manual Riverpod 2 providers (no codegen; see DECISIONS D025).

final AutoDisposeProvider<DaretRepository> daretRepositoryProvider =
    Provider.autoDispose<DaretRepository>(
      (ref) => DaretRepository(ref.watch(firebaseFirestoreProvider)),
    );

final AutoDisposeStreamProvider<List<Daret>> myDaretsProvider =
    StreamProvider.autoDispose<List<Daret>>((ref) {
      final user = ref.watch(authStateChangesProvider).value;
      if (user == null) return Stream.value(const []);
      return ref.watch(daretRepositoryProvider).watchMyDarets(user.uid);
    });

final AutoDisposeStreamProviderFamily<Daret?, String> daretProvider =
    StreamProvider.autoDispose.family<Daret?, String>(
      (ref, daretId) => ref.watch(daretRepositoryProvider).watchDaret(daretId),
    );

final AutoDisposeStreamProviderFamily<List<DaretMember>, String>
daretMembersProvider = StreamProvider.autoDispose
    .family<List<DaretMember>, String>(
      (ref, daretId) =>
          ref.watch(daretRepositoryProvider).watchMembers(daretId),
    );

final AutoDisposeStreamProviderFamily<List<DaretPeriod>, String>
periodsProvider = StreamProvider.autoDispose.family<List<DaretPeriod>, String>(
  (ref, daretId) => ref.watch(daretRepositoryProvider).watchPeriods(daretId),
);

/// Family key is `(daretId, periodIndex)`.
final AutoDisposeStreamProviderFamily<List<Contribution>, (String, int)>
currentContributionsProvider = StreamProvider.autoDispose
    .family<List<Contribution>, (String, int)>((
      ref,
      key,
    ) {
      final (daretId, periodIndex) = key;
      return ref
          .watch(daretRepositoryProvider)
          .watchContributions(daretId, periodIndex);
    });
