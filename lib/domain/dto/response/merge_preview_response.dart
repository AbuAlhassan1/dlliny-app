import 'package:json_annotation/json_annotation.dart';

part 'merge_preview_response.g.dart';

@JsonSerializable(explicitToJson: true)
class MergePreviewResponse {
  final String ghostUserId;
  final String realUserId;

  final int postsToMigrate;
  final int hangoutsToMigrate;
  final int hangoutInvitationsToMigrate;
  final int hangoutMediaToMigrate;
  final int followersToMigrate;
  final int followingsToMigrate;

  final FieldComparison username;
  final FieldComparison displayName;
  final FieldComparison bio;
  final FieldComparison avatarUrl;
  final FieldComparison coverUrl;

  const MergePreviewResponse({
    required this.ghostUserId,
    required this.realUserId,
    required this.postsToMigrate,
    required this.hangoutsToMigrate,
    required this.hangoutInvitationsToMigrate,
    required this.hangoutMediaToMigrate,
    required this.followersToMigrate,
    required this.followingsToMigrate,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
    required this.coverUrl,
  });

  factory MergePreviewResponse.fromJson(Map<String, dynamic> json) =>
      _$MergePreviewResponseFromJson(json);
  Map<String, dynamic> toJson() => _$MergePreviewResponseToJson(this);
}

@JsonSerializable()
class FieldComparison {
  final String? ghostValue;
  final String? realValue;

  const FieldComparison({this.ghostValue, this.realValue});

  factory FieldComparison.fromJson(Map<String, dynamic> json) =>
      _$FieldComparisonFromJson(json);
  Map<String, dynamic> toJson() => _$FieldComparisonToJson(this);
}
