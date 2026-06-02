import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pinput/pinput.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/features/auth/presentation/auth_controller.dart';
import 'package:tantin_flutter/features/onboarding/presentation/widgets/back_bar.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  Timer? _timer;
  int _secondsLeft = 38;
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    if (const bool.fromEnvironment('FLUTTER_TEST') ||
        Platform.environment.containsKey('FLUTTER_TEST')) {
      return;
    }
    setState(() => _secondsLeft = 38);
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify(String code) async {
    final verificationId = ref.read(currentVerificationIdProvider);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .verifyCode(verificationId, code);
      if (mounted) {
        context.go('/profile-setup');
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $error')),
        );
      }
      _pinController.clear();
    }
  }

  Future<void> _resend() async {
    final phone = ref.read(currentPhoneProvider);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .sendCode(
            phone,
            onCodeSent: (newVerificationId) {
              ref
                  .read(currentVerificationIdProvider.notifier)
                  .updateId(newVerificationId);
              _startTimer();
            },
            onError: (error) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erreur: ${error.message}')),
                );
              }
            },
          );
    } on Exception {
      // Handled by onError mostly.
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(currentPhoneProvider);
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    final defaultPinTheme = PinTheme(
      width: 46,
      height: 58,
      textStyle: const TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        fontFamily: 'Fraunces',
        color: TantinColors.ink,
      ),
      decoration: BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: TantinColors.hairline, width: 1.5),
      ),
    );

    final submittedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        color: TantinColors.majorelleSoft,
        border: Border.all(color: TantinColors.majorelle, width: 1.5),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyWith(
      decoration: defaultPinTheme.decoration?.copyWith(
        border: Border.all(color: TantinColors.majorelle, width: 1.5),
      ),
    );

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        child: Column(
          children: [
            const BackBar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 28, right: 28, top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Reveal(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: TantinColors.majorelleSoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.chat_bubble_rounded,
                          color: TantinColors.majorelle,
                          size: 28,
                        ),
                      ),
                    ),
                    const Reveal(
                      delay: Duration(milliseconds: 50),
                      child: Padding(
                        padding: EdgeInsets.only(top: 18, bottom: 8),
                        child: Text(
                          'Entrez le code',
                          style: TextStyle(
                            fontFamily: 'Fraunces',
                            fontSize: 28,
                            letterSpacing: -0.84,
                            height: 1.12,
                            color: TantinColors.ink,
                          ),
                        ),
                      ),
                    ),
                    Reveal(
                      delay: const Duration(milliseconds: 100),
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: Text.rich(
                          TextSpan(
                            text: 'Code envoyé par SMS au ',
                            children: [
                              TextSpan(
                                text: phone.isEmpty
                                    ? '+212 6 12 34 56 78'
                                    : phone,
                                style: const TextStyle(
                                  color: TantinColors.ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          style: const TextStyle(
                            fontSize: 15.5,
                            color: TantinColors.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Reveal(
                      delay: const Duration(milliseconds: 160),
                      child: Pinput(
                        length: 6,
                        controller: _pinController,
                        defaultPinTheme: defaultPinTheme,
                        focusedPinTheme: focusedPinTheme,
                        submittedPinTheme: submittedPinTheme,
                        onCompleted: _verify,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        autofocus: !MediaQuery.disableAnimationsOf(context),
                        readOnly: isLoading,
                      ),
                    ),
                    Reveal(
                      delay: const Duration(milliseconds: 220),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(
                          child: _secondsLeft > 0
                              ? Text.rich(
                                  TextSpan(
                                    text: 'Renvoyer le code dans ',
                                    children: [
                                      TextSpan(
                                        text:
                                            '0:'
                                            '${_secondsLeft.toString().padLeft(
                                              2,
                                              '0',
                                            )}',
                                        style: const TextStyle(
                                          color: TantinColors.ink,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: TantinColors.inkMuted,
                                  ),
                                )
                              : Pressable(
                                  onPressed: isLoading ? null : _resend,
                                  child: const Text(
                                    'Renvoyer le code',
                                    style: TextStyle(
                                      color: TantinColors.majorelle,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (isLoading)
                      const Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
