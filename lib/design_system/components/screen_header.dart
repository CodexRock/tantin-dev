import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/art/tn_art.dart';

class ScreenHeader extends StatelessWidget {
  const ScreenHeader({
    required this.title,
    super.key,
    this.subtitle,
    this.right,
    this.zellige = false,
  });

  final String title;
  final String? subtitle;
  final Widget? right;
  final bool zellige;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (zellige)
          Positioned.fill(
            child: TnArt.zelligeFaint(),
          ),
        Padding(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: 14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (subtitle != null) ...[
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: TantinColors.inkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 30,
                        letterSpacing: -0.025 * 30,
                        height: 1.05,
                        color: TantinColors.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.visible,
                      softWrap: false,
                    ),
                  ],
                ),
              ),
              if (right != null) ...[
                const SizedBox(width: 12),
                right!,
              ],
            ],
          ),
        ),
      ],
    );
  }
}
