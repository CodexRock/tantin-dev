import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/components/button.dart';
import 'package:tantin_flutter/design_system/icons/tn_icons.dart';
import 'package:tantin_flutter/features/auth/domain/phone_validator.dart';
import 'package:tantin_flutter/features/auth/presentation/auth_controller.dart';
import 'package:tantin_flutter/features/onboarding/presentation/widgets/back_bar.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    final formatted = PhoneValidator.formatPhone(value);
    if (formatted != _controller.text) {
      _controller.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    setState(() {});
  }

  void _submit() {
    if (!PhoneValidator.isValidMoroccanPhone(_controller.text)) return;

    final fullPhone = PhoneValidator.toE164(_controller.text);
    ref.read(currentPhoneProvider.notifier).updatePhone(fullPhone);

    unawaited(
      ref
          .read(authControllerProvider.notifier)
          .sendCode(
            fullPhone,
            onCodeSent: (verificationId) {
              ref
                  .read(currentVerificationIdProvider.notifier)
                  .updateId(verificationId);
              context.go('/otp');
            },
            onError: (error) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: ${error.message}'),
                ),
              );
            },
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isSubmitDisabled =
        !PhoneValidator.isValidMoroccanPhone(_controller.text) || isLoading;

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
                      child: TnIcons.phone(
                        size: 34,
                        color: TantinColors.majorelle,
                      ),
                    ),
                    const Reveal(
                      delay: Duration(milliseconds: 50),
                      child: Padding(
                        padding: EdgeInsets.only(top: 18, bottom: 8),
                        child: Text(
                          'Votre numéro\nde téléphone',
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
                    const Reveal(
                      delay: Duration(milliseconds: 100),
                      child: Padding(
                        padding: EdgeInsets.only(bottom: 30),
                        child: Text(
                          'On vous envoie un code par SMS '
                          'pour vérifier votre numéro.',
                          style: TextStyle(
                            fontSize: 15.5,
                            color: TantinColors.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                    Reveal(
                      delay: const Duration(milliseconds: 160),
                      child: Row(
                        children: [
                          Container(
                            height: 58,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: TantinColors.ivorySurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: TantinColors.hairline,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Text(
                                  '🇲🇦',
                                  style: TextStyle(fontSize: 22),
                                ),
                                const SizedBox(width: 7),
                                const Text(
                                  '+212',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: TantinColors.ink,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                TnIcons.chevDown(
                                  size: 16,
                                  color: TantinColors.inkMuted,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 58,
                              decoration: BoxDecoration(
                                color: TantinColors.ivorySurface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _isFocused
                                      ? TantinColors.majorelle
                                      : TantinColors.hairline,
                                  width: 1.5,
                                ),
                              ),
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: TextField(
                                controller: _controller,
                                focusNode: _focusNode,
                                keyboardType: TextInputType.phone,
                                autofocus: !MediaQuery.disableAnimationsOf(
                                  context,
                                ),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.36,
                                  color: TantinColors.ink,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: '6 12 34 56 78',
                                  hintStyle: TextStyle(
                                    color: TantinColors.inkMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onChanged: _onChanged,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: TnButton(
                onPressed: isLoading ? null : _submit,
                size: ButtonSize.lg,
                disabled: isSubmitDisabled,
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Text('Recevoir le code'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
