import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/art/tn_art.dart';
import 'package:tantin_flutter/design_system/components/button.dart';
import 'package:tantin_flutter/design_system/icons/tn_icons.dart';

class _SlideData {
  const _SlideData({
    required this.art,
    required this.title,
    required this.body,
    required this.color,
  });
  final Widget Function({double size}) art;
  final String title;
  final String body;
  final Color color;
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  int _currentIndex = 0;

  final List<_SlideData> _slides = [
    const _SlideData(
      art: TnArt.weaveTile,
      title: 'Ne perdez plus le fil',
      body:
          'Un suivi limpide de chaque daret : '
          'qui a payé, qui reçoit, et quand.',
      color: TantinColors.majorelle,
    ),
    const _SlideData(
      art: TnArt.starTile,
      title: 'Tout le monde voit la vérité',
      body:
          'Chaque membre voit les mêmes informations. '
          'La confiance, par la transparence.',
      color: TantinColors.terracotta,
    ),
    const _SlideData(
      art: TnArt.archTile,
      title: 'Recevez votre tour à temps',
      body:
          'Rappels automatiques et calendrier clair. '
          'Votre tour arrive, vous êtes prêt.',
      color: TantinColors.saffronDeep,
    ),
  ];

  void _next() {
    if (_currentIndex < 2) {
      setState(() => _currentIndex++);
    } else {
      context.go('/phone');
    }
  }

  void _skip() {
    context.go('/phone');
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentIndex];

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Pressable(
                  onPressed: _skip,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Text(
                      'Passer',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: TantinColors.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 36),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Art
                    Reveal(
                      key: ValueKey('art_$_currentIndex'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 40),
                        child: Stack(
                          alignment: Alignment.center,
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: -30,
                              bottom: -30,
                              left: -30,
                              right: -30,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      slide.color.withValues(
                                        alpha: 0.13,
                                      ), // ~ #22 hex in React
                                      Colors.transparent,
                                    ],
                                    stops: const [0.0, 0.7],
                                  ),
                                ),
                              ),
                            ),
                            Transform.scale(
                              scale: 1.7,
                              child: slide.art(size: 130),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Title
                    Reveal(
                      key: ValueKey('title_$_currentIndex'),
                      delay: const Duration(milliseconds: 80),
                      child: Text(
                        slide.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Fraunces',
                          fontSize: 30,
                          letterSpacing: -0.9, // -0.03em
                          height: 1.1,
                          color: TantinColors.ink,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Body
                    Reveal(
                      key: ValueKey('body_$_currentIndex'),
                      delay: const Duration(milliseconds: 140),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: Text(
                          slide.body,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
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

            // Bottom bar
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Paging dots
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (index) {
                        final isActive = index == _currentIndex;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.ease,
                          margin: const EdgeInsets.symmetric(horizontal: 3.5),
                          height: 7,
                          width: isActive ? 22 : 7,
                          decoration: BoxDecoration(
                            color: isActive
                                ? TantinColors.majorelle
                                : TantinColors.ivorySunken,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Next button
                  TnButton(
                    onPressed: _next,
                    full: true,
                    size: ButtonSize.lg,
                    iconRight: _currentIndex < 2
                        ? TnIcons.chevR(size: 20, color: Colors.white)
                        : null,
                    child: Text(_currentIndex < 2 ? 'Suivant' : 'Commencer'),
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
