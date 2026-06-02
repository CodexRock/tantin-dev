import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/art/tn_art.dart';
import 'package:tantin_flutter/features/onboarding/presentation/widgets/big_wordmark.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null &&
        !MediaQuery.disableAnimationsOf(context) &&
        !const bool.fromEnvironment('FLUTTER_TEST') &&
        !Platform.environment.containsKey('FLUTTER_TEST')) {
      _timer = Timer(const Duration(milliseconds: 2200), () {
        if (mounted) {
          context.go('/intro');
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _timer?.cancel();
          context.go('/intro');
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                TantinColors.majorelle,
                TantinColors.majorelleDeep,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Zellige background
              Positioned.fill(
                child: Opacity(
                  opacity: 0.4,
                  child: TnArt.zelligeFaint(),
                ),
              ),
              // Floating star tiles
              _buildStarTile(
                index: 0,
                size: 180,
                left: -0.12,
                top: 0.08,
              ),
              _buildStarTile(
                index: 1,
                size: 150,
                left: 0.70,
                top: 0.62,
              ),
              _buildStarTile(
                index: 2,
                size: 120,
                left: 0.30,
                top: 0.84,
              ),
              // Content
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Reveal(
                      delay: Duration(milliseconds: 300),
                      child: BigWordmark(size: 62, light: true),
                    ),
                    const SizedBox(height: 16),
                    Reveal(
                      delay: const Duration(milliseconds: 700),
                      child: Text(
                        'Vos darets, en toute confiance.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.16, // 0.01em = 0.16px at 16px
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
    );
  }

  Widget _buildStarTile({
    required int index,
    required double size,
    required double left,
    required double top,
  }) {
    return Positioned(
      // We use MediaQuery to translate percentages to fixed values, since
      // Positioned doesn't support percentage-based left/top directly.
      left: MediaQuery.sizeOf(context).width * left,
      top: MediaQuery.sizeOf(context).height * top,
      child: FadeIn(
        child: Builder(
          builder: (context) {
            final isTesting =
                const bool.fromEnvironment('FLUTTER_TEST') ||
                Platform.environment.containsKey('FLUTTER_TEST');
            if (isTesting || MediaQuery.disableAnimationsOf(context)) {
              return Opacity(
                opacity: 0.16,
                child: TnArt.starTile(
                  size: size,
                  c1: const Color(0xFF7A6FF5),
                  c3: Colors.white,
                ),
              );
            }
            return FutureBuilder<void>(
              future: Future.delayed(
                Duration(milliseconds: 200 + (index * 250)),
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const SizedBox.shrink();
                }
                return Opacity(
                  opacity: 0.16,
                  child: TnArt.starTile(
                    size: size,
                    c1: const Color(0xFF7A6FF5),
                    c3: Colors.white,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
