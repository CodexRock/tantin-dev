import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

/// Parses a `#RRGGBB` (or `RRGGBB`) hex string into a [Color].
///
/// Firestore stores daret/member palette colors as hex strings; the UI needs
/// real [Color]s. Falls back to the Majorelle brand color on a bad value.
Color hexToColor(String hex, {Color fallback = TantinColors.majorelle}) {
  var value = hex.replaceAll('#', '').trim();
  if (value.length == 6) value = 'FF$value';
  final parsed = int.tryParse(value, radix: 16);
  return parsed == null ? fallback : Color(parsed);
}
