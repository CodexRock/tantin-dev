import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/icons/tn_icons.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showCoachmark = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      appBar: AppBar(
        title: const Text(
          'Accueil',
          style: TextStyle(
            color: TantinColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: TantinColors.ivoryBg,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: TnIcons.logout(color: TantinColors.ink),
          ),
        ],
      ),
      body: Stack(
        children: [
          const Center(
            child: Text(
              'Dashboard Placeholder',
              style: TextStyle(color: TantinColors.inkMuted),
            ),
          ),
          if (_showCoachmark)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showCoachmark = false),
                child: ColoredBox(
                  color: TantinColors.ink.withValues(alpha: 0.7),
                  child: Stack(
                    children: [
                      Positioned(
                        bottom: 90,
                        right: 32,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Créez votre premier daret',
                              style: TextStyle(
                                fontFamily: 'Fraunces',
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Appuyez sur le + pour commencer.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TnIcons.arrowDown(size: 40, color: Colors.white),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_showCoachmark) setState(() => _showCoachmark = false);
        },
        backgroundColor: TantinColors.saffron,
        elevation: 4,
        child: TnIcons.plus(size: 28, color: TantinColors.ink),
      ),
    );
  }
}
