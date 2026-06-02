import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

class Sheet extends StatelessWidget {
  const Sheet({
    required this.open,
    required this.onClose,
    required this.child,
    super.key,
    this.title,
  });

  final bool open;
  final VoidCallback onClose;
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: !open,
        child: Stack(
          children: [
            GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 320),
                color: open ? const Color(0x6B1E1B2E) : Colors.transparent,
                child: open
                    ? BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
                        child: const SizedBox.expand(),
                      )
                    : const SizedBox.expand(),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 420),
              curve: const Cubic(0.22, 1, 0.36, 1),
              left: 0,
              right: 0,
              bottom: open ? 0 : -MediaQuery.sizeOf(context).height,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.86,
                ),
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 10,
                  bottom: 20 + bottomPadding,
                ),
                decoration: const BoxDecoration(
                  color: TantinColors.ivorySurface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x331E1B2E),
                      offset: Offset(0, -10),
                      blurRadius: 40,
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(top: 4, bottom: 14),
                          decoration: BoxDecoration(
                            color: TantinColors.ivorySunken,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      if (title != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            title!,
                            style: Theme.of(context).textTheme.displayLarge
                                ?.copyWith(
                                  fontSize: 22,
                                  letterSpacing: -0.02 * 22,
                                  color: TantinColors.ink,
                                ),
                          ),
                        ),
                      child,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
