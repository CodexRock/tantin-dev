import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/icons/tn_icons.dart';

class BackBar extends StatelessWidget {
  const BackBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Pressable(
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: TantinColors.ivorySurface,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: TantinColors.hairline),
            ),
            alignment: Alignment.center,
            child: TnIcons.chevL(size: 22, color: TantinColors.ink),
          ),
        ),
      ),
    );
  }
}
