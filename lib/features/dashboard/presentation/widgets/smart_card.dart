import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/darets/domain/daret_logic.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

/// The Accueil hero "smart card" — the most urgent next action, styled to the
/// prototype: majorelle gradient, corner zellige star, "à faire maintenant"
/// badge, big amount, échéance line, and the primary action + chevron buttons.
///
/// The primary action's real behaviour (declare-paid / receive) lands in S5;
/// for now both buttons navigate to the daret.
class SmartCard extends StatelessWidget {
  const SmartCard({
    required this.action,
    required this.daret,
    this.onPrimary,
    this.onOpen,
    super.key,
  });

  final DashboardNextAction action;
  final Daret? daret;
  final VoidCallback? onPrimary;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final isPay = action.type == DashboardActionType.payContribution;
    final badge = isPay ? 'À FAIRE MAINTENANT' : 'BIENTÔT';
    final lead = isPay ? 'Votre part pour ' : 'Vous recevez pour ';
    final name = daret?.nom ?? 'votre daret';
    final primaryLabel = isPay ? "J'ai payé ma part" : 'Voir le détail';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66352DA8),
            offset: Offset(0, 16),
            blurRadius: 40,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      TantinColors.majorelle,
                      TantinColors.majorelleDeep,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -30,
              right: -34,
              child: Opacity(
                opacity: 0.32,
                child: TnArt.starTile(
                  size: 150,
                  c1: const Color(0xFF6A5FF0),
                  c3: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _badge(badge),
                  const SizedBox(height: 14),
                  Text.rich(
                    TextSpan(
                      text: lead,
                      style: const TextStyle(
                        color: Color(0xD1FFFFFF),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      children: [
                        TextSpan(
                          text: name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    TantinFormat.fmtDH(action.amount),
                    style: const TextStyle(
                      fontFamily: 'Fraunces',
                      color: Colors.white,
                      fontSize: 44,
                      height: 1,
                      letterSpacing: -1.3,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      TnIcons.clock(size: 15, color: const Color(0xB3FFFFFF)),
                      const SizedBox(width: 7),
                      Text(
                        'Échéance le ${TantinDates.dayMonth(action.date)}',
                        style: const TextStyle(
                          color: Color(0xB3FFFFFF),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Pressable(
                          onPressed: onPrimary ?? onOpen,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: TantinColors.saffron,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x2E000000),
                                  offset: Offset(0, 6),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Text(
                              primaryLabel,
                              style: const TextStyle(
                                color: Color(0xFF2A1B05),
                                fontWeight: FontWeight.w700,
                                fontSize: 15.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Pressable(
                        onPressed: onOpen,
                        child: Container(
                          width: 52,
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0x29FFFFFF),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: TnIcons.chevR(size: 22, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0x38F5A623),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TnIcons.bolt(size: 14, color: const Color(0xFFF5C76A)),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFFFCDFA6),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
