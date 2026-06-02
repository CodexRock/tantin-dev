import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/features/auth/presentation/auth_controller.dart';

void main() {
  test('Regression: keepAlive on phone and verificationId providers', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Initial values
    expect(container.read(currentPhoneProvider), '');
    expect(container.read(currentVerificationIdProvider), '');

    // Update the values
    container.read(currentPhoneProvider.notifier).updatePhone('123456789');
    container
        .read(currentVerificationIdProvider.notifier)
        .updateId('verif-id-123');

    // Simulate reading the value in a widget
    final subPhone = container.listen(currentPhoneProvider, (p, n) {});
    final subId = container.listen(currentVerificationIdProvider, (p, n) {});

    subPhone.close();
    subId.close();

    // They should NOT reset to default after listeners are closed
    expect(container.read(currentPhoneProvider), '123456789');
    expect(container.read(currentVerificationIdProvider), 'verif-id-123');
  });
}
