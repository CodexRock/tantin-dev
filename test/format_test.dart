import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/core/format/format.dart';

void main() {
  group('TantinFormat.fmtDH', () {
    test('formats regular amount correctly', () {
      expect(TantinFormat.fmtDH(1500), '1 500 DH');
    });

    test('formats large amount correctly', () {
      expect(TantinFormat.fmtDH(1500000), '1 500 000 DH');
    });

    test('formats zero correctly', () {
      expect(TantinFormat.fmtDH(0), '0 DH');
    });
  });
}
