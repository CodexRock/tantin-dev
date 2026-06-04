import 'dart:math';

import 'package:flutter/material.dart';
import 'package:tantin_flutter/core/theme/color_utils.dart';
import 'package:tantin_flutter/core/theme/tokens.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

enum CreateParticipantKind { self, app, previous, pendingInvite }

class CreateParticipant {
  const CreateParticipant({
    required this.uid,
    required this.name,
    required this.prenom,
    required this.initials,
    required this.avatarPalette,
    required this.kind,
    this.inviteIndex,
  });

  factory CreateParticipant.fromUser(
    AppUser user, {
    CreateParticipantKind kind = CreateParticipantKind.app,
  }) {
    return CreateParticipant(
      uid: user.uid,
      name: user.name,
      prenom: user.prenom,
      initials: user.initials,
      avatarPalette: user.avatarPalette,
      kind: kind,
    );
  }

  final String uid;
  final String name;
  final String prenom;
  final String initials;
  final List<String> avatarPalette;
  final CreateParticipantKind kind;
  final int? inviteIndex;

  bool get isPendingInvite => kind == CreateParticipantKind.pendingInvite;

  Color get avatarColor {
    if (avatarPalette.isEmpty) return TantinColors.majorelle;
    return hexToColor(avatarPalette.first);
  }

  Map<String, Object?> toDraftMember() {
    if (isPendingInvite) {
      final index = inviteIndex ?? 1;
      return <String, Object?>{
        'uid': uid,
        'inviteIndex': index,
        'prenom': 'Invitation $index',
        'name': 'Invitation $index',
        'initials': 'IN',
        'avatarPalette': avatarPalette,
      };
    }
    return <String, Object?>{
      'uid': uid,
      'avatarPalette': avatarPalette,
    };
  }
}

class AssignmentSlot {
  const AssignmentSlot({
    required this.index,
    this.recipientUids = const <String>[],
    this.shares = const <String, int>{},
  });

  final int index;
  final List<String> recipientUids;
  final Map<String, int> shares;

  bool get isEmpty => recipientUids.isEmpty;
  bool get isGroup => recipientUids.length >= 2;
  int get shareSum => shares.values.fold(0, (sum, value) => sum + value);

  AssignmentSlot copyWith({
    List<String>? recipientUids,
    Map<String, int>? shares,
  }) {
    return AssignmentSlot(
      index: index,
      recipientUids: recipientUids ?? this.recipientUids,
      shares: shares ?? this.shares,
    );
  }

  Map<String, Object?> toDraftPeriod(DateTime scheduledDate, int potAmount) {
    return <String, Object?>{
      'index': index,
      'recipientUids': recipientUids,
      'shares': shares,
      'scheduledDate': scheduledDate,
      'potAmount': potAmount,
    };
  }
}

class AssignmentValidation {
  const AssignmentValidation({
    required this.valid,
    required this.message,
  });

  final bool valid;
  final String message;
}

class CreateDaretResult {
  const CreateDaretResult({required this.daretId, required this.inviteCode});

  final String daretId;
  final String inviteCode;
}

class CreateDaretState {
  const CreateDaretState({
    this.step = 1,
    this.nom = '',
    this.cover = '🏡',
    this.accent = '#5247E6',
    this.montant = 1000,
    this.frequence = DaretFrequency.mensuel,
    this.periodesCount = 6,
    this.participants = const <CreateParticipant>[],
    this.slots = const <AssignmentSlot>[],
    this.nextInviteIndex = 1,
    this.isSubmitting = false,
    this.submitError,
    this.result,
  });

  final int step;
  final String nom;
  final String cover;
  final String accent;
  final int montant;
  final DaretFrequency frequence;
  final int periodesCount;
  final List<CreateParticipant> participants;
  final List<AssignmentSlot> slots;
  final int nextInviteIndex;
  final bool isSubmitting;
  final String? submitError;
  final CreateDaretResult? result;

  int get cagnotteParPeriode => montant * periodesCount;
  int get payoutParPeriode {
    final contributingShares = periodesCount <= 1 ? 0 : periodesCount - 1;
    return montant * contributingShares;
  }

  bool get hasCurrentUser => participants.any(
    (participant) => participant.kind == CreateParticipantKind.self,
  );

  CreateDaretState copyWith({
    int? step,
    String? nom,
    String? cover,
    String? accent,
    int? montant,
    DaretFrequency? frequence,
    int? periodesCount,
    List<CreateParticipant>? participants,
    List<AssignmentSlot>? slots,
    int? nextInviteIndex,
    bool? isSubmitting,
    String? submitError,
    bool clearSubmitError = false,
    CreateDaretResult? result,
    bool clearResult = false,
  }) {
    return CreateDaretState(
      step: step ?? this.step,
      nom: nom ?? this.nom,
      cover: cover ?? this.cover,
      accent: accent ?? this.accent,
      montant: montant ?? this.montant,
      frequence: frequence ?? this.frequence,
      periodesCount: periodesCount ?? this.periodesCount,
      participants: participants ?? this.participants,
      slots: slots ?? this.slots,
      nextInviteIndex: nextInviteIndex ?? this.nextInviteIndex,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submitError: clearSubmitError ? null : submitError ?? this.submitError,
      result: clearResult ? null : result ?? this.result,
    );
  }
}

abstract class CreateDaretLogic {
  static const covers = [
    '🏡',
    '💜',
    '💼',
    '✈️',
    '🎓',
    '🎉',
    '🚗',
    '🌙',
    '☕',
    '🛋️',
  ];
  static const accents = [
    '#5247E6',
    '#C75B39',
    '#2E9E6B',
    '#F5A623',
    '#352DA8',
    '#D2483F',
  ];

  static List<AssignmentSlot> initialSlots(int count) {
    return List<AssignmentSlot>.generate(
      count,
      (index) => AssignmentSlot(index: index + 1),
    );
  }

  static List<AssignmentSlot> syncSlotCount(
    List<AssignmentSlot> slots,
    int count,
  ) {
    return List<AssignmentSlot>.generate(count, (index) {
      if (index < slots.length) {
        final slot = slots[index];
        return AssignmentSlot(
          index: index + 1,
          recipientUids: slot.recipientUids,
          shares: slot.shares,
        );
      }
      return AssignmentSlot(index: index + 1);
    });
  }

  static List<DateTime> generateDates({
    required int count,
    required DaretFrequency frequence,
    required int echeanceDay,
    DateTime? now,
  }) {
    final reference = now ?? DateTime.now();
    final safeDay = echeanceDay.clamp(1, 28);
    var start = DateTime(reference.year, reference.month, safeDay);
    if (!start.isAfter(reference)) {
      start = DateTime(reference.year, reference.month + 1, safeDay);
    }
    return List<DateTime>.generate(count, (index) {
      if (frequence == DaretFrequency.hebdomadaire) {
        return start.add(Duration(days: index * 7));
      }
      return DateTime(start.year, start.month + index, start.day);
    });
  }

  static Map<String, int> equalShares(List<String> uids) {
    if (uids.isEmpty) return const <String, int>{};
    final base = 100 ~/ uids.length;
    var remainder = 100 - base * uids.length;
    final shares = <String, int>{};
    for (final uid in uids) {
      shares[uid] = base + (remainder > 0 ? 1 : 0);
      remainder -= 1;
    }
    return shares;
  }

  static List<AssignmentSlot> place(
    List<AssignmentSlot> slots,
    String uid,
    int slotIndex,
  ) {
    final cleared = slots.map((slot) {
      final recipients = slot.recipientUids
          .where((candidate) => candidate != uid)
          .toList(growable: false);
      return slot.copyWith(
        recipientUids: recipients,
        shares: equalShares(recipients),
      );
    }).toList();
    final target = cleared[slotIndex];
    final recipients = <String>[...target.recipientUids, uid];
    cleared[slotIndex] = target.copyWith(
      recipientUids: recipients,
      shares: equalShares(recipients),
    );
    return cleared;
  }

  static List<AssignmentSlot> remove(
    List<AssignmentSlot> slots,
    String uid,
  ) {
    return slots.map((slot) {
      final recipients = slot.recipientUids
          .where((candidate) => candidate != uid)
          .toList(growable: false);
      return slot.copyWith(
        recipientUids: recipients,
        shares: equalShares(recipients),
      );
    }).toList();
  }

  static List<AssignmentSlot> autoOrganize(
    List<CreateParticipant> participants,
    int periodesCount,
  ) {
    final slots = initialSlots(periodesCount);
    for (var i = 0; i < participants.length; i += 1) {
      final slotIndex = i < periodesCount ? i : i % periodesCount;
      final slot = slots[slotIndex];
      final recipients = <String>[...slot.recipientUids, participants[i].uid];
      slots[slotIndex] = slot.copyWith(
        recipientUids: recipients,
        shares: equalShares(recipients),
      );
    }
    return slots;
  }

  static List<AssignmentSlot> tirageAuSort(
    List<CreateParticipant> participants,
    int periodesCount, {
    int seed = 42,
  }) {
    final shuffled = [...participants];
    final random = Random(seed);
    for (var i = shuffled.length - 1; i > 0; i -= 1) {
      final j = random.nextInt(i + 1);
      final tmp = shuffled[i];
      shuffled[i] = shuffled[j];
      shuffled[j] = tmp;
    }
    return autoOrganize(shuffled, periodesCount);
  }

  static AssignmentValidation validateAssignment(
    List<CreateParticipant> participants,
    List<AssignmentSlot> slots,
  ) {
    if (participants.length < slots.length) {
      return const AssignmentValidation(
        valid: false,
        message: 'Ajoutez au moins un membre par période.',
      );
    }
    if (slots.any((slot) => slot.recipientUids.isEmpty)) {
      return const AssignmentValidation(
        valid: false,
        message: 'Chaque période doit avoir un bénéficiaire.',
      );
    }
    final placed = <String>{};
    for (final slot in slots) {
      if (slot.shareSum != 100) {
        return const AssignmentValidation(
          valid: false,
          message: 'Les parts de chaque groupe doivent totaliser 100 %.',
        );
      }
      for (final uid in slot.recipientUids) {
        if (!placed.add(uid)) {
          return const AssignmentValidation(
            valid: false,
            message: 'Un membre ne peut être placé qu’une seule fois.',
          );
        }
      }
    }
    final selected = participants.map((participant) => participant.uid).toSet();
    if (!selected.every(placed.contains)) {
      return const AssignmentValidation(
        valid: false,
        message: 'Placez tous les membres dans l’ordre.',
      );
    }
    return const AssignmentValidation(valid: true, message: 'Ordre complet');
  }
}
