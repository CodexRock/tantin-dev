import 'package:freezed_annotation/freezed_annotation.dart';

part 'daret_models.freezed.dart';
part 'daret_models.g.dart';

@JsonEnum(valueField: 'firestoreValue')
enum DaretStatus {
  brouillon('brouillon'),
  attente('attente'),
  actif('actif'),
  termine('termine')
  ;

  const DaretStatus(this.firestoreValue);

  final String firestoreValue;
}

@JsonEnum(valueField: 'firestoreValue')
enum DaretFrequency {
  mensuel('Mensuel'),
  hebdomadaire('Hebdomadaire')
  ;

  const DaretFrequency(this.firestoreValue);

  final String firestoreValue;
}

@JsonEnum(valueField: 'firestoreValue')
enum MemberRole {
  admin('admin'),
  member('member')
  ;

  const MemberRole(this.firestoreValue);

  final String firestoreValue;
}

@JsonEnum(valueField: 'firestoreValue')
enum ApprovalStatus {
  pending('pending'),
  approved('approved')
  ;

  const ApprovalStatus(this.firestoreValue);

  final String firestoreValue;
}

@JsonEnum(valueField: 'firestoreValue')
enum PeriodStatus {
  upcoming('upcoming'),
  current('current'),
  closed('closed')
  ;

  const PeriodStatus(this.firestoreValue);

  final String firestoreValue;
}

@JsonEnum(valueField: 'firestoreValue')
enum ContributionState {
  apayer('apayer'),
  attente('attente'),
  confirme('confirme'),
  retard('retard'),
  recipient('recipient')
  ;

  const ContributionState(this.firestoreValue);

  final String firestoreValue;
}

@freezed
abstract class DaretSettings with _$DaretSettings {
  const factory DaretSettings({
    required int echeanceDay,
    required int graceDays,
  }) = _DaretSettings;

  factory DaretSettings.fromJson(Map<String, dynamic> json) =>
      _$DaretSettingsFromJson(json);
}

@freezed
abstract class Daret with _$Daret {
  const factory Daret({
    required String id,
    required String nom,
    required String cover,
    required String accent,
    required int montant,
    required DaretFrequency frequence,
    required int periodesCount,
    required int cagnotteParPeriode,
    required DaretStatus statut,
    required String adminUid,
    required List<String> memberUids,
    required int currentPeriode,
    required DaretSettings settings,
    DateTime? prochaineDate,
    String? inviteCode,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? closedAt,
  }) = _Daret;

  factory Daret.fromJson(Map<String, dynamic> json) => _$DaretFromJson(json);
}

@freezed
abstract class DaretMember with _$DaretMember {
  const factory DaretMember({
    required String uid,
    required MemberRole role,
    required ApprovalStatus approvalStatus,
    required String name,
    required String prenom,
    required String initials,
    required List<String> avatarPalette,
    DateTime? joinedAt,
    int? groupePart,
  }) = _DaretMember;

  factory DaretMember.fromJson(Map<String, dynamic> json) =>
      _$DaretMemberFromJson(json);
}

@freezed
abstract class DaretPeriod with _$DaretPeriod {
  const factory DaretPeriod({
    required String id,
    required int index,
    required List<String> recipientUids,
    required Map<String, int> shares,
    required DateTime scheduledDate,
    required int potAmount,
    required PeriodStatus status,
    required int paidCount,
    required int totalCount,
    DateTime? closedAt,
  }) = _DaretPeriod;

  factory DaretPeriod.fromJson(Map<String, dynamic> json) =>
      _$DaretPeriodFromJson(json);
}

@freezed
abstract class Contribution with _$Contribution {
  const factory Contribution({
    required String payerUid,
    required ContributionState state,
    required int amount,
    DateTime? paidDeclaredAt,
    DateTime? confirmedAt,
    String? confirmedByUid,
  }) = _Contribution;

  factory Contribution.fromJson(Map<String, dynamic> json) =>
      _$ContributionFromJson(json);
}

@freezed
abstract class DaretInvite with _$DaretInvite {
  const factory DaretInvite({
    required String code,
    required String daretId,
    required String createdByUid,
    required bool active,
    required DateTime expiresAt,
  }) = _DaretInvite;

  factory DaretInvite.fromJson(Map<String, dynamic> json) =>
      _$DaretInviteFromJson(json);
}
