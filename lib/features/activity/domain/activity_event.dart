import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_event.freezed.dart';
part 'activity_event.g.dart';

@JsonEnum(valueField: 'firestoreValue')
enum ActivityType {
  paiement('paiement'),
  tour('tour'),
  rappel('rappel'),
  membre('membre'),
  demarre('demarre'),
  cloture('cloture')
  ;

  const ActivityType(this.firestoreValue);

  final String firestoreValue;
}

@freezed
abstract class ActivityEvent with _$ActivityEvent {
  const factory ActivityEvent({
    required String id,
    required ActivityType type,
    required String actorUid,
    required String text,
    required DateTime createdAt,
    int? amount,
    int? periodIndex,
  }) = _ActivityEvent;

  factory ActivityEvent.fromJson(Map<String, dynamic> json) =>
      _$ActivityEventFromJson(json);
}
