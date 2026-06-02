import 'package:flutter/material.dart';

abstract class TantinColors {
  static const Color ivoryBg = Color(0xFFF6EFE1);
  static const Color ivorySurface = Color(0xFFFFFDF7);
  static const Color ivorySunken = Color(0xFFEFE6D4);
  static const Color majorelle = Color(0xFF5247E6);
  static const Color majorelleDeep = Color(0xFF352DA8);
  static const Color majorelleSoft = Color(0xFFE7E5FB);
  static const Color saffron = Color(0xFFF5A623);
  static const Color saffronDeep = Color(0xFFE08A1E);
  static const Color terracotta = Color(0xFFC75B39);
  static const Color ink = Color(0xFF1E1B2E);
  static const Color inkMuted = Color(0xFF6B6478);
  static const Color success = Color(0xFF2E9E6B);
  static const Color warning = Color(0xFFF5A623);
  static const Color danger = Color(0xFFD2483F);
  static const Color hairline = Color(0x141E1B2E); // 8% opacity ink
}

abstract class TantinShadows {
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x0A352DA8),
      offset: Offset(0, 1),
      blurRadius: 2,
    ), // 4%
    BoxShadow(
      color: Color(0x0DC75B39),
      offset: Offset(0, 2),
      blurRadius: 6,
    ), // 5%
  ];

  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x0D1E1B2E),
      offset: Offset(0, 2),
      blurRadius: 6,
    ), // 5%
    BoxShadow(
      color: Color(0x145247E6),
      offset: Offset(0, 8),
      blurRadius: 22,
    ), // 8%
  ];

  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x141E1B2E),
      offset: Offset(0, 6),
      blurRadius: 18,
    ), // 8%
    BoxShadow(
      color: Color(0x245247E6),
      offset: Offset(0, 18),
      blurRadius: 48,
    ), // 14%
  ];

  static const List<BoxShadow> pop = [
    BoxShadow(
      color: Color(0x1F1E1B2E),
      offset: Offset(0, 10),
      blurRadius: 28,
    ), // 12%
    BoxShadow(
      color: Color(0x385247E6),
      offset: Offset(0, 26),
      blurRadius: 70,
    ), // 22%
  ];
}

abstract class TantinRadii {
  static const BorderRadius sm = BorderRadius.all(Radius.circular(8));
  static const BorderRadius md = BorderRadius.all(Radius.circular(12));
  static const BorderRadius lg = BorderRadius.all(Radius.circular(16));
  static const BorderRadius xl = BorderRadius.all(Radius.circular(24));
  static const BorderRadius round = BorderRadius.all(Radius.circular(999));
}

abstract class TantinMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 340);
  static const Duration slow = Duration(milliseconds: 600);

  static const Curve defaultCurve = Cubic(0.32, 0.72, 0, 1);
  static const Curve pressCurve = Cubic(0.34, 1.56, 0.64, 1);
  static const Curve revealCurve = Cubic(0.22, 1, 0.36, 1);
}
