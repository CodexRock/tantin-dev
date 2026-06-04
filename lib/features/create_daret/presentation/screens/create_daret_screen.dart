import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:tantin_flutter/core/format/date_format.dart';
import 'package:tantin_flutter/core/format/format.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/router/router.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/create_daret/data/create_daret_providers.dart';
import 'package:tantin_flutter/features/create_daret/domain/create_daret_models.dart';
import 'package:tantin_flutter/features/create_daret/presentation/create_daret_controller.dart';
import 'package:tantin_flutter/features/darets/data/daret_callable_providers.dart';
import 'package:tantin_flutter/features/darets/data/daret_providers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/profile/data/user_providers.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

class CreateDaretScreen extends ConsumerStatefulWidget {
  const CreateDaretScreen({super.key});

  @override
  ConsumerState<CreateDaretScreen> createState() => _CreateDaretScreenState();
}

class _CreateDaretScreenState extends ConsumerState<CreateDaretScreen> {
  List<Contact> _contacts = const <Contact>[];
  String? _contactsError;
  bool _loadingContacts = false;

  @override
  Widget build(BuildContext context) {
    final appUser = ref.watch(currentAppUserProvider).valueOrNull;
    final state = ref.watch(createDaretControllerProvider);
    final controller = ref.read(createDaretControllerProvider.notifier);

    if (appUser != null && !state.hasCurrentUser) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(createDaretControllerProvider.notifier)
            .ensureCurrentUser(
              appUser,
            );
      });
    }

    if (appUser == null) {
      return const Scaffold(
        backgroundColor: TantinColors.ivoryBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final dates = controller.generatedDates(appUser);
    final title = switch (state.step) {
      1 => 'Identité',
      2 => 'Argent & rythme',
      3 => 'Membres',
      4 => 'Ordre & périodes',
      _ => 'Récapitulatif',
    };

    return Scaffold(
      backgroundColor: TantinColors.ivoryBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WizardHeader(
              step: state.step,
              title: title,
              onBack: state.step == 1 ? () => context.pop() : controller.back,
              onClose: () => context.pop(),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                child: KeyedSubtree(
                  key: ValueKey(state.step),
                  child: switch (state.step) {
                    1 => _IdentityStep(state: state, controller: controller),
                    2 => _MoneyStep(
                      state: state,
                      controller: controller,
                      dates: dates,
                    ),
                    3 => _MembersStep(
                      state: state,
                      controller: controller,
                      options: _memberOptions(ref, appUser.uid),
                      contacts: _contacts,
                      contactsError: _contactsError,
                      loadingContacts: _loadingContacts,
                      onLoadContacts: _loadContacts,
                    ),
                    4 => _OrderStep(
                      state: state,
                      controller: controller,
                      dates: dates,
                    ),
                    _ => _RecapStep(
                      state: state,
                      controller: controller,
                      dates: dates,
                    ),
                  },
                ),
              ),
            ),
            _WizardFooter(
              state: state,
              canContinue: controller.canGoNext,
              onContinue: () => _continue(appUser),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continue(AppUser appUser) async {
    final controller = ref.read(createDaretControllerProvider.notifier);
    final state = ref.read(createDaretControllerProvider);
    if (state.step < 5) {
      controller.next();
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await controller.submit(
        creator: appUser,
        repository: ref.read(createDaretRepositoryProvider),
        callables: ref.read(daretCallableRepositoryProvider),
      );
      if (!mounted) return;
      context.go(
        '${AppRoutes.approval}/${result.daretId}?code=${Uri.encodeComponent(result.inviteCode)}',
      );
    } on Object catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Création impossible : $error')),
      );
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _loadingContacts = true;
      _contactsError = null;
    });
    try {
      final allowed = await FlutterContacts.permissions.request(
        PermissionType.read,
      );
      if (allowed != PermissionStatus.granted &&
          allowed != PermissionStatus.limited) {
        setState(() {
          _contactsError = 'Accès aux contacts refusé.';
          _loadingContacts = false;
        });
        return;
      }
      final contacts = await FlutterContacts.getAll(limit: 20);
      setState(() {
        _contacts = contacts;
        _loadingContacts = false;
      });
    } on Object catch (error) {
      setState(() {
        _contactsError = error.toString();
        _loadingContacts = false;
      });
    }
  }
}

List<CreateParticipant> _memberOptions(WidgetRef ref, String currentUid) {
  final darets = ref.watch(myDaretsProvider).valueOrNull ?? const <Daret>[];
  final options = <String, CreateParticipant>{};
  for (final daret in darets) {
    final members =
        ref.watch(daretMembersProvider(daret.id)).valueOrNull ??
        const <DaretMember>[];
    for (final member in members) {
      if (member.uid == currentUid) continue;
      options.putIfAbsent(
        member.uid,
        () => CreateParticipant(
          uid: member.uid,
          name: member.name,
          prenom: member.prenom,
          initials: member.initials,
          avatarPalette: member.avatarPalette,
          kind: CreateParticipantKind.previous,
        ),
      );
    }
  }
  if (options.isNotEmpty) return options.values.toList(growable: false);
  return _seedMemberOptions;
}

const _seedMemberOptions = <CreateParticipant>[
  CreateParticipant(
    uid: 'seed-person-01',
    name: 'Karim Tazi',
    prenom: 'Karim',
    initials: 'KT',
    avatarPalette: ['#5247E6', '#E7E5FB'],
    kind: CreateParticipantKind.app,
  ),
  CreateParticipant(
    uid: 'seed-person-02',
    name: 'Salma Idrissi',
    prenom: 'Salma',
    initials: 'SI',
    avatarPalette: ['#F5A623', '#FBEFD6'],
    kind: CreateParticipantKind.app,
  ),
  CreateParticipant(
    uid: 'seed-person-04',
    name: 'Nadia Bennani',
    prenom: 'Nadia',
    initials: 'NB',
    avatarPalette: ['#2E9E6B', '#DCF0E6'],
    kind: CreateParticipantKind.app,
  ),
  CreateParticipant(
    uid: 'seed-person-06',
    name: 'Aïcha Fassi',
    prenom: 'Aïcha',
    initials: 'AF',
    avatarPalette: ['#D2483F', '#F8DAD7'],
    kind: CreateParticipantKind.app,
  ),
  CreateParticipant(
    uid: 'seed-person-07',
    name: 'Reda Lahlou',
    prenom: 'Reda',
    initials: 'RL',
    avatarPalette: ['#5247E6', '#E7E5FB'],
    kind: CreateParticipantKind.app,
  ),
];

class _WizardHeader extends StatelessWidget {
  const _WizardHeader({
    required this.step,
    required this.title,
    required this.onBack,
    required this.onClose,
  });

  final int step;
  final String title;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      child: Column(
        children: [
          Row(
            children: [
              _IconButton(
                icon: TnIcons.chevL(size: 21, color: TantinColors.ink),
                onPressed: onBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Étape $step sur 5',
                      style: const TextStyle(
                        fontSize: 12,
                        color: TantinColors.inkMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontSize: 20,
                        letterSpacing: -0.4,
                        color: TantinColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onClose,
                child: const Text('Quitter'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 1; i <= 5; i += 1) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= step
                          ? TantinColors.majorelle
                          : TantinColors.ivorySunken,
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
                if (i < 5) const SizedBox(width: 5),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.state,
    required this.canContinue,
    required this.onContinue,
  });

  final CreateDaretState state;
  final bool canContinue;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final label = switch (state.step) {
      4 when !canContinue => 'Placez tous les membres',
      5 => 'Envoyer pour approbation',
      _ => 'Continuer',
    };
    return Container(
      padding: EdgeInsets.fromLTRB(22, 12, 22, 18 + bottom),
      decoration: const BoxDecoration(
        color: TantinColors.ivorySurface,
        border: Border(top: BorderSide(color: TantinColors.hairline)),
      ),
      child: TnButton(
        full: true,
        size: ButtonSize.lg,
        disabled: !canContinue || state.isSubmitting,
        variant: state.step == 5
            ? ButtonVariant.saffron
            : ButtonVariant.primary,
        onPressed: canContinue ? onContinue : null,
        iconRight: state.step == 5
            ? TnIcons.send(size: 19)
            : TnIcons.chevR(size: 20),
        child: Text(state.isSubmitting ? 'Création…' : label),
      ),
    );
  }
}

class _IdentityStep extends StatelessWidget {
  const _IdentityStep({required this.state, required this.controller});

  final CreateDaretState state;
  final CreateDaretController controller;

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(state.accent);
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        Center(
          child: Container(
            width: 90,
            height: 90,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(28),
              boxShadow: TantinShadows.md,
            ),
            child: Text(state.cover, style: const TextStyle(fontSize: 46)),
          ),
        ),
        const SizedBox(height: 18),
        const _Label('Nom du daret'),
        TextFormField(
          initialValue: state.nom,
          autofocus: true,
          onChanged: controller.setNom,
          decoration: _inputDecoration('ex. Daret Famille'),
        ),
        const SizedBox(height: 20),
        const _Label('Choisissez une couverture'),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
          ),
          itemCount: CreateDaretLogic.covers.length,
          itemBuilder: (context, index) {
            final cover = CreateDaretLogic.covers[index];
            final selected = cover == state.cover;
            return Pressable(
              onPressed: () => controller.setCover(cover),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: selected
                      ? accent.withValues(alpha: 0.14)
                      : TantinColors.ivorySurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selected ? accent : TantinColors.hairline,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Center(
                  child: Text(cover, style: const TextStyle(fontSize: 26)),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        const _Label('Couleur d’accent'),
        Row(
          children: [
            for (final value in CreateDaretLogic.accents) ...[
              _ColorSwatch(
                value: value,
                selected: value == state.accent,
                onPressed: () => controller.setAccent(value),
              ),
              const SizedBox(width: 12),
            ],
          ],
        ),
      ],
    );
  }
}

class _MoneyStep extends StatelessWidget {
  const _MoneyStep({
    required this.state,
    required this.controller,
    required this.dates,
  });

  final CreateDaretState state;
  final CreateDaretController controller;
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        const _Label('Montant par période'),
        DecoratedBox(
          decoration: BoxDecoration(
            color: TantinColors.ivorySurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: TantinColors.hairline, width: 1.5),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: TantinFormat.fmtNum(state.montant),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (value) {
                    controller.setMontant(int.tryParse(value) ?? 0);
                  },
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 30,
                    color: TantinColors.ink,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Text(
                  'DH',
                  style: TextStyle(
                    fontSize: 18,
                    color: TantinColors.inkMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const _Label('Fréquence'),
        Segmented<DaretFrequency>(
          value: state.frequence,
          onChange: controller.setFrequence,
          options: const [
            SegmentedOption(value: DaretFrequency.mensuel, label: 'Mensuel'),
            SegmentedOption(
              value: DaretFrequency.hebdomadaire,
              label: 'Hebdomadaire',
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _Label('Nombre de périodes'),
        _Stepper(
          value: state.periodesCount,
          unit: state.frequence == DaretFrequency.mensuel ? 'mois' : 'semaines',
          onMinus: () => controller.setPeriodesCount(state.periodesCount - 1),
          onPlus: () => controller.setPeriodesCount(state.periodesCount + 1),
        ),
        const SizedBox(height: 22),
        _CalcCard(state: state, dates: dates),
      ],
    );
  }
}

class _MembersStep extends StatefulWidget {
  const _MembersStep({
    required this.state,
    required this.controller,
    required this.options,
    required this.contacts,
    required this.loadingContacts,
    required this.onLoadContacts,
    this.contactsError,
  });

  final CreateDaretState state;
  final CreateDaretController controller;
  final List<CreateParticipant> options;
  final List<Contact> contacts;
  final bool loadingContacts;
  final VoidCallback onLoadContacts;
  final String? contactsError;

  @override
  State<_MembersStep> createState() => _MembersStepState();
}

class _MembersStepState extends State<_MembersStep> {
  var _source = 'amis';
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final participants = widget.state.participants;
    final selected = participants.map((item) => item.uid).toSet();
    final avatars = participants
        .map(
          (participant) => AvatarData(
            initials: participant.initials,
            bgColor: participant.avatarColor,
          ),
        )
        .toList();
    final enough = participants.length >= widget.state.periodesCount;
    final memberLabel =
        '${participants.length} membre${participants.length > 1 ? 's' : ''}';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 0),
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: TantinColors.ivorySurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: TantinColors.hairline),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      AvatarStack(avatars: avatars, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          memberLabel,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        enough
                            ? 'suffisant'
                            : 'min. ${widget.state.periodesCount}',
                        style: TextStyle(
                          fontSize: 13,
                          color: enough
                              ? TantinColors.success
                              : TantinColors.saffronDeep,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _SearchField(
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              Segmented<String>(
                value: _source,
                onChange: (value) => setState(() => _source = value),
                options: const [
                  SegmentedOption(value: 'amis', label: 'Amis'),
                  SegmentedOption(value: 'precedents', label: 'Précédents'),
                  SegmentedOption(value: 'contacts', label: 'Contacts'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
            children: [
              if (_source == 'contacts') ..._contactRows(),
              if (_source != 'contacts')
                for (final option in _filteredOptions())
                  _MemberRow(
                    participant: option,
                    selected: selected.contains(option.uid),
                    onTap: () => widget.controller.toggleParticipant(option),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  Iterable<CreateParticipant> _filteredOptions() {
    final query = _query.trim().toLowerCase();
    return widget.options.where((option) {
      if (query.isEmpty) return true;
      return option.name.toLowerCase().contains(query);
    });
  }

  List<Widget> _contactRows() {
    if (widget.loadingContacts) {
      return const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (widget.contacts.isEmpty) {
      return [
        TnCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Invitations en attente',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (widget.contactsError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    widget.contactsError!,
                    style: const TextStyle(color: TantinColors.danger),
                  ),
                ],
                const SizedBox(height: 12),
                TnButton(
                  full: true,
                  variant: ButtonVariant.soft,
                  icon: TnIcons.contacts(size: 18),
                  onPressed: widget.onLoadContacts,
                  child: const Text('Charger les contacts'),
                ),
                const SizedBox(height: 10),
                TnButton(
                  full: true,
                  variant: ButtonVariant.ghost,
                  icon: TnIcons.plus(size: 18),
                  onPressed: () => widget.controller.addPendingInvite(),
                  child: const Text('Ajouter une invitation'),
                ),
              ],
            ),
          ),
        ),
      ];
    }
    final query = _query.trim().toLowerCase();
    return widget.contacts
        .where((contact) {
          final name = contact.displayName ?? '';
          if (query.isEmpty) return true;
          return name.toLowerCase().contains(query);
        })
        .map((contact) {
          final name = contact.displayName ?? 'Contact';
          return _ContactRow(
            name: name,
            onTap: () => widget.controller.addPendingInvite(
              displayName: name,
            ),
          );
        })
        .toList(growable: false);
  }
}

class _OrderStep extends StatelessWidget {
  const _OrderStep({
    required this.state,
    required this.controller,
    required this.dates,
  });

  final CreateDaretState state;
  final CreateDaretController controller;
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    final placed = state.slots.expand((slot) => slot.recipientUids).toSet();
    final tray = state.participants
        .where((participant) => !placed.contains(participant.uid))
        .toList(growable: false);
    final validation = CreateDaretLogic.validateAssignment(
      state.participants,
      state.slots,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 2, 22, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Glissez chaque membre sur une période. '
                'Deux membres ou plus créent un groupe.',
                style: TextStyle(
                  fontSize: 14,
                  color: TantinColors.inkMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _ChipButton(
                    icon: TnIcons.wand(size: 16, color: TantinColors.majorelle),
                    label: 'Auto-organiser',
                    onPressed: controller.autoOrganize,
                  ),
                  const SizedBox(width: 9),
                  _ChipButton(
                    icon: TnIcons.dice(
                      size: 16,
                      color: TantinColors.saffronDeep,
                    ),
                    label: 'Tirage au sort',
                    onPressed: controller.tirageAuSort,
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(22, 6, 22, 12),
            itemCount: state.slots.length,
            itemBuilder: (context, index) {
              final slot = state.slots[index];
              return _PeriodSlot(
                slot: slot,
                date: dates[index],
                potAmount: state.payoutParPeriode,
                participants: state.participants,
                onDrop: (uid) => controller.placeParticipant(uid, index),
                onRemove: controller.removeFromSlot,
                onEditGroup: slot.isGroup
                    ? () => _showGroupEditor(context, index)
                    : null,
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 10),
          decoration: const BoxDecoration(
            color: TantinColors.ivorySurface,
            border: Border(top: BorderSide(color: TantinColors.hairline)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Text(
                    'À placer',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: TantinColors.inkMuted,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    tray.isEmpty
                        ? 'Tous placés'
                        : '${tray.length} restant${tray.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: tray.isEmpty
                          ? TantinColors.success
                          : TantinColors.inkMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              SizedBox(
                height: 66,
                child: tray.isEmpty
                    ? Row(
                        children: [
                          TnIcons.checkCircle(
                            size: 18,
                            color: TantinColors.success,
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'Chaque membre a sa période',
                            style: TextStyle(
                              color: TantinColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: tray.length,
                        separatorBuilder: (context, index) {
                          return const SizedBox(width: 12);
                        },
                        itemBuilder: (context, index) {
                          return _DraggableParticipant(
                            participant: tray[index],
                          );
                        },
                      ),
              ),
              if (!validation.valid)
                Text(
                  validation.message,
                  style: const TextStyle(
                    color: TantinColors.saffronDeep,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showGroupEditor(BuildContext context, int index) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer(
          builder: (context, ref, child) {
            final currentState = ref.watch(createDaretControllerProvider);
            final currentController = ref.read(
              createDaretControllerProvider.notifier,
            );
            final slot = currentState.slots[index];
            return _GroupEditorSheet(
              slot: slot,
              participants: currentState.participants,
              potAmount: currentState.payoutParPeriode,
              onShareChanged: (uid, value) => currentController.setGroupShare(
                slotIndex: index,
                uid: uid,
                value: value,
              ),
            );
          },
        );
      },
    );
  }
}

class _RecapStep extends StatelessWidget {
  const _RecapStep({
    required this.state,
    required this.controller,
    required this.dates,
  });

  final CreateDaretState state;
  final CreateDaretController controller;
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    final accent = hexToColor(state.accent);
    final groups = state.slots.where((slot) => slot.isGroup).length;
    final subtitle =
        '${TantinFormat.fmtDH(state.montant)} · '
        '${state.frequence.firestoreValue} · '
        '${state.periodesCount} tours';
    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
      children: [
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(state.cover, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.nom.trim().isEmpty ? 'Daret' : state.nom.trim(),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 23,
                      letterSpacing: -0.46,
                      color: TantinColors.ink,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: TantinColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            _RecapStat(
              label: 'Cagnotte / tour',
              value: TantinFormat.fmtDH(state.cagnotteParPeriode),
            ),
            const SizedBox(width: 10),
            _RecapStat(label: 'Membres', value: '${state.participants.length}'),
            if (groups > 0) ...[
              const SizedBox(width: 10),
              _RecapStat(label: 'Groupes', value: '$groups'),
            ],
          ],
        ),
        const SizedBox(height: 18),
        const _Label('Ordre des tours'),
        TnCard(
          child: Column(
            children: [
              for (var i = 0; i < state.slots.length; i += 1)
                _RecapPeriodRow(
                  slot: state.slots[i],
                  date: dates[i],
                  participants: state.participants,
                  last: i == state.slots.length - 1,
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            color: TantinColors.ivorySunken,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                TnIcons.shield(color: TantinColors.inkMuted),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chaque membre devra approuver le daret, l’ordre et '
                    'le calendrier avant le démarrage.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: TantinColors.inkMuted,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (state.submitError != null) ...[
          const SizedBox(height: 12),
          Text(
            state.submitError!,
            style: const TextStyle(color: TantinColors.danger),
          ),
        ],
      ],
    );
  }
}

class _PeriodSlot extends StatelessWidget {
  const _PeriodSlot({
    required this.slot,
    required this.date,
    required this.potAmount,
    required this.participants,
    required this.onDrop,
    required this.onRemove,
    this.onEditGroup,
  });

  final AssignmentSlot slot;
  final DateTime date;
  final int potAmount;
  final List<CreateParticipant> participants;
  final ValueChanged<String> onDrop;
  final ValueChanged<String> onRemove;
  final VoidCallback? onEditGroup;

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final hovering = candidateData.isNotEmpty;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              SizedBox(
                width: 36,
                child: Center(
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: slot.isEmpty
                          ? TantinColors.ivorySurface
                          : TantinColors.majorelle,
                      borderRadius: BorderRadius.circular(10),
                      border: slot.isEmpty
                          ? Border.all(color: TantinColors.hairline, width: 1.5)
                          : null,
                      boxShadow: const [
                        BoxShadow(
                          color: TantinColors.ivoryBg,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      '${slot.index}',
                      style: TextStyle(
                        color: slot.isEmpty
                            ? TantinColors.inkMuted
                            : Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Pressable(
                  onPressed: onEditGroup,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: hovering
                          ? TantinColors.majorelleSoft
                          : slot.isEmpty
                          ? TantinColors.ivorySunken
                          : TantinColors.ivorySurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hovering
                            ? TantinColors.majorelle
                            : TantinColors.hairline,
                        width: hovering || slot.isEmpty ? 1.5 : 1,
                      ),
                      boxShadow: slot.isEmpty ? null : TantinShadows.sm,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                TantinDates.dayMonth(date),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: TantinColors.inkMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                TantinFormat.fmtDH(potAmount),
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: TantinColors.inkMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              if (slot.isGroup) const _GroupBadge(),
                            ],
                          ),
                          const SizedBox(height: 5),
                          if (slot.isEmpty)
                            const Text(
                              'Glissez un membre ici',
                              style: TextStyle(
                                fontSize: 13,
                                color: TantinColors.inkMuted,
                              ),
                            )
                          else
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                for (final uid in slot.recipientUids)
                                  _PlacedChip(
                                    participant: participants.firstWhere(
                                      (participant) => participant.uid == uid,
                                    ),
                                    onRemove: () => onRemove(uid),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DraggableParticipant extends StatelessWidget {
  const _DraggableParticipant({required this.participant});

  final CreateParticipant participant;

  @override
  Widget build(BuildContext context) {
    final avatar = Avatar(
      data: AvatarData(
        initials: participant.initials,
        bgColor: participant.avatarColor,
      ),
      size: 46,
    );
    return Draggable<String>(
      data: participant.uid,
      feedback: Transform.scale(
        scale: 1.12,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: TantinColors.majorelle.withValues(alpha: 0.35),
                offset: const Offset(0, 12),
                blurRadius: 20,
              ),
            ],
          ),
          child: avatar,
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _TrayMember(participant),
      ),
      child: _TrayMember(participant),
    );
  }
}

class _TrayMember extends StatelessWidget {
  const _TrayMember(this.participant);

  final CreateParticipant participant;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Avatar(
            data: AvatarData(
              initials: participant.initials,
              bgColor: participant.avatarColor,
            ),
            size: 46,
          ),
          const SizedBox(height: 4),
          Text(
            participant.prenom,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _PlacedChip extends StatelessWidget {
  const _PlacedChip({required this.participant, required this.onRemove});

  final CreateParticipant participant;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Draggable<String>(
      data: participant.uid,
      feedback: _ChipContent(participant: participant),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _ChipContent(participant: participant, onRemove: onRemove),
      ),
      child: _ChipContent(participant: participant, onRemove: onRemove),
    );
  }
}

class _ChipContent extends StatelessWidget {
  const _ChipContent({required this.participant, this.onRemove});

  final CreateParticipant participant;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TantinColors.majorelleSoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(3, 3, 8, 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Avatar(
              data: AvatarData(
                initials: participant.initials,
                bgColor: participant.avatarColor,
              ),
              size: 24,
            ),
            const SizedBox(width: 6),
            Text(
              participant.prenom,
              style: const TextStyle(
                color: TantinColors.majorelleDeep,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (onRemove != null) ...[
              const SizedBox(width: 5),
              GestureDetector(
                onTap: onRemove,
                child: TnIcons.close(size: 13, color: TantinColors.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _GroupEditorSheet extends StatelessWidget {
  const _GroupEditorSheet({
    required this.slot,
    required this.participants,
    required this.potAmount,
    required this.onShareChanged,
  });

  final AssignmentSlot slot;
  final List<CreateParticipant> participants;
  final int potAmount;
  final void Function(String uid, int value) onShareChanged;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 10, 20, 20 + bottom),
      decoration: const BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
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
          Text(
            'Groupe · Période ${slot.index}',
            style: Theme.of(context).textTheme.displayLarge?.copyWith(
              fontSize: 22,
              color: TantinColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Le groupe se répartit le versement des autres parts : '
            '${TantinFormat.fmtDH(potAmount)}. Les parts doivent totaliser '
            '100 %.',
            style: const TextStyle(
              color: TantinColors.inkMuted,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          for (final uid in slot.recipientUids)
            _ShareRow(
              participant: participants.firstWhere(
                (participant) => participant.uid == uid,
              ),
              share: slot.shares[uid] ?? 0,
              potAmount: potAmount,
              onChange: (value) => onShareChanged(uid, value),
            ),
          const SizedBox(height: 8),
          Text(
            'Total des parts : ${slot.shareSum}%',
            textAlign: TextAlign.right,
            style: TextStyle(
              color: slot.shareSum == 100
                  ? TantinColors.success
                  : TantinColors.danger,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          TnButton(
            full: true,
            disabled: slot.shareSum != 100,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Enregistrer le groupe'),
          ),
        ],
      ),
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({
    required this.participant,
    required this.share,
    required this.potAmount,
    required this.onChange,
  });

  final CreateParticipant participant;
  final int share;
  final int potAmount;
  final ValueChanged<int> onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: TantinColors.ivoryBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Avatar(
            data: AvatarData(
              initials: participant.initials,
              bgColor: participant.avatarColor,
            ),
            size: 38,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  TantinFormat.fmtDH((potAmount * share / 100).round()),
                  style: const TextStyle(
                    color: TantinColors.success,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _SmallStep(onTap: () => onChange(share - 5), minus: true),
          SizedBox(
            width: 48,
            child: Text(
              '$share%',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                fontSize: 18,
                color: TantinColors.ink,
              ),
            ),
          ),
          _SmallStep(onTap: () => onChange(share + 5), minus: false),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.participant,
    required this.selected,
    required this.onTap,
  });

  final CreateParticipant participant;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? TantinColors.majorelleSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Avatar(
              data: AvatarData(
                initials: participant.initials,
                bgColor: participant.avatarColor,
              ),
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    participant.kind == CreateParticipantKind.self
                        ? 'vous'
                        : 'membre inscrit',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: TantinColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            _CheckBox(selected: selected),
          ],
        ),
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
        child: Row(
          children: [
            const Avatar(
              data: AvatarData(
                initials: 'IN',
                bgColor: TantinColors.saffron,
                fgColor: TantinColors.ivorySurface,
              ),
              size: 42,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Text(
              'inviter',
              style: TextStyle(
                color: TantinColors.majorelle,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalcCard extends StatelessWidget {
  const _CalcCard({required this.state, required this.dates});

  final CreateDaretState state;
  final List<DateTime> dates;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TantinColors.majorelleSoft,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: TantinColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                TnIcons.sparkle(size: 17, color: TantinColors.majorelleDeep),
                const SizedBox(width: 7),
                const Text(
                  'Calcul automatique',
                  style: TextStyle(
                    fontSize: 13,
                    color: TantinColors.majorelleDeep,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Expanded(
                  child: Text(
                    'Cagnotte reçue à chaque tour',
                    style: TextStyle(
                      color: TantinColors.inkMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                CountUp(
                  value: state.cagnotteParPeriode.toDouble(),
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 22,
                    color: TantinColors.majorelleDeep,
                  ),
                ),
              ],
            ),
            const Divider(height: 18, color: Color(0x1F352DA8)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Dernier tour',
                  style: TextStyle(
                    color: TantinColors.inkMuted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${TantinDates.dayMonth(dates.last)} ${dates.last.year}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.unit,
    required this.onMinus,
    required this.onPlus,
  });

  final int value;
  final String unit;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TantinColors.ivorySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: TantinColors.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            _SquareButton(icon: TnIcons.minus(size: 18), onPressed: onMinus),
            Expanded(
              child: Column(
                children: [
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 30,
                      color: TantinColors.ink,
                    ),
                  ),
                  Text(
                    unit,
                    style: const TextStyle(
                      color: TantinColors.inkMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            _SquareButton(icon: TnIcons.plus(size: 18), onPressed: onPlus),
          ],
        ),
      ),
    );
  }
}

class _RecapStat extends StatelessWidget {
  const _RecapStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontSize: 19,
                  color: TantinColors.majorelle,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: TantinColors.inkMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecapPeriodRow extends StatelessWidget {
  const _RecapPeriodRow({
    required this.slot,
    required this.date,
    required this.participants,
    required this.last,
  });

  final AssignmentSlot slot;
  final DateTime date;
  final List<CreateParticipant> participants;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final names = slot.recipientUids
        .map((uid) {
          return participants
              .firstWhere((participant) => participant.uid == uid)
              .prenom;
        })
        .join(', ');
    final avatars = slot.recipientUids
        .map((uid) {
          final participant = participants.firstWhere(
            (item) => item.uid == uid,
          );
          return AvatarData(
            initials: participant.initials,
            bgColor: participant.avatarColor,
          );
        })
        .toList(growable: false);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: last
              ? BorderSide.none
              : const BorderSide(color: TantinColors.hairline),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          children: [
            SizedBox(
              width: 20,
              child: Text(
                '${slot.index}',
                style: const TextStyle(
                  color: TantinColors.majorelle,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(
              width: 68,
              child: Text(
                TantinDates.dayMonth(date),
                style: const TextStyle(
                  color: TantinColors.inkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AvatarStack(avatars: avatars, size: 26, maxCount: 3),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                names,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (slot.isGroup) const _GroupBadge(),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12.5,
          color: TantinColors.inkMuted,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(String hint) {
  return InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: TantinColors.ivorySurface,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: TantinColors.hairline, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: TantinColors.hairline, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: TantinColors.majorelle, width: 1.5),
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.onChanged});

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TantinColors.ivorySunken,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          const SizedBox(width: 13),
          TnIcons.search(size: 18, color: TantinColors.inkMuted),
          const SizedBox(width: 9),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              decoration: const InputDecoration(
                hintText: 'Rechercher',
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.value,
    required this.selected,
    required this.onPressed,
  });

  final String value;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final color = hexToColor(value);
    return Pressable(
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(13),
          boxShadow: selected
              ? [
                  const BoxShadow(
                    color: TantinColors.ivoryBg,
                    spreadRadius: 2.5,
                  ),
                  BoxShadow(color: color, spreadRadius: 5),
                ]
              : TantinShadows.sm,
        ),
        child: SizedBox(
          width: 40,
          height: 40,
          child: selected
              ? Center(child: TnIcons.check(size: 20, color: Colors.white))
              : null,
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onPressed});

  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: icon,
      ),
    );
  }
}

class _SquareButton extends StatelessWidget {
  const _SquareButton({required this.icon, required this.onPressed});

  final Widget icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TantinColors.ivoryBg,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: icon,
      ),
    );
  }
}

class _SmallStep extends StatelessWidget {
  const _SmallStep({required this.onTap, required this.minus});

  final VoidCallback onTap;
  final bool minus;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onTap,
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: TantinColors.hairline),
        ),
        child: minus
            ? Transform.rotate(
                angle: 0.8,
                child: TnIcons.close(size: 15, color: TantinColors.ink),
              )
            : TnIcons.plus(size: 15, color: TantinColors.ink),
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final Widget icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: TantinColors.ivorySurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TantinColors.hairline),
          boxShadow: TantinShadows.sm,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckBox extends StatelessWidget {
  const _CheckBox({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? TantinColors.majorelle : Colors.transparent,
        borderRadius: BorderRadius.circular(9),
        border: selected
            ? null
            : Border.all(color: TantinColors.hairline, width: 2),
      ),
      child: selected ? TnIcons.check(size: 16, color: Colors.white) : null,
    );
  }
}

class _GroupBadge extends StatelessWidget {
  const _GroupBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: TantinColors.terracotta.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        child: Text(
          'GROUPE',
          style: TextStyle(
            fontSize: 10.5,
            color: TantinColors.terracotta,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}
