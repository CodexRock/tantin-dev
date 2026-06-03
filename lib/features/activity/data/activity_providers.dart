import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/activity/data/activity_repository.dart';
import 'package:tantin_flutter/features/activity/domain/activity_event.dart';

// Manual Riverpod 2 providers (no codegen; see DECISIONS D025).

final AutoDisposeProvider<ActivityRepository> activityRepositoryProvider =
    Provider.autoDispose<ActivityRepository>(
      (ref) => ActivityRepository(ref.watch(firebaseFirestoreProvider)),
    );

final AutoDisposeStreamProviderFamily<List<ActivityEvent>, String>
activityProvider = StreamProvider.autoDispose
    .family<List<ActivityEvent>, String>(
      (ref, daretId) =>
          ref.watch(activityRepositoryProvider).watchActivity(daretId),
    );
