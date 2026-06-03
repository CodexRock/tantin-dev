import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/darets/presentation/widgets/daret_card.dart';
import 'package:tantin_flutter/features/shell/presentation/create_join_sheet.dart';

/// "Mes Darets" tab: segmented Actifs / En attente / Terminés over the user's
/// darets, each rendered as a [DaretCard]. Tapping a card opens the read-only
/// hub stub (the full hub is S5).
class MesDaretsScreen extends ConsumerStatefulWidget {
  const MesDaretsScreen({super.key});

  @override
  ConsumerState<MesDaretsScreen> createState() => _MesDaretsScreenState();
}

class _MesDaretsScreenState extends ConsumerState<MesDaretsScreen> {
  DaretStatus _seg = DaretStatus.actif;

  @override
  Widget build(BuildContext context) {
    final daretsAsync = ref.watch(myDaretsProvider());
    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        bottom: false,
        child: daretsAsync.when(
          loading: () => const _DaretsLoading(),
          error: (error, _) => Center(child: Text('Erreur : $error')),
          data: _content,
        ),
      ),
    );
  }

  Widget _content(List<Daret> darets) {
    final counts = <DaretStatus, int>{
      DaretStatus.actif: darets
          .where((d) => d.statut == DaretStatus.actif)
          .length,
      DaretStatus.attente: darets
          .where((d) => d.statut == DaretStatus.attente)
          .length,
      DaretStatus.termine: darets
          .where((d) => d.statut == DaretStatus.termine)
          .length,
    };
    final list = darets.where((d) => d.statut == _seg).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 120),
      children: [
        const ScreenHeader(
          title: 'Mes Darets',
          subtitle: "Vos cercles d'épargne",
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Segmented<DaretStatus>(
            value: _seg,
            onChange: (v) => setState(() => _seg = v),
            options: [
              SegmentedOption(
                value: DaretStatus.actif,
                label: 'Actifs',
                count: '${counts[DaretStatus.actif]}',
              ),
              SegmentedOption(
                value: DaretStatus.attente,
                label: 'En attente',
                count: '${counts[DaretStatus.attente]}',
              ),
              SegmentedOption(
                value: DaretStatus.termine,
                label: 'Terminés',
                count: '${counts[DaretStatus.termine]}',
              ),
            ],
          ),
        ),
        if (list.isEmpty)
          _empty()
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                for (final d in list) ...[
                  DaretCard(
                    daret: d,
                    onTap: () => context.push('/daret/${d.id}'),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _empty() {
    final title = switch (_seg) {
      DaretStatus.actif => 'Aucun daret actif',
      DaretStatus.attente => 'Rien en attente',
      DaretStatus.termine => 'Aucun daret terminé',
      DaretStatus.brouillon => 'Aucun brouillon',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      child: EmptyBlock(
        title: title,
        body:
            'Créez votre premier daret et invitez vos proches '
            'en toute confiance.',
        action: 'Créer un daret',
        onAction: () => showCreateJoinSheet(context),
      ),
    );
  }
}

class _DaretsLoading extends StatelessWidget {
  const _DaretsLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
      children: const [
        Skel(width: 160, height: 28),
        SizedBox(height: 20),
        Skel(height: 96, radius: 24),
        SizedBox(height: 14),
        Skel(height: 96, radius: 24),
      ],
    );
  }
}
