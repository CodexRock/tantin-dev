import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/art/tn_art.dart';
import 'package:tantin_flutter/design_system/components/button.dart';

enum EmptyBlockArt { star, arch, weave }

class EmptyBlock extends StatelessWidget {
  const EmptyBlock({
    required this.title,
    required this.body,
    super.key,
    this.art = EmptyBlockArt.star,
    this.action,
    this.onAction,
  });

  final String title;
  final String body;
  final EmptyBlockArt art;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    Widget artWidget;
    switch (art) {
      case EmptyBlockArt.star:
        artWidget = TnArt.starTile(size: 100);
      case EmptyBlockArt.arch:
        artWidget = TnArt.archTile(size: 100);
      case EmptyBlockArt.weave:
        artWidget = TnArt.weaveTile(size: 100);
    }

    return Reveal(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 34),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: artWidget,
            ),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 19,
                letterSpacing: -0.02 * 19,
                color: TantinColors.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: TantinColors.inkMuted,
                height: 1.45,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              TnButton(
                onPressed: onAction,
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
