import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_user.freezed.dart';
part 'app_user.g.dart';

@freezed
abstract class NotificationPreferences with _$NotificationPreferences {
  const factory NotificationPreferences({
    @Default(true) bool contributions,
    @Default(true) bool reminders,
    @Default(true) bool turns,
  }) = _NotificationPreferences;

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) =>
      _$NotificationPreferencesFromJson(json);
}

@freezed
abstract class UserSettings with _$UserSettings {
  const factory UserSettings({
    @Default(5) int defaultEcheanceDay,
    @Default(2) int graceDays,
    @Default('fr') String lang,
    @Default(NotificationPreferences()) NotificationPreferences notifPrefs,
  }) = _UserSettings;

  factory UserSettings.fromJson(Map<String, dynamic> json) =>
      _$UserSettingsFromJson(json);
}

@freezed
abstract class UserStats with _$UserStats {
  const factory UserStats({
    @Default(0) int daretsActifs,
    @Default(0) int totalRecuVie,
  }) = _UserStats;

  factory UserStats.fromJson(Map<String, dynamic> json) =>
      _$UserStatsFromJson(json);
}

@freezed
abstract class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String prenom,
    required String nom,
    required String name,
    required String initials,
    required String phone,
    required List<String> avatarPalette,
    @Default(<String>[]) List<String> fcmTokens,
    @Default(UserSettings()) UserSettings settings,
    @Default(UserStats()) UserStats stats,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}
