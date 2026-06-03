import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';

/// Read-only placeholder for a daret's hub. The full hub (members, periods,
/// confirmation, payout) is built in S5; for now tapping a daret card lands
/// here so navigation is wired end-to-end.
class DaretHubStubScreen extends ConsumerWidget {
  const DaretHubStubScreen({required this.daretId, super.key});

  final String daretId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daret = ref.watch(daretProvider(daretId)).valueOrNull;
    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      appBar: AppBar(
        backgroundColor: TantinColors.ivoryBg,
        elevation: 0,
        leading: const BackButton(color: TantinColors.ink),
        title: Text(
          daret?.nom ?? 'Daret',
          style: const TextStyle(
            color: TantinColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: EmptyBlock(
            title: 'Détails du daret',
            body:
                'Le hub complet (membres, tours, confirmation) '
                'arrive au sprint S5.',
          ),
        ),
      ),
    );
  }
}
