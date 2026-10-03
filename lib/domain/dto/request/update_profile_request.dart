import 'package:json_annotation/json_annotation.dart';

part 'update_profile_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateProfileRequest {
  final String? displayName;
  final String? bio;
  final String? city;
  final String? district;
  final String? preferredLang;

  final bool? isPrivate;

  final int? cityId;

  final int? districtId;

  const UpdateProfileRequest({
    this.displayName,
    this.bio,
    this.city,
    this.district,
    this.preferredLang,
    this.isPrivate,
    this.cityId,
    this.districtId,
  });

  factory UpdateProfileRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateProfileRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateProfileRequestToJson(this);
}
