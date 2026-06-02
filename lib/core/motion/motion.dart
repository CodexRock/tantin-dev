import 'package:flutter/material.dart';

/// Stubs for motion helpers (full implementation in S1)
class Reveal extends StatelessWidget {
  const Reveal({required this.child, super.key, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    // S0 placeholder: just return child. Full animation in S1.
    return child;
  }
}

class FadeIn extends StatelessWidget {
  const FadeIn({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return child;
  }
}

class Pressable extends StatelessWidget {
  const Pressable({required this.child, super.key, this.onPressed});

  final Widget child;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: child,
    );
  }
}
