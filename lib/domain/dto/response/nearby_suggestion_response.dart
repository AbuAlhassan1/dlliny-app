import 'package:json_annotation/json_annotation.dart';

part 'nearby_suggestion_response.g.dart';

@JsonSerializable()
class NearbySuggestionResponse {
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final bool verified;

  final int mutualFollowers;

  final String? sharedVenueNameAr;
  final String? sharedVenueNameEn;

  const NearbySuggestionResponse({
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.verified = false,
    this.mutualFollowers = 0,
    this.sharedVenueNameAr,
    this.sharedVenueNameEn,
  });

  bool get hasSharedVenue =>
      (sharedVenueNameAr?.isNotEmpty ?? false) ||
      (sharedVenueNameEn?.isNotEmpty ?? false);

  factory NearbySuggestionResponse.fromJson(Map<String, dynamic> json) =>
      _$NearbySuggestionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$NearbySuggestionResponseToJson(this);
}
