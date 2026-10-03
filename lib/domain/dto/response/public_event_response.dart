import 'package:hangout/domain/dto/response/public_event_media_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'public_event_response.g.dart';

@JsonSerializable(explicitToJson: true)
class PublicEventResponse {
  final String id;
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;

  final String startsAt;

  final String? endsAt;

  final String? externalUrl;

  final String? externalUrlLabel;

  final String? venueId;
  final String? venueNameAr;
  final String? venueNameEn;

  final PublicEventBranch? branch;

  final String? hangoutId;

  @JsonKey(defaultValue: 0)
  final int interestedCount;

  @JsonKey(defaultValue: false)
  final bool interestedByMe;

  @JsonKey(defaultValue: true)
  final bool active;

  final String? createdByAdminId;
  final String? createdByBusinessId;
  final String? createdAt;
  final String? updatedAt;

  @JsonKey(defaultValue: <PublicEventMediaResponse>[])
  final List<PublicEventMediaResponse> media;

  const PublicEventResponse({
    required this.id,
    required this.titleAr,
    required this.titleEn,
    this.descriptionAr,
    this.descriptionEn,
    required this.startsAt,
    this.endsAt,
    this.externalUrl,
    this.externalUrlLabel,
    this.venueId,
    this.venueNameAr,
    this.venueNameEn,
    this.branch,
    this.hangoutId,
    this.interestedCount = 0,
    this.interestedByMe = false,
    this.active = true,
    this.createdByAdminId,
    this.createdByBusinessId,
    this.createdAt,
    this.updatedAt,
    this.media = const [],
  });

  String? get coverUrl => media.isNotEmpty ? media.first.coverUrl : null;

  PublicEventResponse copyWithInterest({
    required bool interestedByMe,
    required int interestedCount,
  }) =>
      PublicEventResponse(
        id: id,
        titleAr: titleAr,
        titleEn: titleEn,
        descriptionAr: descriptionAr,
        descriptionEn: descriptionEn,
        startsAt: startsAt,
        endsAt: endsAt,
        externalUrl: externalUrl,
        externalUrlLabel: externalUrlLabel,
        venueId: venueId,
        venueNameAr: venueNameAr,
        venueNameEn: venueNameEn,
        branch: branch,
        hangoutId: hangoutId,
        interestedCount: interestedCount,
        interestedByMe: interestedByMe,
        active: active,
        createdByAdminId: createdByAdminId,
        createdByBusinessId: createdByBusinessId,
        createdAt: createdAt,
        updatedAt: updatedAt,
        media: media,
      );

  factory PublicEventResponse.fromJson(Map<String, dynamic> json) =>
      _$PublicEventResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PublicEventResponseToJson(this);
}

@JsonSerializable()
class PublicEventBranch {
  final String id;
  final String? labelAr;
  final String? labelEn;
  final String? addressAr;
  final String? addressEn;

  @JsonKey(defaultValue: false)
  final bool isPrimary;

  const PublicEventBranch({
    required this.id,
    this.labelAr,
    this.labelEn,
    this.addressAr,
    this.addressEn,
    this.isPrimary = false,
  });

  factory PublicEventBranch.fromJson(Map<String, dynamic> json) =>
      _$PublicEventBranchFromJson(json);

  Map<String, dynamic> toJson() => _$PublicEventBranchToJson(this);
}
