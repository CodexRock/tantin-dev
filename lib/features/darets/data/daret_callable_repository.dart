import 'package:cloud_functions/cloud_functions.dart';

class DaretCallableRepository {
  const DaretCallableRepository(this._functions);

  final FirebaseFunctions _functions;

  Future<void> startDaret(String daretId) {
    return _callVoid('startDaret', {'daretId': daretId});
  }

  Future<String> createInvite(String daretId) async {
    final data = await _callMap('createInvite', {'daretId': daretId});
    return data['code'] as String;
  }

  Future<Map<String, dynamic>> previewDaret(String code) {
    return _callMap('previewDaret', {'code': code});
  }

  Future<void> joinDaret(String code) {
    return _callVoid('joinDaret', {'code': code});
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

  Future<void> seedDev() {
    return _callVoid('seedDev', {});
  }

  Future<void> _callVoid(String name, Map<String, dynamic> parameters) async {
    await _functions.httpsCallable(name).call<void>(parameters);
  }

  Future<Map<String, dynamic>> _callMap(
    String name,
    Map<String, dynamic> parameters,
  ) async {
    final result = await _functions
        .httpsCallable(name)
        .call<Object?>(
          parameters,
        );
    return Map<String, dynamic>.from(result.data! as Map<Object?, Object?>);
  }
}
