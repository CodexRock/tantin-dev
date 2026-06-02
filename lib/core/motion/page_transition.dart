import 'package:flutter/material.dart';

class PageTransitions {
  static Widget slideFwd(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curve = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.32, 0.72, 0, 1),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        return Opacity(
          opacity: curve.value,
          child: Transform.translate(
            offset: Offset(26 * (1 - curve.value), 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  static Widget slideBack(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final curve = CurvedAnimation(
      parent: animation,
      curve: const Cubic(0.32, 0.72, 0, 1),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        return Opacity(
          opacity: curve.value,
          child: Transform.translate(
            offset: Offset(-22 * (1 - curve.value), 0),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
