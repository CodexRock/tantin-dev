import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DaretPreview {
  const DaretPreview({
    required this.daretId,
    required this.nom,
    required this.cover,
    required this.accent,
    required this.montant,
    required this.frequence,
    required this.periodesCount,
    required this.membersCount,
    required this.pendingInvitesCount,
    required this.statut,
  });

  factory DaretPreview.fromMap(Map<String, dynamic> data) {
    return DaretPreview(
      daretId: data['daretId'] as String,
      nom: data['nom'] as String,
      cover: data['cover'] as String,
      accent: data['accent'] as String,
      montant: data['montant'] as int,
      frequence: data['frequence'] as String,
      periodesCount: data['periodesCount'] as int,
      membersCount: data['membersCount'] as int,
      pendingInvitesCount: data['pendingInvitesCount'] as int? ?? 0,
      statut: data['statut'] as String,
    );
  }

  final String daretId;
  final String nom;
  final String cover;
  final String accent;
  final int montant;
  final String frequence;
  final int periodesCount;
  final int membersCount;
  final int pendingInvitesCount;
  final String statut;
}

class DaretCallableRepository {
  const DaretCallableRepository(this._functions, this._auth);

  final FirebaseFunctions _functions;
  final FirebaseAuth _auth;

  Future<void> startDaret(String daretId) {
    return _callVoid('startDaret', {'daretId': daretId});
  }

  Future<String> createInvite(String daretId) async {
    final data = await _callMap('createInvite', {'daretId': daretId});
    return data['code'] as String;
  }

  Future<DaretPreview> previewDaret(String code) async {
    final data = await _callMap('previewDaret', {'code': code});
    return DaretPreview.fromMap(data);
  }

  Future<String> joinDaret(String code) async {
    final data = await _callMap('joinDaret', {'code': code});
    return data['daretId'] as String;
  }

  Future<void> approveDaret(String daretId) {
    return _callVoid('approveDaret', {'daretId': daretId});
  }

  Future<void> advancePeriod(String daretId) {
    return _callVoid('advancePeriod', {'daretId': daretId});
  }

  Future<void> closePeriod(String daretId, int periodIndex) {
    return _callVoid(
      'closePeriod',
      {'daretId': daretId, 'periodIndex': periodIndex},
    );
  }

  Future<void> closeDaret(String daretId) {
    return _callVoid('closeDaret', {'daretId': daretId});
  }

  Future<void> sendNudge({
    required String daretId,
    required int periodIndex,
    required String targetUid,
  }) {
    return _callVoid(
      'sendNudge',
      {
        'daretId': daretId,
        'periodIndex': periodIndex,
        'targetUid': targetUid,
      },
    );
  }

  Future<void> reorderPeriods({
    required String daretId,
    required List<Map<String, dynamic>> periods,
  }) {
    return _callVoid('reorderPeriods', {
      'daretId': daretId,
      'periods': periods,
    });
  }

  /// Placeholder (re-invite) mode when [toUid] is null: returns the invite code
  /// for the freshly opened seat. Direct mode returns null.
  Future<String?> replaceMember({
    required String daretId,
    required String fromUid,
    String? toUid,
  }) async {
    final data = await _callMap('replaceMember', {
      'daretId': daretId,
      'fromUid': fromUid,
      'toUid': ?toUid,
    });
    return data['code'] as String?;
  }

  Future<void> editDaretDetails({
    required String daretId,
    String? nom,
    String? cover,
    String? accent,
  }) {
    return _callVoid('editDaretDetails', {
      'daretId': daretId,
      'nom': ?nom,
      'cover': ?cover,
      'accent': ?accent,
    });
  }

  Future<void> deleteDaret(String daretId) {
    return _callVoid('deleteDaret', {'daretId': daretId});
  }

  Future<void> seedDev() {
    return _callVoid('seedDev', {});
  }

  Future<void> _callVoid(String name, Map<String, dynamic> parameters) async {
    await _requireAuthToken();
    await _functions.httpsCallable(name).call<void>(parameters);
  }

  Future<Map<String, dynamic>> _callMap(
    String name,
    Map<String, dynamic> parameters,
  ) async {
    await _requireAuthToken();
    final result = await _functions
        .httpsCallable(name)
        .call<Object?>(
          parameters,
        );
    return Map<String, dynamic>.from(result.data! as Map<Object?, Object?>);
  }

  Future<void> _requireAuthToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError(
        'Utilisateur non connecté. Déconnectez-vous puis reconnectez-vous.',
      );
    }
    await user.getIdToken(true);
  }
}
