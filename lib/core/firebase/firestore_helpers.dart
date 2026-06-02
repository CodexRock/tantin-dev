import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? dateTimeFromFirestore(Object? value) {
  return switch (value) {
    final Timestamp timestamp => timestamp.toDate(),
    final DateTime dateTime => dateTime,
    _ => null,
  };
}

Timestamp? timestampFromDateTime(DateTime? value) {
  return value == null ? null : Timestamp.fromDate(value);
}

List<String> stringListFromFirestore(Object? value) {
  if (value is! List<Object?>) return const [];
  return value.whereType<String>().toList(growable: false);
}

Map<String, int> intMapFromFirestore(Object? value) {
  if (value is! Map<Object?, Object?>) return const {};
  final result = <String, int>{};
  for (final entry in value.entries) {
    final key = entry.key;
    final item = entry.value;
    if (key is String && item is int) result[key] = item;
  }
  return result;
}

Map<String, dynamic> mapFromFirestore(Object? value) {
  if (value is! Map<Object?, Object?>) return const {};
  return <String, dynamic>{
    for (final entry in value.entries)
      if (entry.key case final String key) key: entry.value,
  };
}
