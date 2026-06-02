import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tantin_flutter/core/firebase/firestore_helpers.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

abstract class DaretFirestoreMapper {
  static Daret fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = _requiredData(snapshot);
    return Daret(
      id: snapshot.id,
      nom: data['nom'] as String,
      cover: data['cover'] as String,
      accent: data['accent'] as String,
      montant: data['montant'] as int,
      frequence: _enumValue(
        DaretFrequency.values,
        data['frequence'],
        (item) => item.firestoreValue,
      ),
      periodesCount: data['periodesCount'] as int,
      cagnotteParPeriode: data['cagnotteParPeriode'] as int,
      statut: _enumValue(
        DaretStatus.values,
        data['statut'],
        (item) => item.firestoreValue,
      ),
      adminUid: data['adminUid'] as String,
      memberUids: stringListFromFirestore(data['memberUids']),
      currentPeriode: data['currentPeriode'] as int,
      prochaineDate: dateTimeFromFirestore(data['prochaineDate']),
      inviteCode: data['inviteCode'] as String?,
      settings: DaretSettings.fromJson(
        mapFromFirestore(data['settings']),
      ),
      createdAt: dateTimeFromFirestore(data['createdAt']),
      startedAt: dateTimeFromFirestore(data['startedAt']),
      closedAt: dateTimeFromFirestore(data['closedAt']),
    );
  }

  static Map<String, dynamic> toFirestore(Daret daret) {
    return <String, dynamic>{
      'nom': daret.nom,
      'cover': daret.cover,
      'accent': daret.accent,
      'montant': daret.montant,
      'frequence': daret.frequence.firestoreValue,
      'periodesCount': daret.periodesCount,
      'cagnotteParPeriode': daret.cagnotteParPeriode,
      'statut': daret.statut.firestoreValue,
      'adminUid': daret.adminUid,
      'memberUids': daret.memberUids,
      'currentPeriode': daret.currentPeriode,
      'prochaineDate': timestampFromDateTime(daret.prochaineDate),
      'inviteCode': daret.inviteCode,
      'settings': daret.settings.toJson(),
      'createdAt': timestampFromDateTime(daret.createdAt),
      'startedAt': timestampFromDateTime(daret.startedAt),
      'closedAt': timestampFromDateTime(daret.closedAt),
    };
  }
}

abstract class DaretMemberFirestoreMapper {
  static DaretMember fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = _requiredData(snapshot);
    return DaretMember(
      uid: data['uid'] as String,
      role: _enumValue(
        MemberRole.values,
        data['role'],
        (item) => item.firestoreValue,
      ),
      joinedAt: dateTimeFromFirestore(data['joinedAt']),
      approvalStatus: _enumValue(
        ApprovalStatus.values,
        data['approvalStatus'],
        (item) => item.firestoreValue,
      ),
      name: data['name'] as String,
      prenom: data['prenom'] as String,
      initials: data['initials'] as String,
      avatarPalette: stringListFromFirestore(data['avatarPalette']),
      groupePart: data['groupePart'] as int?,
    );
  }

  static Map<String, dynamic> toFirestore(DaretMember member) {
    return <String, dynamic>{
      'uid': member.uid,
      'role': member.role.firestoreValue,
      'joinedAt': timestampFromDateTime(member.joinedAt),
      'approvalStatus': member.approvalStatus.firestoreValue,
      'name': member.name,
      'prenom': member.prenom,
      'initials': member.initials,
      'avatarPalette': member.avatarPalette,
      'groupePart': member.groupePart,
    };
  }
}

abstract class DaretPeriodFirestoreMapper {
  static DaretPeriod fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = _requiredData(snapshot);
    return DaretPeriod(
      id: snapshot.id,
      index: data['index'] as int,
      recipientUids: stringListFromFirestore(data['recipientUids']),
      shares: intMapFromFirestore(data['shares']),
      scheduledDate: _requiredDate(data, 'scheduledDate'),
      potAmount: data['potAmount'] as int,
      status: _enumValue(
        PeriodStatus.values,
        data['status'],
        (item) => item.firestoreValue,
      ),
      paidCount: data['paidCount'] as int,
      totalCount: data['totalCount'] as int,
      closedAt: dateTimeFromFirestore(data['closedAt']),
    );
  }

  static Map<String, dynamic> toFirestore(DaretPeriod period) {
    return <String, dynamic>{
      'index': period.index,
      'recipientUids': period.recipientUids,
      'shares': period.shares,
      'scheduledDate': timestampFromDateTime(period.scheduledDate),
      'potAmount': period.potAmount,
      'status': period.status.firestoreValue,
      'paidCount': period.paidCount,
      'totalCount': period.totalCount,
      'closedAt': timestampFromDateTime(period.closedAt),
    };
  }
}

abstract class ContributionFirestoreMapper {
  static Contribution fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = _requiredData(snapshot);
    return Contribution(
      payerUid: data['payerUid'] as String,
      state: _enumValue(
        ContributionState.values,
        data['state'],
        (item) => item.firestoreValue,
      ),
      amount: data['amount'] as int,
      paidDeclaredAt: dateTimeFromFirestore(data['paidDeclaredAt']),
      confirmedAt: dateTimeFromFirestore(data['confirmedAt']),
      confirmedByUid: data['confirmedByUid'] as String?,
    );
  }

  static Map<String, dynamic> toFirestore(Contribution contribution) {
    return <String, dynamic>{
      'payerUid': contribution.payerUid,
      'state': contribution.state.firestoreValue,
      'amount': contribution.amount,
      'paidDeclaredAt': timestampFromDateTime(contribution.paidDeclaredAt),
      'confirmedAt': timestampFromDateTime(contribution.confirmedAt),
      'confirmedByUid': contribution.confirmedByUid,
    };
  }
}

abstract class DaretInviteFirestoreMapper {
  static DaretInvite fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = _requiredData(snapshot);
    return DaretInvite(
      code: snapshot.id,
      daretId: data['daretId'] as String,
      createdByUid: data['createdByUid'] as String,
      active: data['active'] as bool,
      expiresAt: _requiredDate(data, 'expiresAt'),
    );
  }

  static Map<String, dynamic> toFirestore(DaretInvite invite) {
    return <String, dynamic>{
      'daretId': invite.daretId,
      'createdByUid': invite.createdByUid,
      'active': invite.active,
      'expiresAt': timestampFromDateTime(invite.expiresAt),
    };
  }
}

Map<String, dynamic> _requiredData(
  DocumentSnapshot<Map<String, dynamic>> snapshot,
) {
  final data = snapshot.data();
  if (data == null) {
    throw StateError('Firestore document ${snapshot.reference.path} is empty');
  }
  return data;
}

DateTime _requiredDate(Map<String, dynamic> data, String field) {
  final date = dateTimeFromFirestore(data[field]);
  if (date == null) {
    throw StateError('Firestore field $field must be a Timestamp');
  }
  return date;
}

T _enumValue<T>(
  Iterable<T> values,
  Object? value,
  String Function(T item) firestoreValue,
) {
  return values.firstWhere(
    (item) => firestoreValue(item) == value,
    orElse: () => throw StateError('Unsupported Firestore enum value: $value'),
  );
}
