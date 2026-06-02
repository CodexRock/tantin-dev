import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smoke_provider.g.dart';

@riverpod
String smoke(SmokeRef ref) {
  return 'Hello, World!';
}
