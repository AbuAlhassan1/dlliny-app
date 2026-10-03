// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'business_venue_hours_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusinessVenueHoursResponse _$BusinessVenueHoursResponseFromJson(
  Map<String, dynamic> json,
) => BusinessVenueHoursResponse(
  venueId: json['venueId'] as String,
  timezone: json['timezone'] as String,
  evaluatedAt: json['evaluatedAt'] as String,
  today: json['today'] as String?,
  ramadanWindow: json['ramadanWindow'] == null
      ? null
      : RamadanWindowDto.fromJson(
          json['ramadanWindow'] as Map<String, dynamic>,
        ),
  venue: EditableScopeHoursDto.fromJson(json['venue'] as Map<String, dynamic>),
  branches:
      (json['branches'] as List<dynamic>?)
          ?.map(
            (e) => EditableScopeHoursDto.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$BusinessVenueHoursResponseToJson(
  BusinessVenueHoursResponse instance,
) => <String, dynamic>{
  'venueId': instance.venueId,
  'timezone': instance.timezone,
  'evaluatedAt': instance.evaluatedAt,
  'today': instance.today,
  'ramadanWindow': instance.ramadanWindow?.toJson(),
  'venue': instance.venue.toJson(),
  'branches': instance.branches.map((e) => e.toJson()).toList(),
};

EditableScopeHoursDto _$EditableScopeHoursDtoFromJson(
  Map<String, dynamic> json,
) => EditableScopeHoursDto(
  locationId: json['locationId'] as String?,
  labelAr: json['labelAr'] as String?,
  labelEn: json['labelEn'] as String?,
  districtNameAr: json['districtNameAr'] as String?,
  districtNameEn: json['districtNameEn'] as String?,
  isPrimary: json['isPrimary'] as bool? ?? false,
  hoursMode: json['hoursMode'] as String,
  statusMode: json['statusMode'] as String,
  operatingStatus: json['operatingStatus'] as String?,
  reopensOn: json['reopensOn'] as String?,
  statusExpired: json['statusExpired'] as bool? ?? false,
  regular: json['regular'] == null
      ? null
      : WeeklyScheduleDto.fromJson(json['regular'] as Map<String, dynamic>),
  ramadan: json['ramadan'] == null
      ? null
      : WeeklyScheduleDto.fromJson(json['ramadan'] as Map<String, dynamic>),
  effectiveStatus: OpenStatusDto.fromJson(
    json['effectiveStatus'] as Map<String, dynamic>,
  ),
  hoursUpdatedAt: json['hoursUpdatedAt'] as String?,
);

Map<String, dynamic> _$EditableScopeHoursDtoToJson(
  EditableScopeHoursDto instance,
) => <String, dynamic>{
  'locationId': instance.locationId,
  'labelAr': instance.labelAr,
  'labelEn': instance.labelEn,
  'districtNameAr': instance.districtNameAr,
  'districtNameEn': instance.districtNameEn,
  'isPrimary': instance.isPrimary,
  'hoursMode': instance.hoursMode,
  'statusMode': instance.statusMode,
  'operatingStatus': instance.operatingStatus,
  'reopensOn': instance.reopensOn,
  'statusExpired': instance.statusExpired,
  'regular': instance.regular?.toJson(),
  'ramadan': instance.ramadan?.toJson(),
  'effectiveStatus': instance.effectiveStatus.toJson(),
  'hoursUpdatedAt': instance.hoursUpdatedAt,
};
