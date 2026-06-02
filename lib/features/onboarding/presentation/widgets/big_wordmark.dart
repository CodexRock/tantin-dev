import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

class BigWordmark extends StatelessWidget {
  const BigWordmark({
    super.key,
    this.size = 56,
    this.light = false,
  });
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final textColor = light ? Colors.white : TantinColors.ink;

    return Text.rich(
      const TextSpan(
        text: 'Tant',
        children: [
          TextSpan(
            text: "'",
            style: TextStyle(color: TantinColors.saffron),
          ),
          TextSpan(text: 'in'),
        ],
      ),
      style: TextStyle(
        fontFamily: 'Fraunces',
        fontSize: size,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.04 * size, // -0.04em
        color: textColor,
        height: 1,
      ),
    );
  }
}
