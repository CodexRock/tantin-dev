import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tantin_flutter/core/firebase/firebase_providers.dart';
import 'package:tantin_flutter/features/activity/data/activity_repository.dart';
import 'package:tantin_flutter/features/activity/domain/activity_event.dart';

part 'activity_providers.g.dart';

@riverpod
ActivityRepository activityRepository(Ref ref) {
  return ActivityRepository(ref.watch(firebaseFirestoreProvider));
}

@riverpod
Stream<List<ActivityEvent>> activity(Ref ref, String daretId) {
  return ref.watch(activityRepositoryProvider).watchActivity(daretId);
}
