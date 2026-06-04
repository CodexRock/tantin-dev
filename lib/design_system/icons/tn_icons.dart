import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class _SvgIcon extends StatelessWidget {
  const _SvgIcon({
    required this.content,
    required this.size,
    required this.strokeWidth,
    this.color,
    this.fill = 'none',
  });
  final String content;
  final double size;
  final Color? color;
  final double strokeWidth;
  final String fill;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? IconTheme.of(context).color ?? Colors.black;
    final r = (effectiveColor.r * 255.0).round().clamp(0, 255);
    final g = (effectiveColor.g * 255.0).round().clamp(0, 255);
    final b = (effectiveColor.b * 255.0).round().clamp(0, 255);
    final rgba = 'rgba($r,$g,$b,${effectiveColor.a})';

    final processedContent = content.replaceAll('currentColor', rgba);
    final processedFill = fill == 'currentColor' ? rgba : fill;

    final svg =
        '''
<svg width="$size" height="$size" viewBox="0 0 24 24" fill="$processedFill" xmlns="http://www.w3.org/2000/svg" stroke="$rgba" stroke-width="$strokeWidth" stroke-linecap="round" stroke-linejoin="round">
  $processedContent
</svg>''';

    return SvgPicture.string(svg, width: size, height: size);
  }
}

abstract class TnIcons {
  static Widget home({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M3 10.5 12 3l9 7.5M5 9.5V20a1 1 0 0 0 1 1h4v-6h4v6h4a1 1 0 0 0 1-1V9.5" />',
  );

  static Widget stack({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M12 3 3 8l9 5 9-5-9-5ZM3 13l9 5 9-5M3 17.5l9 5 9-5" />',
  );

  static Widget calendar({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M7 3v3M17 3v3M4 8h16M5 6h14a1 1 0 0 1 1 1v12a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1Z" />',
  );

  static Widget activity({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M3 12h4l2 6 4-14 2 8h6" />',
  );

  static Widget user({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M12 12a4 4 0 1 0 0-8 4 4 0 0 0 0 8ZM4 21c0-3.5 3.6-6 8-6s8 2.5 8 6" />',
  );

  static Widget bell({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M6 9a6 6 0 1 1 12 0c0 4 1.2 5.5 2 6.5H4c.8-1 2-2.5 2-6.5ZM9.5 19a2.5 2.5 0 0 0 5 0" />',
  );

  static Widget plus({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M12 5v14M5 12h14" />',
  );

  static Widget minus({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M5 12h14" />',
  );

  static Widget chevR({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M9 5l7 7-7 7" />',
  );

  static Widget chevL({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M15 5l-7 7 7 7" />',
  );

  static Widget chevDown({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M5 9l7 7 7-7" />',
  );

  static Widget check({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M5 12.5 10 17 19 7" />',
  );

  static Widget checkCircle({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<circle cx="12" cy="12" r="9" /><path d="M8 12.2 11 15l5-6" />',
  );

  static Widget clock({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<circle cx="12" cy="12" r="9" /><path d="M12 7v5l3 2" />',
  );

  static Widget close({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M6 6l12 12M18 6 6 18" />',
  );

  static Widget search({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<circle cx="11" cy="11" r="7" /><path d="m20 20-3.5-3.5" />',
  );

  static Widget arrowUp({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M12 19V5M6 11l6-6 6 6" />',
  );

  static Widget arrowDown({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M12 5v14M6 13l6 6 6-6" />',
  );

  static Widget gift({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M20 12v8a1 1 0 0 1-1 1H5a1 1 0 0 1-1-1v-8M3 8h18v4H3zM12 8v13M12 8S10.5 3 8 3a2.5 2.5 0 0 0 0 5M12 8s1.5-5 4-5a2.5 2.5 0 0 1 0 5" />',
  );

  static Widget users({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M9 12a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7ZM2.5 20c0-3 2.9-5 6.5-5s6.5 2 6.5 5M16 5.2A3.5 3.5 0 0 1 16 12M18 15.2c2 .6 3.5 2 3.5 4" />',
  );

  static Widget send({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M22 2 11 13M22 2 15 22l-4-9-9-4 20-7Z" />',
  );

  static Widget sparkle({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M12 3l1.8 5.2L19 10l-5.2 1.8L12 17l-1.8-5.2L5 10l5.2-1.8L12 3ZM19 15l.8 2.2L22 18l-2.2.8L19 21l-.8-2.2L16 18l2.2-.8L19 15Z" />',
  );

  static Widget edit({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M4 20h4L19 9a2 2 0 0 0-3-3L5 17v3ZM14 7l3 3" />',
  );

  static Widget trash({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M4 7h16M9 7V5a1 1 0 0 1 1-1h4a1 1 0 0 1 1 1v2M6 7l1 13a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1l1-13M10 11v6M14 11v6" />',
  );

  static Widget settings({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<circle cx="12" cy="12" r="3" /><path d="M12 2v3M12 19v3M4.2 4.2l2.1 2.1M17.7 17.7l2.1 2.1M2 12h3M19 12h3M4.2 19.8l2.1-2.1M17.7 6.3l2.1-2.1" />',
  );

  static Widget bolt({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<path d="M13 2 4 14h6l-1 8 9-12h-6l1-8Z" />',
  );

  static Widget phone({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M5 4h4l2 5-2.5 1.5a11 11 0 0 0 5 5L20 13l5 2v4a2 2 0 0 1-2 2A17 17 0 0 1 3 6a2 2 0 0 1 2-2Z" />',
  );

  static Widget link({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M9 15l6-6M10.5 6.5 12 5a4 4 0 0 1 6 6l-1.5 1.5M13.5 17.5 12 19a4 4 0 0 1-6-6l1.5-1.5" />',
  );

  static Widget share({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<circle cx="6" cy="12" r="2.5" /><circle cx="18" cy="6" r="2.5" /><circle cx="18" cy="18" r="2.5" /><path d="M8.2 10.8 15.8 7.2M8.2 13.2l7.6 3.6" />',
  );

  static Widget camera({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M4 8h3l1.5-2h7L17 8h3a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V9a1 1 0 0 1 1-1Z" /><circle cx="12" cy="13" r="3.5" />',
  );

  static Widget info({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content: '<circle cx="12" cy="12" r="9" /><path d="M12 11v5M12 8h.01" />',
  );

  static Widget logout({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M15 4h3a1 1 0 0 1 1 1v14a1 1 0 0 1-1 1h-3M10 12h9M16 9l3 3-3 3" />',
  );

  static Widget globe({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<circle cx="12" cy="12" r="9" /><path d="M3 12h18M12 3c2.5 2.5 2.5 15 0 18M12 3c-2.5 2.5-2.5 15 0 18" />',
  );

  static Widget help({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<circle cx="12" cy="12" r="9" /><path d="M9.5 9.5a2.5 2.5 0 1 1 3.5 2.3c-.8.4-1 .8-1 1.7M12 16.5h.01" />',
  );

  static Widget shield({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M12 3l7 2.5V11c0 4.5-3 7.8-7 9-4-1.2-7-4.5-7-9V5.5L12 3Z" />',
  );

  static Widget grip({
    double size = 24,
    Color? color,
    double strokeWidth = 0,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    fill: 'currentColor',
    content:
        '<g fill="currentColor"><circle cx="9" cy="8" r="1.4" /><circle cx="15" cy="8" r="1.4" /><circle cx="9" cy="12" r="1.4" /><circle cx="15" cy="12" r="1.4" /><circle cx="9" cy="16" r="1.4" /><circle cx="15" cy="16" r="1.4" /></g>',
  );

  static Widget dice({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<rect x="4" y="4" width="16" height="16" rx="4" /><circle cx="9" cy="9" r="1.2" fill="currentColor" stroke="none" /><circle cx="15" cy="15" r="1.2" fill="currentColor" stroke="none" /><circle cx="12" cy="12" r="1.2" fill="currentColor" stroke="none" />',
  );

  static Widget wand({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M15 4l1 2 2 1-2 1-1 2-1-2-2-1 2-1 1-2ZM5 19l8-8M11 9l2 2" />',
  );

  static Widget qr({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<rect x="4" y="4" width="6" height="6" rx="1" /><rect x="14" y="4" width="6" height="6" rx="1" /><rect x="4" y="14" width="6" height="6" rx="1" /><path d="M14 14h3v3M20 14v6M17 20h3" />',
  );

  static Widget copy({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<rect x="8" y="8" width="12" height="12" rx="2" /><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2" />',
  );

  static Widget contacts({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<rect x="4" y="3" width="16" height="18" rx="2" /><circle cx="12" cy="10" r="2.5" /><path d="M8.5 16c.6-1.6 2-2.5 3.5-2.5s2.9.9 3.5 2.5M2 7h2M2 12h2M2 17h2" />',
  );

  static Widget star8({
    double size = 24,
    Color? color,
    double strokeWidth = 1.7,
  }) => _SvgIcon(
    size: size,
    color: color,
    strokeWidth: strokeWidth,
    content:
        '<path d="M12 2l2.2 5.1L19.8 5 17 10.2 22 12l-5 1.8 2.8 5.2-5.6-2.1L12 22l-2.2-5.1L4.2 19 7 13.8 2 12l5-1.8L4.2 5l5.6 2.1L12 2Z" />',
  );
}
