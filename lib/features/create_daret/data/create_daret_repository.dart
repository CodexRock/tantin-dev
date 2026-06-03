import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tantin_flutter/features/create_daret/domain/create_daret_models.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';
import 'package:tantin_flutter/features/profile/domain/app_user.dart';

class CreateDaretRepository {
  const CreateDaretRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Future<String> createDraft({
    required CreateDaretState draft,
    required AppUser creator,
    required List<DateTime> scheduledDates,
  }) async {
    final doc = _firestore.collection('darets').doc();
    final draftMembers = draft.participants
        .map((participant) => participant.toDraftMember())
        .toList(growable: false);
    final potAmount = draft.montant * draft.participants.length;
    final draftPeriods = <Map<String, Object?>>[
      for (var i = 0; i < draft.slots.length; i += 1)
        draft.slots[i].toDraftPeriod(scheduledDates[i], potAmount),
    ];

    await doc.set(<String, Object?>{
      'nom': draft.nom.trim(),
      'cover': draft.cover,
      'accent': draft.accent,
      'montant': draft.montant,
      'frequence': draft.frequence.firestoreValue,
      'periodesCount': draft.periodesCount,
      'cagnotteParPeriode': draft.montant,
      'statut': DaretStatus.brouillon.firestoreValue,
      'adminUid': creator.uid,
      'memberUids': [creator.uid],
      'currentPeriode': 0,
      'prochaineDate': Timestamp.fromDate(scheduledDates.first),
      'inviteCode': null,
      'settings': <String, Object?>{
        'echeanceDay': creator.settings.defaultEcheanceDay,
        'graceDays': creator.settings.graceDays,
      },
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'startedAt': null,
      'closedAt': null,
      'draftMembers': draftMembers,
      'draftPeriods': draftPeriods,
    });
    return doc.id;
  }
}
