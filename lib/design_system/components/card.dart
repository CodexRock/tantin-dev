import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

class TnCard extends StatelessWidget {
  const TnCard({
    required this.child,
    super.key,
    this.onPressed,
    this.accent,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final Widget content = Container(
      decoration: BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: TantinShadows.md,
        border: Border.all(color: TantinColors.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          if (accent != null)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 4,
              child: ColoredBox(color: accent!),
            ),
          child,
        ],
      ),
    );

    if (onPressed != null) {
      return Pressable(
        onPressed: onPressed,
        child: content,
      );
    }
    return content;
  }
}
