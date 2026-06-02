import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

class ProgressRing extends StatelessWidget {
  const ProgressRing({
    required this.value,
    required this.total,
    super.key,
    this.size = 52.0,
    this.strokeWidth = 5.0,
    this.color = TantinColors.majorelle,
    this.trackColor = TantinColors.ivorySunken,
    this.child,
  });

  final double value;
  final double total;
  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value / total).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: pct),
            duration: const Duration(milliseconds: 900),
            curve: const Cubic(0.22, 1, 0.36, 1),
            builder: (context, animVal, _) {
              final currentVal = MediaQuery.disableAnimationsOf(context)
                  ? pct
                  : animVal;
              return CustomPaint(
                size: Size(size, size),
                painter: _RingPainter(
                  pct: currentVal,
                  strokeWidth: strokeWidth,
                  color: color,
                  trackColor: trackColor,
                ),
              );
            },
          ),
          ?child,
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.pct,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  final double pct;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = (size.width - strokeWidth) / 2;
    final center = Offset(size.width / 2, size.height / 2);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    if (pct > 0) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * pct,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.pct != pct ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
