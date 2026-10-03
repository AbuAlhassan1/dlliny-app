import 'package:json_annotation/json_annotation.dart';

part 'vibe_response.g.dart';

@JsonSerializable()
class VibeTagDto {
  final String code;
  final String nameAr;
  final String nameEn;

  final String dimension;
  final int sortOrder;

  const VibeTagDto({
    required this.code,
    required this.nameAr,
    required this.nameEn,
    required this.dimension,
    required this.sortOrder,
  });

  factory VibeTagDto.fromJson(Map<String, dynamic> json) =>
      _$VibeTagDtoFromJson(json);
  Map<String, dynamic> toJson() => _$VibeTagDtoToJson(this);
}

@JsonSerializable()
class UserVibeAffinityDto {
  final String tagCode;
  final String? nameAr;
  final String? nameEn;

  final String? dimension;

  final double score;

  final int sampleCount;

  const UserVibeAffinityDto({
    required this.tagCode,
    this.nameAr,
    this.nameEn,
    this.dimension,
    required this.score,
    required this.sampleCount,
  });

  factory UserVibeAffinityDto.fromJson(Map<String, dynamic> json) =>
      _$UserVibeAffinityDtoFromJson(json);
  Map<String, dynamic> toJson() => _$UserVibeAffinityDtoToJson(this);
}

@JsonSerializable()
class MyVibeProfileResponse {
  final bool needsOnboarding;
  @JsonKey(defaultValue: <String>[])
  final List<String> lovedTagCodes;
  @JsonKey(defaultValue: <String>[])
  final List<String> avoidedTagCodes;
  @JsonKey(defaultValue: <UserVibeAffinityDto>[])
  final List<UserVibeAffinityDto> affinities;

  const MyVibeProfileResponse({
    required this.needsOnboarding,
    this.lovedTagCodes = const [],
    this.avoidedTagCodes = const [],
    this.affinities = const [],
  });

  factory MyVibeProfileResponse.fromJson(Map<String, dynamic> json) =>
      _$MyVibeProfileResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MyVibeProfileResponseToJson(this);
}
