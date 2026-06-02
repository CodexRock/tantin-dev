import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/format/format.dart';

class CountUp extends StatelessWidget {
  const CountUp({
    required this.value,
    super.key,
    this.duration = const Duration(milliseconds: 1100),
    this.prefix = '',
    this.suffix = ' DH',
    this.style,
  });

  final double value;
  final Duration duration;
  final String prefix;
  final String suffix;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = DefaultTextStyle.of(context).style;
    final mergedStyle = defaultStyle
        .merge(style)
        .copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        );

    if (MediaQuery.disableAnimationsOf(context)) {
      return Text(
        '$prefix${TantinFormat.fmtNum(value)}$suffix',
        style: mergedStyle,
      );
    }
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          '$prefix${TantinFormat.fmtNum(val)}$suffix',
          style: mergedStyle,
        );
      },
    );
  }
}
