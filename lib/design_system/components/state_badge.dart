import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';

enum DaretState { apayer, attente, confirme, retard, recipient }

class StateBadgeData {
  const StateBadgeData({
    required this.label,
    required this.color,
    required this.bg,
    required this.dot,
  });
  final String label;
  final Color color;
  final Color bg;
  final Color dot;
}

abstract class StateMap {
  static final Map<DaretState, StateBadgeData> values = {
    DaretState.apayer: const StateBadgeData(
      label: 'À payer',
      color: TantinColors.inkMuted,
      bg: TantinColors.ivorySunken,
      dot: TantinColors.inkMuted,
    ),
    DaretState.attente: StateBadgeData(
      label: 'En attente',
      color: TantinColors.saffronDeep,
      bg: TantinColors.saffron.withValues(alpha: 0.14),
      dot: TantinColors.warning,
    ),
    DaretState.confirme: const StateBadgeData(
      label: 'Confirmé',
      color: TantinColors.success,
      bg: Color(0x1F2E9E6B), // rgba(46,158,107,0.12)
      dot: TantinColors.success,
    ),
    DaretState.retard: const StateBadgeData(
      label: 'En retard',
      color: TantinColors.danger,
      bg: Color(0x1FD2483F), // rgba(210,72,63,0.12)
      dot: TantinColors.danger,
    ),
    DaretState.recipient: const StateBadgeData(
      label: 'Bénéficiaire',
      color: TantinColors.majorelleDeep,
      bg: TantinColors.majorelleSoft,
      dot: TantinColors.majorelle,
    ),
  };
}

class StateBadge extends StatelessWidget {
  const StateBadge({
    required this.state,
    super.key,
    this.small = false,
  });

  final DaretState state;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final s = StateMap.values[state] ?? StateMap.values[DaretState.apayer]!;

    return Container(
      padding: small
          ? const EdgeInsets.symmetric(horizontal: 9, vertical: 3)
          : const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: s.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            s.label,
            style: TextStyle(
              color: s.color,
              fontWeight: FontWeight.w600,
              fontSize: small ? 12.0 : 13.0,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
