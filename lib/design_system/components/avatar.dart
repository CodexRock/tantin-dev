import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

class AvatarData {
  const AvatarData({
    required this.initials,
    this.bgColor = TantinColors.majorelle,
    this.fgColor = TantinColors.majorelleSoft,
  });
  final String initials;
  final Color bgColor;
  final Color fgColor;
}

class Avatar extends StatelessWidget {
  const Avatar({
    required this.data,
    super.key,
    this.size = 44.0,
    this.ring = false,
  });

  final AvatarData data;
  final double size;
  final bool ring;

  Color _shade(Color color, double pct) {
    final r = (color.r * 255.0 + (255.0 * pct)).round().clamp(0, 255);
    final g = (color.g * 255.0 + (255.0 * pct)).round().clamp(0, 255);
    final b = (color.b * 255.0 + (255.0 * pct)).round().clamp(0, 255);
    return Color.fromRGBO(r, g, b, color.a);
  }

  @override
  Widget build(BuildContext context) {
    final bgDark = _shade(data.bgColor, -0.18);
    final fgR = data.fgColor.toARGB32().toRadixString(16);
    final fgHex = '#${fgR.substring(2).padLeft(6, '0')}';

    final Widget content = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight, // 140deg approx
          colors: [data.bgColor, bgDark],
          stops: const [0.0, 1.0],
        ),
        boxShadow: ring
            ? [
                const BoxShadow(
                  color: TantinColors.ivorySurface,
                  spreadRadius: 2.5,
                ),
                BoxShadow(
                  color: data.bgColor,
                  spreadRadius: 4,
                ),
              ]
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.22,
              child: SvgPicture.string(
                '<svg viewBox="0 0 44 44" xmlns="http://www.w3.org/2000/svg"><path d="M22 2l4 9 9-4-4 9 9 4-9 4 4 9-9-4-4 9-4-9-9 4 4-9-9-4 9-4-4-9 9 4 4-9Z" fill="$fgHex" /></svg>',
                fit: BoxFit.cover,
              ),
            ),
          ),
          Text(
            data.initials,
            style: TextStyle(
              color: Colors.white,
              fontFamily: Theme.of(context).textTheme.displayLarge?.fontFamily,
              fontWeight: FontWeight.w600,
              fontSize: size * 0.4,
            ),
          ),
        ],
      ),
    );

    return content;
  }
}

class AvatarStack extends StatelessWidget {
  const AvatarStack({
    required this.avatars,
    super.key,
    this.maxCount = 4,
    this.size = 30.0,
  });

  final List<AvatarData> avatars;
  final int maxCount;
  final double size;

  @override
  Widget build(BuildContext context) {
    final shown = avatars.take(maxCount).toList();
    final extra = avatars.length - shown.length;

    final overlap = size * 0.32;
    final step = size - overlap;

    final totalWidth = shown.isEmpty
        ? 0.0
        : size + (shown.length - 1) * step + (extra > 0 ? step : 0.0);

    return SizedBox(
      width: totalWidth,
      height: size,
      child: Stack(
        children: [
          for (int i = 0; i < shown.length; i++)
            Positioned(
              left: i * step,
              child: Avatar(
                data: shown[i],
                size: size,
                ring: true,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: shown.length * step,
              child: Container(
                width: size,
                height: size,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: TantinColors.ivorySunken,
                  boxShadow: [
                    BoxShadow(
                      color: TantinColors.ivorySurface,
                      spreadRadius: 2.5,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  r'+$extra',
                  style: TextStyle(
                    color: TantinColors.inkMuted,
                    fontSize: size * 0.34,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
