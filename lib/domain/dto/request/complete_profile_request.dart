import 'package:json_annotation/json_annotation.dart';

part 'complete_profile_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CompleteProfileRequest {
  final String? username;
  final String displayName;
  final String? bio;
  final String? city;
  final String? gender;
  final String? district;

  final int? cityId;
  final int? districtId;

  const CompleteProfileRequest({
    this.username,
    required this.displayName,
    this.bio,
    this.city,
    this.district,
    this.gender,
    this.cityId,
    this.districtId,
  });

  factory CompleteProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$CompleteProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CompleteProfileRequestToJson(this);
}
