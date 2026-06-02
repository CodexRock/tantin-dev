import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/components/button.dart';
import 'package:tantin_flutter/design_system/icons/tn_icons.dart';
import 'package:tantin_flutter/features/auth/presentation/auth_controller.dart';
import 'package:tantin_flutter/features/onboarding/presentation/widgets/back_bar.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _firstFocusNode = FocusNode();
  final _lastFocusNode = FocusNode();
  bool _firstFocused = false;
  bool _lastFocused = false;
  File? _image;

  @override
  void initState() {
    super.initState();
    _firstFocusNode.addListener(() {
      setState(() => _firstFocused = _firstFocusNode.hasFocus);
    });
    _lastFocusNode.addListener(() {
      setState(() => _lastFocused = _lastFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _firstFocusNode.dispose();
    _lastFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_firstNameController.text.trim().length < 2) return;
    try {
      await ref
          .read(authControllerProvider.notifier)
          .updateProfile(
            _firstNameController.text.trim(),
            _lastNameController.text.trim(),
            _image,
          );
      if (mounted) {
        context.go('/contacts');
      }
    } on Exception catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final isSubmitDisabled =
        _firstNameController.text.trim().length < 2 || isLoading;

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        child: Column(
          children: [
            const BackBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(left: 28, right: 28, top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Reveal(
                      child: TnIcons.user(
                        size: 34,
                        color: TantinColors.majorelle,
                      ),
                    ),
                    const Reveal(
                      delay: Duration(milliseconds: 50),
                      child: Padding(
                        padding: EdgeInsets.only(top: 18, bottom: 8),
                        child: Text(
                          'Créons votre\nprofil',
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
                          'Vos amis vous reconnaîtront plus '
                          'facilement dans les darets.',
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
                      child: Column(
                        children: [
                          Center(
                            child: Pressable(
                              onPressed: _pickImage,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: TantinColors.ivorySurface,
                                  borderRadius: BorderRadius.circular(36),
                                  border: _image == null
                                      ? Border.all(
                                          color: TantinColors.hairline,
                                          width: 1.5,
                                        ) // Dashed border deferred
                                      : null,
                                ),
                                child: Stack(
                                  children: [
                                    if (_image != null)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(36),
                                        child: Image.file(
                                          _image!,
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                    else
                                      Center(
                                        child: TnIcons.camera(
                                          size: 32,
                                          color: TantinColors.inkMuted,
                                        ),
                                      ),
                                    if (_image == null)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          decoration: BoxDecoration(
                                            color: TantinColors.ivoryBg,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: TantinColors.hairline,
                                              width: 1.5,
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: TnIcons.plus(
                                            size: 20,
                                            color: TantinColors.ink,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Container(
                            height: 58,
                            decoration: BoxDecoration(
                              color: TantinColors.ivorySurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _firstFocused
                                    ? TantinColors.majorelle
                                    : TantinColors.hairline,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: _firstNameController,
                              focusNode: _firstFocusNode,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: TantinColors.ink,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Prénom',
                                hintStyle: TextStyle(
                                  color: TantinColors.inkMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 58,
                            decoration: BoxDecoration(
                              color: TantinColors.ivorySurface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _lastFocused
                                    ? TantinColors.majorelle
                                    : TantinColors.hairline,
                                width: 1.5,
                              ),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            alignment: Alignment.center,
                            child: TextField(
                              controller: _lastNameController,
                              focusNode: _lastFocusNode,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: TantinColors.ink,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Nom (optionnel)',
                                hintStyle: TextStyle(
                                  color: TantinColors.inkMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
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
                onPressed: isSubmitDisabled ? null : _submit,
                full: true,
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
                    : const Text('Continuer'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
