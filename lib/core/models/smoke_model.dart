import 'package:freezed_annotation/freezed_annotation.dart';

part 'smoke_model.freezed.dart';
part 'smoke_model.g.dart';

@freezed
class SmokeModel with _$SmokeModel {
  const factory SmokeModel({
    required String id,
    required String name,
  }) = _SmokeModel;

  factory SmokeModel.fromJson(Map<String, dynamic> json) =>
      _$SmokeModelFromJson(json);
}
