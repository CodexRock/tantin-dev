import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/components/button.dart';
import 'package:tantin_flutter/design_system/icons/tn_icons.dart';
import 'package:tantin_flutter/features/onboarding/presentation/widgets/back_bar.dart';

class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  Future<void> _requestContacts(BuildContext context) async {
    // Request permission using permission_handler
    await Permission.contacts.request();
    if (context.mounted) {
      context.go('/home');
    }
  }

  void _skip(BuildContext context) {
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
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
                      child: TnIcons.contacts(
                        size: 34,
                        color: TantinColors.majorelle,
                      ),
                    ),
                    const Reveal(
                      delay: Duration(milliseconds: 50),
                      child: Padding(
                        padding: EdgeInsets.only(top: 18, bottom: 8),
                        child: Text(
                          'Retrouvez vos\nproches',
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
                          "Tant'in utilise vos contacts pour "
                          'trouver les membres de votre daret. '
                          "Rien n'est envoyé sans votre accord.",
                          style: TextStyle(
                            fontSize: 15.5,
                            color: TantinColors.inkMuted,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TnButton(
                    onPressed: () => _requestContacts(context),
                    full: true,
                    size: ButtonSize.lg,
                    child: const Text("Autoriser l'accès"),
                  ),
                  const SizedBox(height: 12),
                  TnButton(
                    onPressed: () => _skip(context),
                    full: true,
                    size: ButtonSize.lg,
                    variant: ButtonVariant.ghost,
                    child: const Text('Plus tard'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
