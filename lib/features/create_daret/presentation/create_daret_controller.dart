import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tantin_flutter/features/create_daret/data/create_daret_repository.dart';
import 'package:tantin_flutter/features/create_daret/domain/create_daret_models.dart';
import 'package:tantin_flutter/features/darets/data/daret_callable_repository.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

class CreateDaretController extends StateNotifier<CreateDaretState> {
  CreateDaretController()
    : super(
        CreateDaretState(
          slots: CreateDaretLogic.initialSlots(6),
        ),
      );

  void ensureCurrentUser(AppUser user) {
    if (state.participants.any((participant) => participant.uid == user.uid)) {
      return;
    }
    state = state.copyWith(
      participants: [
        CreateParticipant.fromUser(user, kind: CreateParticipantKind.self),
        ...state.participants,
      ],
    );
  }

  void setStep(int step) {
    state = state.copyWith(step: step.clamp(1, 5));
  }

  void next() => setStep(state.step + 1);
  void back() => setStep(state.step - 1);

  void setNom(String value) {
    state = state.copyWith(nom: value, clearSubmitError: true);
  }

  void setCover(String value) {
    state = state.copyWith(cover: value);
  }

  void setAccent(String value) {
    state = state.copyWith(accent: value);
  }

  void setMontant(int value) {
    state = state.copyWith(montant: value.clamp(50, 999999));
  }

  void setFrequence(DaretFrequency value) {
    state = state.copyWith(frequence: value);
  }

  void setPeriodesCount(int value) {
    final count = value.clamp(2, 24);
    state = state.copyWith(
      periodesCount: count,
      slots: CreateDaretLogic.syncSlotCount(state.slots, count),
    );
  }

  void toggleParticipant(CreateParticipant participant) {
    if (participant.kind == CreateParticipantKind.self) return;
    final exists = state.participants.any(
      (item) => item.uid == participant.uid,
    );
    if (exists) {
      state = state.copyWith(
        participants: state.participants
            .where((item) => item.uid != participant.uid)
            .toList(growable: false),
        slots: CreateDaretLogic.remove(state.slots, participant.uid),
      );
      return;
    }
    state = state.copyWith(
      participants: [...state.participants, participant],
    );
  }

  void addPendingInvite({String? displayName}) {
    final index = state.nextInviteIndex;
    final label = displayName == null || displayName.trim().isEmpty
        ? 'Invitation $index'
        : displayName.trim();
    final participant = CreateParticipant(
      uid: 'pending_invite_$index',
      name: label,
      prenom: label.split(' ').first,
      initials: 'IN',
      avatarPalette: const ['#F5A623', '#FBEFD6'],
      kind: CreateParticipantKind.pendingInvite,
      inviteIndex: index,
    );
    state = state.copyWith(
      participants: [...state.participants, participant],
      nextInviteIndex: index + 1,
    );
  }

  void placeParticipant(String uid, int slotIndex) {
    if (slotIndex < 0 || slotIndex >= state.slots.length) return;
    state = state.copyWith(
      slots: CreateDaretLogic.place(state.slots, uid, slotIndex),
    );
  }

  void removeFromSlot(String uid) {
    state = state.copyWith(slots: CreateDaretLogic.remove(state.slots, uid));
  }

  void autoOrganize() {
    state = state.copyWith(
      slots: CreateDaretLogic.autoOrganize(
        state.participants,
        state.periodesCount,
      ),
    );
  }

  void tirageAuSort() {
    state = state.copyWith(
      slots: CreateDaretLogic.tirageAuSort(
        state.participants,
        state.periodesCount,
        seed: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  void setGroupShare({
    required int slotIndex,
    required String uid,
    required int value,
  }) {
    if (slotIndex < 0 || slotIndex >= state.slots.length) return;
    final slot = state.slots[slotIndex];
    if (!slot.recipientUids.contains(uid)) return;
    final shares = <String, int>{
      ...slot.shares,
      uid: value.clamp(0, 100),
    };
    final slots = [...state.slots];
    slots[slotIndex] = slot.copyWith(shares: shares);
    state = state.copyWith(slots: slots);
  }

  bool get canGoNext {
    return switch (state.step) {
      1 => state.nom.trim().length >= 2,
      2 => state.montant >= 50 && state.periodesCount >= 2,
      3 => state.participants.length >= state.periodesCount,
      4 => CreateDaretLogic.validateAssignment(
        state.participants,
        state.slots,
      ).valid,
      5 => !state.isSubmitting,
      _ => false,
    };
  }

  List<DateTime> generatedDates(AppUser user) {
    return CreateDaretLogic.generateDates(
      count: state.periodesCount,
      frequence: state.frequence,
      echeanceDay: user.settings.defaultEcheanceDay,
    );
  }

  Future<CreateDaretResult> submit({
    required AppUser creator,
    required CreateDaretRepository repository,
    required DaretCallableRepository callables,
  }) async {
    final validation = CreateDaretLogic.validateAssignment(
      state.participants,
      state.slots,
    );
    if (!validation.valid) {
      state = state.copyWith(submitError: validation.message);
      throw StateError(validation.message);
    }
    state = state.copyWith(
      isSubmitting: true,
      clearSubmitError: true,
      clearResult: true,
    );
    try {
      final daretId = await repository.createDraft(
        draft: state,
        creator: creator,
        scheduledDates: generatedDates(creator),
      );
      await callables.startDaret(daretId);
      final inviteCode = await callables.createInvite(daretId);
      final result = CreateDaretResult(
        daretId: daretId,
        inviteCode: inviteCode,
      );
      state = state.copyWith(
        isSubmitting: false,
        result: result,
      );
      return result;
    } on Object catch (error) {
      state = state.copyWith(
        isSubmitting: false,
        submitError: error.toString(),
      );
      rethrow;
    }
  }
}
