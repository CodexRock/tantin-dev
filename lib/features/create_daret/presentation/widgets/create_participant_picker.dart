import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:tantin_flutter/core/motion/motion.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/design_system/design_system.dart';
import 'package:tantin_flutter/features/create_daret/domain/create_daret_models.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

class CreateParticipantPicker extends StatefulWidget {
  const CreateParticipantPicker({
    required this.options,
    required this.selectedUids,
    required this.onParticipantTap,
    required this.onContactTap,
    super.key,
    this.onAddPendingInvite,
    this.showSelection = true,
    this.participantActionLabel = 'choisir',
    this.contactActionLabel = 'inviter',
    this.contactEmptyTitle = 'Invitations en attente',
    this.initialSource = 'amis',
  });

  final List<CreateParticipant> options;
  final Set<String> selectedUids;
  final ValueChanged<CreateParticipant> onParticipantTap;
  final ValueChanged<String> onContactTap;
  final VoidCallback? onAddPendingInvite;
  final bool showSelection;
  final String participantActionLabel;
  final String contactActionLabel;
  final String contactEmptyTitle;
  final String initialSource;

  @override
  State<CreateParticipantPicker> createState() =>
      _CreateParticipantPickerState();
}

class _CreateParticipantPickerState extends State<CreateParticipantPicker> {
  late String _source;
  var _query = '';
  List<Contact> _contacts = const <Contact>[];
  String? _contactsError;
  bool _loadingContacts = false;

  @override
  void initState() {
    super.initState();
    _source = widget.initialSource;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PickerSearchField(
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
        const SizedBox(height: 10),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              if (_source == 'contacts') ..._contactRows(),
              if (_source != 'contacts')
                for (final option in _filteredOptions())
                  _PickerMemberRow(
                    participant: option,
                    selected: widget.selectedUids.contains(option.uid),
                    showSelection: widget.showSelection,
                    actionLabel: widget.participantActionLabel,
                    onTap: () => widget.onParticipantTap(option),
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
    if (_loadingContacts) {
      return const [
        Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_contacts.isEmpty) {
      return [
        TnCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.contactEmptyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_contactsError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _contactsError!,
                    style: const TextStyle(color: TantinColors.danger),
                  ),
                ],
                const SizedBox(height: 12),
                TnButton(
                  full: true,
                  variant: ButtonVariant.soft,
                  icon: TnIcons.contacts(size: 18),
                  onPressed: _loadContacts,
                  child: const Text('Charger les contacts'),
                ),
                if (widget.onAddPendingInvite != null) ...[
                  const SizedBox(height: 10),
                  TnButton(
                    full: true,
                    variant: ButtonVariant.ghost,
                    icon: TnIcons.plus(size: 18),
                    onPressed: widget.onAddPendingInvite,
                    child: const Text('Ajouter une invitation'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ];
    }
    final query = _query.trim().toLowerCase();
    return _contacts
        .where((contact) {
          final name = contact.displayName ?? '';
          if (query.isEmpty) return true;
          return name.toLowerCase().contains(query);
        })
        .map((contact) {
          final name = contact.displayName ?? 'Contact';
          return _PickerContactRow(
            name: name,
            actionLabel: widget.contactActionLabel,
            onTap: () => widget.onContactTap(name),
          );
        })
        .toList(growable: false);
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
      if (!mounted) return;
      if (allowed != PermissionStatus.granted &&
          allowed != PermissionStatus.limited) {
        setState(() {
          _contactsError = 'Accès aux contacts refusé.';
          _loadingContacts = false;
        });
        return;
      }
      final contacts = await FlutterContacts.getAll(limit: 20);
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _loadingContacts = false;
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _contactsError = error.toString();
        _loadingContacts = false;
      });
    }
  }
}

CreateParticipant createParticipantFromMember(
  DaretMember member, {
  CreateParticipantKind kind = CreateParticipantKind.previous,
}) {
  return CreateParticipant(
    uid: member.uid,
    name: member.name,
    prenom: member.prenom,
    initials: member.initials,
    avatarPalette: member.avatarPalette,
    kind: kind,
  );
}

const fallbackCreateParticipantOptions = <CreateParticipant>[
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

class _PickerMemberRow extends StatelessWidget {
  const _PickerMemberRow({
    required this.participant,
    required this.selected,
    required this.showSelection,
    required this.actionLabel,
    required this.onTap,
  });

  final CreateParticipant participant;
  final bool selected;
  final bool showSelection;
  final String actionLabel;
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            if (showSelection)
              _PickerCheckBox(selected: selected)
            else
              Text(
                actionLabel,
                style: const TextStyle(
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

class _PickerContactRow extends StatelessWidget {
  const _PickerContactRow({
    required this.name,
    required this.actionLabel,
    required this.onTap,
  });

  final String name;
  final String actionLabel;
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              actionLabel,
              style: const TextStyle(
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

class _PickerSearchField extends StatelessWidget {
  const _PickerSearchField({required this.onChanged});

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

class _PickerCheckBox extends StatelessWidget {
  const _PickerCheckBox({required this.selected});

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
