import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

enum ButtonVariant { primary, saffron, soft, ghost, danger, dark }

enum ButtonSize { sm, md, lg }

class TnButton extends StatelessWidget {
  const TnButton({
    required this.child,
    super.key,
    this.onPressed,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.md,
    this.icon,
    this.iconRight,
    this.full = false,
    this.disabled = false,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final ButtonSize size;
  final Widget? icon;
  final Widget? iconRight;
  final bool full;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    EdgeInsetsGeometry padding;
    double fontSize;
    switch (size) {
      case ButtonSize.sm:
        padding = const EdgeInsets.symmetric(vertical: 9, horizontal: 14);
        fontSize = 14.0;
      case ButtonSize.md:
        padding = const EdgeInsets.symmetric(vertical: 13, horizontal: 18);
        fontSize = 15.5;
      case ButtonSize.lg:
        padding = const EdgeInsets.symmetric(vertical: 16, horizontal: 22);
        fontSize = 17.0;
    }

    Color bgColor;
    Color fgColor;
    List<BoxShadow>? boxShadow;
    Border? border;

    switch (variant) {
      case ButtonVariant.primary:
        bgColor = TantinColors.majorelle;
        fgColor = Colors.white;
        boxShadow = [
          BoxShadow(
            color: TantinColors.majorelle.withValues(alpha: 0.32),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ];
      case ButtonVariant.saffron:
        bgColor = TantinColors.saffron;
        fgColor = const Color(0xFF2A1B05);
        boxShadow = [
          BoxShadow(
            color: TantinColors.saffron.withValues(alpha: 0.34),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ];
      case ButtonVariant.soft:
        bgColor = TantinColors.majorelleSoft;
        fgColor = TantinColors.majorelleDeep;
      case ButtonVariant.ghost:
        bgColor = Colors.transparent;
        fgColor = TantinColors.ink;
        border = Border.all(color: TantinColors.hairline, width: 1.5);
      case ButtonVariant.danger:
        bgColor = TantinColors.danger.withValues(alpha: 0.1);
        fgColor = TantinColors.danger;
      case ButtonVariant.dark:
        bgColor = TantinColors.ink;
        fgColor = Colors.white;
    }

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: boxShadow,
        border: border,
      ),
      child: Row(
        mainAxisSize: full ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            IconTheme(
              data: IconThemeData(color: fgColor, size: fontSize * 1.2),
              child: Transform.translate(
                offset: const Offset(-2, 0),
                child: icon,
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                color: fgColor,
                fontWeight: FontWeight.w600,
                fontSize: fontSize,
                letterSpacing: -0.01 * fontSize,
              ),
              child: child,
            ),
          ),
          if (iconRight != null) ...[
            const SizedBox(width: 8),
            IconTheme(
              data: IconThemeData(color: fgColor, size: fontSize * 1.2),
              child: Transform.translate(
                offset: const Offset(2, 0),
                child: iconRight,
              ),
            ),
          ],
        ],
      ),
    );

    if (disabled) {
      content = Opacity(
        opacity: 0.4,
        child: content,
      );
    } else {
      content = Pressable(
        onPressed: onPressed,
        child: content,
      );
    }

    if (full) {
      return SizedBox(width: double.infinity, child: content);
    }
    return content;
  }
}
