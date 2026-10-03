// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_event_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicEventResponse _$PublicEventResponseFromJson(Map<String, dynamic> json) =>
    PublicEventResponse(
      id: json['id'] as String,
      titleAr: json['titleAr'] as String,
      titleEn: json['titleEn'] as String,
      descriptionAr: json['descriptionAr'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      startsAt: json['startsAt'] as String,
      endsAt: json['endsAt'] as String?,
      externalUrl: json['externalUrl'] as String?,
      externalUrlLabel: json['externalUrlLabel'] as String?,
      venueId: json['venueId'] as String?,
      venueNameAr: json['venueNameAr'] as String?,
      venueNameEn: json['venueNameEn'] as String?,
      branch: json['branch'] == null
          ? null
          : PublicEventBranch.fromJson(json['branch'] as Map<String, dynamic>),
      hangoutId: json['hangoutId'] as String?,
      interestedCount: (json['interestedCount'] as num?)?.toInt() ?? 0,
      interestedByMe: json['interestedByMe'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      createdByAdminId: json['createdByAdminId'] as String?,
      createdByBusinessId: json['createdByBusinessId'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      media:
          (json['media'] as List<dynamic>?)
              ?.map(
                (e) => PublicEventMediaResponse.fromJson(
                  e as Map<String, dynamic>,
                ),
              )
              .toList() ??
          [],
    );

Map<String, dynamic> _$PublicEventResponseToJson(
  PublicEventResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'titleAr': instance.titleAr,
  'titleEn': instance.titleEn,
  'descriptionAr': instance.descriptionAr,
  'descriptionEn': instance.descriptionEn,
  'startsAt': instance.startsAt,
  'endsAt': instance.endsAt,
  'externalUrl': instance.externalUrl,
  'externalUrlLabel': instance.externalUrlLabel,
  'venueId': instance.venueId,
  'venueNameAr': instance.venueNameAr,
  'venueNameEn': instance.venueNameEn,
  'branch': instance.branch?.toJson(),
  'hangoutId': instance.hangoutId,
  'interestedCount': instance.interestedCount,
  'interestedByMe': instance.interestedByMe,
  'active': instance.active,
  'createdByAdminId': instance.createdByAdminId,
  'createdByBusinessId': instance.createdByBusinessId,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'media': instance.media.map((e) => e.toJson()).toList(),
};

PublicEventBranch _$PublicEventBranchFromJson(Map<String, dynamic> json) =>
    PublicEventBranch(
      id: json['id'] as String,
      labelAr: json['labelAr'] as String?,
      labelEn: json['labelEn'] as String?,
      addressAr: json['addressAr'] as String?,
      addressEn: json['addressEn'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
    );

Map<String, dynamic> _$PublicEventBranchToJson(PublicEventBranch instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labelAr': instance.labelAr,
      'labelEn': instance.labelEn,
      'addressAr': instance.addressAr,
      'addressEn': instance.addressEn,
      'isPrimary': instance.isPrimary,
    };
