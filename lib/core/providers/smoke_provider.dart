import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'smoke_provider.g.dart';

@riverpod
String smoke(Ref ref) {
  return 'Hello, World!';
}
