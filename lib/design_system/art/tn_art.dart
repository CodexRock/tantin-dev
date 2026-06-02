import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract class TnArt {
  static Widget starTile({
    double size = 120,
    Color c1 = const Color(0xFF5247E6),
    Color c2 = const Color(0xFFF5A623),
    Color c3 = const Color(0xFFC75B39),
  }) {
    final c1Hex =
        '#${c1.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
    final c2Hex =
        '#${c2.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
    final c3Hex =
        '#${c3.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

    final svg =
        '''
<svg width="$size" height="$size" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <g>
    <circle cx="60" cy="60" r="56" fill="#EFE6D4" />
    <path d="M60 14l9 22 24-9-9 24 22 9-22 9 9 24-24-9-9 22-9-22-24 9 9-24-22-9 22-9-9-24 24 9 9-22Z" fill="$c1Hex" fill-opacity="0.16" />
    <path d="M60 26l7 16 17-6-6 17 16 7-16 7 6 17-17-6-7 16-7-16-17 6 6-17-16-7 16-7-6-17 17 6 7-16Z" fill="$c1Hex" />
    <circle cx="60" cy="60" r="13" fill="$c2Hex" />
    <circle cx="60" cy="60" r="5" fill="$c3Hex" />
  </g>
</svg>''';
    return SvgPicture.string(svg, width: size, height: size);
  }

  static Widget archTile({
    double size = 120,
    Color c1 = const Color(0xFF5247E6),
    Color c2 = const Color(0xFFF5A623),
  }) {
    final c1Hex =
        '#${c1.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
    final c2Hex =
        '#${c2.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

    final svg =
        '''
<svg width="$size" height="$size" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <rect x="18" y="14" width="84" height="92" rx="10" fill="#EFE6D4" />
  <path d="M30 100V58c0-16.6 13.4-30 30-30s30 13.4 30 30v42" fill="none" stroke="$c1Hex" stroke-width="7" />
  <path d="M44 100V60a16 16 0 0 1 32 0v40Z" fill="$c1Hex" fill-opacity="0.14" />
  <circle cx="60" cy="50" r="7" fill="$c2Hex" />
  <path d="M30 100h60" fill="none" stroke="$c1Hex" stroke-width="7" stroke-linecap="round" />
</svg>''';
    return SvgPicture.string(svg, width: size, height: size);
  }

  static Widget weaveTile({
    double size = 120,
    Color c1 = const Color(0xFFC75B39),
    Color c2 = const Color(0xFF5247E6),
    Color c3 = const Color(0xFFF5A623),
  }) {
    final c1Hex =
        '#${c1.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
    final c2Hex =
        '#${c2.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';
    final c3Hex =
        '#${c3.toARGB32().toRadixString(16).substring(2).padLeft(6, '0')}';

    final svg =
        '''
<svg width="$size" height="$size" viewBox="0 0 120 120" xmlns="http://www.w3.org/2000/svg">
  <circle cx="60" cy="60" r="56" fill="#EFE6D4" />
  <g fill="none" stroke-width="9" stroke-linecap="round">
    <path d="M30 30 90 90" stroke="$c1Hex" />
    <path d="M90 30 30 90" stroke="$c2Hex" />
    <path d="M60 22v76" stroke="$c3Hex" stroke-opacity="0.85" />
    <path d="M22 60h76" stroke="$c1Hex" stroke-opacity="0.5" />
  </g>
  <circle cx="60" cy="60" r="11" fill="$c2Hex" />
</svg>''';
    return SvgPicture.string(svg, width: size, height: size);
  }

  static Widget zelligeFaint() {
    return CustomPaint(
      painter: _ZelligePainter(),
      child: const SizedBox.expand(),
    );
  }
}

class _ZelligePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5247E6).withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const tileSize = 64;

    // Instead of full parsing, we can just draw the path manually
    // M32 2 L42 22 L62 32 L42 42 L32 62 L22 42 L2 32 L22 22 Z
    final tilePath = Path()
      ..moveTo(32, 2)
      ..lineTo(42, 22)
      ..lineTo(62, 32)
      ..lineTo(42, 42)
      ..lineTo(32, 62)
      ..lineTo(22, 42)
      ..lineTo(2, 32)
      ..lineTo(22, 22)
      ..close()
      ..addOval(Rect.fromCircle(center: const Offset(32, 32), radius: 9));

    for (double y = 0; y < size.height; y += tileSize) {
      for (double x = 0; x < size.width; x += tileSize) {
        canvas
          ..save()
          ..translate(x, y)
          ..drawPath(tilePath, paint)
          ..restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
