import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:tantin_flutter/features/darets/data/daret_firestore_mapper.dart';
import 'package:tantin_flutter/features/darets/domain/daret_models.dart';

class DaretRepository {
  const DaretRepository(this._firestore);

  final FirebaseFirestore _firestore;

  Stream<List<Daret>> watchMyDarets(
    String uid, {
    DaretStatus? status,
  }) {
    var query = _firestore
        .collection('darets')
        .where('memberUids', arrayContains: uid);
    if (status != null) {
      query = query.where('statut', isEqualTo: status.firestoreValue);
    }
    return query.orderBy('createdAt', descending: true).snapshots().map(
      (snapshot) {
        return snapshot.docs
            .map(DaretFirestoreMapper.fromSnapshot)
            .toList(growable: false);
      },
    );
  }

  Stream<Daret?> watchDaret(String daretId) {
    return _firestore.collection('darets').doc(daretId).snapshots().map(
      (snapshot) {
        return snapshot.exists
            ? DaretFirestoreMapper.fromSnapshot(snapshot)
            : null;
      },
    );
  }

  Stream<List<DaretMember>> watchMembers(String daretId) {
    return _firestore
        .collection('darets')
        .doc(daretId)
        .collection('members')
        .orderBy('joinedAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(DaretMemberFirestoreMapper.fromSnapshot)
              .toList(growable: false);
        });
  }

  Stream<List<DaretPeriod>> watchPeriods(String daretId) {
    return _firestore
        .collection('darets')
        .doc(daretId)
        .collection('periods')
        .orderBy('index')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(DaretPeriodFirestoreMapper.fromSnapshot)
              .toList(growable: false);
        });
  }

  Stream<List<Contribution>> watchContributions(
    String daretId,
    int periodIndex,
  ) {
    return _firestore
        .collection('darets')
        .doc(daretId)
        .collection('periods')
        .doc(_periodId(periodIndex))
        .collection('contributions')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(ContributionFirestoreMapper.fromSnapshot)
              .toList(growable: false);
        });
  }

  Future<void> declarePaid({
    required String daretId,
    required int periodIndex,
    required String payerUid,
  }) {
    return _contribution(daretId, periodIndex, payerUid).update({
      'state': ContributionState.attente.firestoreValue,
      'paidDeclaredAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> confirmReceived({
    required String daretId,
    required int periodIndex,
    required String payerUid,
    required String confirmedByUid,
  }) {
    return _contribution(daretId, periodIndex, payerUid).update({
      'state': ContributionState.confirme.firestoreValue,
      'confirmedAt': FieldValue.serverTimestamp(),
      'confirmedByUid': confirmedByUid,
    });
  }

  DocumentReference<Map<String, dynamic>> _contribution(
    String daretId,
    int periodIndex,
    String payerUid,
  ) {
    return _firestore
        .collection('darets')
        .doc(daretId)
        .collection('periods')
        .doc(_periodId(periodIndex))
        .collection('contributions')
        .doc(payerUid);
  }

  String _periodId(int index) => index.toString().padLeft(2, '0');
}
