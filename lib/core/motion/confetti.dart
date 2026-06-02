import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';

class PayoutConfetti extends StatefulWidget {
  const PayoutConfetti({super.key});

  @override
  State<PayoutConfetti> createState() => _PayoutConfettiState();
}

class _PayoutConfettiState extends State<PayoutConfetti> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _controller.play();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topCenter,
      child: ConfettiWidget(
        confettiController: _controller,
        blastDirectionality: BlastDirectionality.explosive,
        colors: const [
          Color(0xFF5247E6), // majorelle
          Color(0xFFF5A623), // saffron
          Color(0xFFC75B39), // terracotta
          Color(0xFF2E9E6B), // success
        ],
        numberOfParticles: 50,
        emissionFrequency: 0.05,
      ),
    );
  }
}
