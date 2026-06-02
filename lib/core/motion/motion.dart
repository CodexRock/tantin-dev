import 'package:flutter/material.dart';

/// Stubs for motion helpers (full implementation in S1)
class Reveal extends StatelessWidget {
  final Widget child;
  final Duration delay;

  const Reveal({super.key, required this.child, this.delay = Duration.zero});

  @override
  Widget build(BuildContext context) {
    // S0 placeholder: just return child. Full animation in S1.
    return child;
  }
}

class FadeIn extends StatelessWidget {
  final Widget child;

  const FadeIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class Pressable extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;

  const Pressable({super.key, required this.child, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: child,
    );
  }
}
