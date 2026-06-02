import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/icons/tn_icons.dart';

enum ToastType { success, info, warn }

class ToastData {
  const ToastData({required this.msg, required this.type});
  final String msg;
  final ToastType type;
}

class Toast extends StatelessWidget {
  const Toast({
    required this.toast,
    super.key,
  });

  final ToastData? toast;

  @override
  Widget build(BuildContext context) {
    if (toast == null) return const SizedBox.shrink();

    Color iconColor;
    switch (toast!.type) {
      case ToastType.success:
        iconColor = TantinColors.success;
      case ToastType.info:
        iconColor = TantinColors.majorelle;
      case ToastType.warn:
        iconColor = TantinColors.saffronDeep;
    }

    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 96 + bottomPadding,
      child: IgnorePointer(
        child: Center(
          child: Reveal(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: TantinColors.ink,
                borderRadius: BorderRadius.circular(16),
                boxShadow: TantinShadows.pop,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TnIcons.checkCircle(size: 19, color: iconColor),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      toast!.msg,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
