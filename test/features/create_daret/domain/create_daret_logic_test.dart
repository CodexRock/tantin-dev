import 'package:flutter_test/flutter_test.dart';
import 'package:tantin_flutter/features/create_daret/domain/create_daret_models.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

const _participants = <CreateParticipant>[
  CreateParticipant(
    uid: 'self',
    name: 'Yasmine Amrani',
    prenom: 'Yasmine',
    initials: 'YA',
    avatarPalette: ['#5247E6', '#E7E5FB'],
    kind: CreateParticipantKind.self,
  ),
  CreateParticipant(
    uid: 'karim',
    name: 'Karim Tazi',
    prenom: 'Karim',
    initials: 'KT',
    avatarPalette: ['#F5A623', '#FBEFD6'],
    kind: CreateParticipantKind.app,
  ),
  CreateParticipant(
    uid: 'salma',
    name: 'Salma Idrissi',
    prenom: 'Salma',
    initials: 'SI',
    avatarPalette: ['#2E9E6B', '#DCF0E6'],
    kind: CreateParticipantKind.app,
  ),
  CreateParticipant(
    uid: 'nadia',
    name: 'Nadia Bennani',
    prenom: 'Nadia',
    initials: 'NB',
    avatarPalette: ['#D2483F', '#F8DAD7'],
    kind: CreateParticipantKind.app,
  ),
];

void main() {
  group('CreateDaretLogic', () {
    test('generates future dates from the global echeance setting', () {
      final dates = CreateDaretLogic.generateDates(
        count: 3,
        frequence: DaretFrequency.mensuel,
        echeanceDay: 5,
        now: DateTime(2026, 6, 3),
      );

      expect(
        dates,
        <DateTime>[
          DateTime(2026, 6, 5),
          DateTime(2026, 7, 5),
          DateTime(2026, 8, 5),
        ],
      );
    });

    test('moves a participant between slots without duplicating them', () {
      var slots = CreateDaretLogic.initialSlots(3);

      slots = CreateDaretLogic.place(slots, 'karim', 0);
      slots = CreateDaretLogic.place(slots, 'karim', 2);

      expect(slots[0].recipientUids, isEmpty);
      expect(slots[2].recipientUids, const ['karim']);
      expect(slots[2].shares, const {'karim': 100});
    });

    test('auto-organizes overflow members into a valid group split', () {
      final slots = CreateDaretLogic.autoOrganize(_participants, 3);

      expect(slots[0].recipientUids, const ['self', 'nadia']);
      expect(slots[0].shares, const {'self': 50, 'nadia': 50});
      expect(
        CreateDaretLogic.validateAssignment(_participants, slots).valid,
        isTrue,
      );
    });

    test('rejects group shares that do not total 100 percent', () {
      final slots = <AssignmentSlot>[
        const AssignmentSlot(
          index: 1,
          recipientUids: ['self', 'karim'],
          shares: {'self': 70, 'karim': 20},
        ),
        const AssignmentSlot(
          index: 2,
          recipientUids: ['salma'],
          shares: {'salma': 100},
        ),
      ];

      final validation = CreateDaretLogic.validateAssignment(
        _participants.take(3).toList(growable: false),
        slots,
      );

      expect(validation.valid, isFalse);
      expect(validation.message, contains('100'));
    });

    test('pending invite draft data stays generic and phone-free', () {
      const participant = CreateParticipant(
        uid: 'pending_invite_3',
        name: 'Aicha Fassi',
        prenom: 'Aicha',
        initials: 'AF',
        avatarPalette: ['#F5A623', '#FBEFD6'],
        kind: CreateParticipantKind.pendingInvite,
        inviteIndex: 3,
      );

      final draft = participant.toDraftMember();

      expect(draft['uid'], 'pending_invite_3');
      expect(draft['inviteIndex'], 3);
      expect(draft['prenom'], 'Invitation 3');
      expect(draft['name'], 'Invitation 3');
      expect(draft.containsKey('phone'), isFalse);
      expect(draft.values, isNot(contains('Aicha Fassi')));
    });
  });
}
