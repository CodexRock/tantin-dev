import 'dart:async';
import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

class Skel extends StatefulWidget {
  const Skel({
    super.key,
    this.width = double.infinity,
    this.height = 14.0,
    this.radius = 10.0,
  });

  final double width;
  final double height;
  final double radius;

  @override
  State<Skel> createState() => _SkelState();
}

class _SkelState extends State<Skel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: TantinColors.ivorySunken,
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final stops = [
          _controller.value - 1.0,
          _controller.value - 0.5,
          _controller.value,
        ];
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              colors: const [
                TantinColors.ivorySunken,
                Color(0xB3FFFDF7),
                TantinColors.ivorySunken,
              ],
              stops: stops,
            ),
          ),
        );
      },
    );
  }
}
