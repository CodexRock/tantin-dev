import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

class SegmentedOption<T> {
  const SegmentedOption({required this.value, required this.label, this.count});
  final T value;
  final String label;
  final String? count;
}

class Segmented<T> extends StatelessWidget {
  const Segmented({
    required this.options,
    required this.value,
    required this.onChange,
    super.key,
  });

  final List<SegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TantinColors.ivorySunken,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: options.map((option) {
          final active = option.value == value;
          return Expanded(
            child: Pressable(
              onPressed: () => onChange(option.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
                decoration: BoxDecoration(
                  color: active
                      ? TantinColors.ivorySurface
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: active ? TantinShadows.sm : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        color: active
                            ? TantinColors.ink
                            : TantinColors.inkMuted,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (option.count != null) ...[
                      const SizedBox(width: 5),
                      Opacity(
                        opacity: 0.5,
                        child: Text(
                          option.count!,
                          style: TextStyle(
                            color: active
                                ? TantinColors.ink
                                : TantinColors.inkMuted,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
