import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/features/auth/domain/phone_validator.dart';

void main() {
  group('PhoneValidator', () {
    test('formatPhone formats string with spaces', () {
      expect(PhoneValidator.formatPhone('6'), '6');
      expect(PhoneValidator.formatPhone('61'), '6 1');
      expect(PhoneValidator.formatPhone('612'), '6 12');
      expect(PhoneValidator.formatPhone('61234'), '6 12 34');
      expect(PhoneValidator.formatPhone('612345678'), '6 12 34 56 78');
      expect(PhoneValidator.formatPhone('61 23 45 67 8'), '6 12 34 56 78');
      expect(PhoneValidator.formatPhone('6123456789'), '6 12 34 56 78');
    });

    test('isValidMoroccanPhone validates correct lengths and prefixes', () {
      // Valid lengths and prefixes (5, 6, 7, 8)
      expect(PhoneValidator.isValidMoroccanPhone('512345678'), isTrue);
      expect(PhoneValidator.isValidMoroccanPhone('612345678'), isTrue);
      expect(PhoneValidator.isValidMoroccanPhone('712345678'), isTrue);
      expect(PhoneValidator.isValidMoroccanPhone('812345678'), isTrue);
      expect(PhoneValidator.isValidMoroccanPhone('6 12 34 56 78'), isTrue);

      // Invalid lengths
      expect(PhoneValidator.isValidMoroccanPhone('61234567'), isFalse);
      expect(PhoneValidator.isValidMoroccanPhone('6123456789'), isFalse);

      // Invalid prefixes
      expect(PhoneValidator.isValidMoroccanPhone('412345678'), isFalse);
      expect(PhoneValidator.isValidMoroccanPhone('912345678'), isFalse);
    });

    test('toE164 converts to +212 format', () {
      expect(PhoneValidator.toE164('612345678'), '+212612345678');
      expect(PhoneValidator.toE164('6 12 34 56 78'), '+212612345678');
    });
  });
}
