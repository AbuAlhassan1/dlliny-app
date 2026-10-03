// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_hours_requests.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateVenueHoursRequest _$UpdateVenueHoursRequestFromJson(
  Map<String, dynamic> json,
) => UpdateVenueHoursRequest(
  regular: WeeklyScheduleInput.fromJson(
    json['regular'] as Map<String, dynamic>,
  ),
  ramadan: json['ramadan'] == null
      ? null
      : WeeklyScheduleInput.fromJson(json['ramadan'] as Map<String, dynamic>),
  removeRamadan: json['removeRamadan'] as bool? ?? false,
);

Map<String, dynamic> _$UpdateVenueHoursRequestToJson(
  UpdateVenueHoursRequest instance,
) => <String, dynamic>{
  'regular': instance.regular.toJson(),
  'ramadan': ?instance.ramadan?.toJson(),
  'removeRamadan': ?_trueOrNull(instance.removeRamadan),
};

UpdateBranchHoursRequest _$UpdateBranchHoursRequestFromJson(
  Map<String, dynamic> json,
) => UpdateBranchHoursRequest(
  mode: json['mode'] as String,
  regular: json['regular'] == null
      ? null
      : WeeklyScheduleInput.fromJson(json['regular'] as Map<String, dynamic>),
  ramadan: json['ramadan'] == null
      ? null
      : WeeklyScheduleInput.fromJson(json['ramadan'] as Map<String, dynamic>),
  removeRamadan: json['removeRamadan'] as bool? ?? false,
);

Map<String, dynamic> _$UpdateBranchHoursRequestToJson(
  UpdateBranchHoursRequest instance,
) => <String, dynamic>{
  'mode': instance.mode,
  'regular': ?instance.regular?.toJson(),
  'ramadan': ?instance.ramadan?.toJson(),
  'removeRamadan': ?_trueOrNull(instance.removeRamadan),
};

WeeklyScheduleInput _$WeeklyScheduleInputFromJson(Map<String, dynamic> json) =>
    WeeklyScheduleInput(
      days: (json['days'] as List<dynamic>)
          .map((e) => HoursDayInput.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WeeklyScheduleInputToJson(
  WeeklyScheduleInput instance,
) => <String, dynamic>{'days': instance.days.map((e) => e.toJson()).toList()};

HoursDayInput _$HoursDayInputFromJson(Map<String, dynamic> json) =>
    HoursDayInput(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      kind: json['kind'] as String,
      intervals:
          (json['intervals'] as List<dynamic>?)
              ?.map(
                (e) => HoursIntervalInput.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );

Map<String, dynamic> _$HoursDayInputToJson(HoursDayInput instance) =>
    <String, dynamic>{
      'dayOfWeek': instance.dayOfWeek,
      'kind': instance.kind,
      'intervals': instance.intervals.map((e) => e.toJson()).toList(),
    };

HoursIntervalInput _$HoursIntervalInputFromJson(Map<String, dynamic> json) =>
    HoursIntervalInput(
      opens: json['opens'] as String,
      closes: json['closes'] as String,
    );

Map<String, dynamic> _$HoursIntervalInputToJson(HoursIntervalInput instance) =>
    <String, dynamic>{'opens': instance.opens, 'closes': instance.closes};

UpdateOperatingStatusRequest _$UpdateOperatingStatusRequestFromJson(
  Map<String, dynamic> json,
) => UpdateOperatingStatusRequest(
  status: json['status'] as String,
  reopensOn: json['reopensOn'] as String?,
);

Map<String, dynamic> _$UpdateOperatingStatusRequestToJson(
  UpdateOperatingStatusRequest instance,
) => <String, dynamic>{
  'status': instance.status,
  'reopensOn': ?instance.reopensOn,
};

UpdateBranchOperatingStatusRequest _$UpdateBranchOperatingStatusRequestFromJson(
  Map<String, dynamic> json,
) => UpdateBranchOperatingStatusRequest(
  mode: json['mode'] as String,
  status: json['status'] as String?,
  reopensOn: json['reopensOn'] as String?,
);

Map<String, dynamic> _$UpdateBranchOperatingStatusRequestToJson(
  UpdateBranchOperatingStatusRequest instance,
) => <String, dynamic>{
  'mode': instance.mode,
  'status': ?instance.status,
  'reopensOn': ?instance.reopensOn,
};
