// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'venue_opening_hours_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VenueOpeningHoursDto _$VenueOpeningHoursDtoFromJson(
  Map<String, dynamic> json,
) => VenueOpeningHoursDto(
  timezone: json['timezone'] as String,
  evaluatedAt: json['evaluatedAt'] as String,
  ramadanWindow: json['ramadanWindow'] == null
      ? null
      : RamadanWindowDto.fromJson(
          json['ramadanWindow'] as Map<String, dynamic>,
        ),
  summary: ScopeHoursDto.fromJson(json['summary'] as Map<String, dynamic>),
  branches:
      (json['branches'] as List<dynamic>?)
          ?.map((e) => ScopeHoursDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$VenueOpeningHoursDtoToJson(
  VenueOpeningHoursDto instance,
) => <String, dynamic>{
  'timezone': instance.timezone,
  'evaluatedAt': instance.evaluatedAt,
  'ramadanWindow': instance.ramadanWindow?.toJson(),
  'summary': instance.summary.toJson(),
  'branches': instance.branches.map((e) => e.toJson()).toList(),
};

ScopeHoursDto _$ScopeHoursDtoFromJson(Map<String, dynamic> json) =>
    ScopeHoursDto(
      locationId: json['locationId'] as String?,
      hoursSource:
          $enumDecodeNullable(
            _$HoursSourceEnumMap,
            json['hoursSource'],
            unknownValue: HoursSource.none,
          ) ??
          HoursSource.none,
      statusSource:
          $enumDecodeNullable(
            _$HoursSourceEnumMap,
            json['statusSource'],
            unknownValue: HoursSource.venue,
          ) ??
          HoursSource.venue,
      operatingStatus: json['operatingStatus'] as String?,
      reopensOn: json['reopensOn'] as String?,
      status: OpenStatusDto.fromJson(json['status'] as Map<String, dynamic>),
      today: json['today'] == null
          ? null
          : TodayHoursDto.fromJson(json['today'] as Map<String, dynamic>),
      lastNight: json['lastNight'] == null
          ? null
          : TodayHoursDto.fromJson(json['lastNight'] as Map<String, dynamic>),
      regular: json['regular'] == null
          ? null
          : WeeklyScheduleDto.fromJson(json['regular'] as Map<String, dynamic>),
      ramadan: json['ramadan'] == null
          ? null
          : WeeklyScheduleDto.fromJson(json['ramadan'] as Map<String, dynamic>),
      hoursUpdatedAt: json['hoursUpdatedAt'] as String?,
    );

Map<String, dynamic> _$ScopeHoursDtoToJson(ScopeHoursDto instance) =>
    <String, dynamic>{
      'locationId': instance.locationId,
      'hoursSource': _$HoursSourceEnumMap[instance.hoursSource]!,
      'statusSource': _$HoursSourceEnumMap[instance.statusSource]!,
      'operatingStatus': instance.operatingStatus,
      'reopensOn': instance.reopensOn,
      'status': instance.status.toJson(),
      'today': instance.today?.toJson(),
      'lastNight': instance.lastNight?.toJson(),
      'regular': instance.regular?.toJson(),
      'ramadan': instance.ramadan?.toJson(),
      'hoursUpdatedAt': instance.hoursUpdatedAt,
    };

const _$HoursSourceEnumMap = {
  HoursSource.venue: 'VENUE',
  HoursSource.branch: 'BRANCH',
  HoursSource.none: 'NONE',
};

OpenStatusDto _$OpenStatusDtoFromJson(Map<String, dynamic> json) =>
    OpenStatusDto(
      state:
          $enumDecodeNullable(
            _$OpenStateEnumMap,
            json['state'],
            unknownValue: OpenState.unknown,
          ) ??
          OpenState.unknown,
      openNow: json['openNow'] as bool?,
      closingSoon: json['closingSoon'] as bool? ?? false,
      openingSoon: json['openingSoon'] as bool? ?? false,
      alwaysOpen: json['alwaysOpen'] as bool? ?? false,
      closesAt: json['closesAt'] == null
          ? null
          : HoursMomentDto.fromJson(json['closesAt'] as Map<String, dynamic>),
      opensAt: json['opensAt'] == null
          ? null
          : HoursMomentDto.fromJson(json['opensAt'] as Map<String, dynamic>),
      nextChangeAt: json['nextChangeAt'] as String?,
      season:
          $enumDecodeNullable(
            _$HoursSeasonEnumMap,
            json['season'],
            unknownValue: HoursSeason.regular,
          ) ??
          HoursSeason.regular,
      reopensOn: json['reopensOn'] as String?,
      spanOperatingDate: json['spanOperatingDate'] as String?,
      spanSeason: $enumDecodeNullable(
        _$HoursSeasonEnumMap,
        json['spanSeason'],
        unknownValue: HoursSeason.regular,
      ),
    );

Map<String, dynamic> _$OpenStatusDtoToJson(OpenStatusDto instance) =>
    <String, dynamic>{
      'state': _$OpenStateEnumMap[instance.state]!,
      'openNow': instance.openNow,
      'closingSoon': instance.closingSoon,
      'openingSoon': instance.openingSoon,
      'alwaysOpen': instance.alwaysOpen,
      'closesAt': instance.closesAt?.toJson(),
      'opensAt': instance.opensAt?.toJson(),
      'nextChangeAt': instance.nextChangeAt,
      'season': _$HoursSeasonEnumMap[instance.season]!,
      'reopensOn': instance.reopensOn,
      'spanOperatingDate': instance.spanOperatingDate,
      'spanSeason': _$HoursSeasonEnumMap[instance.spanSeason],
    };

const _$OpenStateEnumMap = {
  OpenState.open: 'OPEN',
  OpenState.closed: 'CLOSED',
  OpenState.temporarilyClosed: 'TEMPORARILY_CLOSED',
  OpenState.permanentlyClosed: 'PERMANENTLY_CLOSED',
  OpenState.unknown: 'UNKNOWN',
};

const _$HoursSeasonEnumMap = {
  HoursSeason.regular: 'REGULAR',
  HoursSeason.ramadan: 'RAMADAN',
};

HoursMomentDto _$HoursMomentDtoFromJson(Map<String, dynamic> json) =>
    HoursMomentDto(
      at: json['at'] as String,
      localTime: json['localTime'] as String,
      localDate: json['localDate'] as String,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      dayOffset: (json['dayOffset'] as num).toInt(),
    );

Map<String, dynamic> _$HoursMomentDtoToJson(HoursMomentDto instance) =>
    <String, dynamic>{
      'at': instance.at,
      'localTime': instance.localTime,
      'localDate': instance.localDate,
      'dayOfWeek': instance.dayOfWeek,
      'dayOffset': instance.dayOffset,
    };

WeeklyScheduleDto _$WeeklyScheduleDtoFromJson(Map<String, dynamic> json) =>
    WeeklyScheduleDto(
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => DayScheduleDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$WeeklyScheduleDtoToJson(WeeklyScheduleDto instance) =>
    <String, dynamic>{'days': instance.days.map((e) => e.toJson()).toList()};

DayScheduleDto _$DayScheduleDtoFromJson(Map<String, dynamic> json) =>
    DayScheduleDto(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      kind:
          $enumDecodeNullable(
            _$HoursDayKindEnumMap,
            json['kind'],
            unknownValue: HoursDayKind.closed,
          ) ??
          HoursDayKind.closed,
      intervals:
          (json['intervals'] as List<dynamic>?)
              ?.map((e) => HoursIntervalDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$DayScheduleDtoToJson(DayScheduleDto instance) =>
    <String, dynamic>{
      'dayOfWeek': instance.dayOfWeek,
      'kind': _$HoursDayKindEnumMap[instance.kind]!,
      'intervals': instance.intervals.map((e) => e.toJson()).toList(),
    };

const _$HoursDayKindEnumMap = {
  HoursDayKind.closed: 'CLOSED',
  HoursDayKind.open24h: 'OPEN_24H',
  HoursDayKind.hours: 'HOURS',
};

TodayHoursDto _$TodayHoursDtoFromJson(Map<String, dynamic> json) =>
    TodayHoursDto(
      date: json['date'] as String,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      season:
          $enumDecodeNullable(
            _$HoursSeasonEnumMap,
            json['season'],
            unknownValue: HoursSeason.regular,
          ) ??
          HoursSeason.regular,
      kind:
          $enumDecodeNullable(
            _$HoursDayKindEnumMap,
            json['kind'],
            unknownValue: HoursDayKind.closed,
          ) ??
          HoursDayKind.closed,
      intervals:
          (json['intervals'] as List<dynamic>?)
              ?.map((e) => HoursIntervalDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      ramadanEveIntervals:
          (json['ramadanEveIntervals'] as List<dynamic>?)
              ?.map((e) => HoursIntervalDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$TodayHoursDtoToJson(TodayHoursDto instance) =>
    <String, dynamic>{
      'date': instance.date,
      'dayOfWeek': instance.dayOfWeek,
      'season': _$HoursSeasonEnumMap[instance.season]!,
      'kind': _$HoursDayKindEnumMap[instance.kind]!,
      'intervals': instance.intervals.map((e) => e.toJson()).toList(),
      'ramadanEveIntervals': instance.ramadanEveIntervals
          .map((e) => e.toJson())
          .toList(),
    };

HoursIntervalDto _$HoursIntervalDtoFromJson(Map<String, dynamic> json) =>
    HoursIntervalDto(
      opens: json['opens'] as String,
      closes: json['closes'] as String,
      overnight: json['overnight'] as bool? ?? false,
    );

Map<String, dynamic> _$HoursIntervalDtoToJson(HoursIntervalDto instance) =>
    <String, dynamic>{
      'opens': instance.opens,
      'closes': instance.closes,
      'overnight': instance.overnight,
    };

RamadanWindowDto _$RamadanWindowDtoFromJson(Map<String, dynamic> json) =>
    RamadanWindowDto(
      startsOn: json['startsOn'] as String,
      endsOn: json['endsOn'] as String,
      active: json['active'] as bool? ?? false,
    );

Map<String, dynamic> _$RamadanWindowDtoToJson(RamadanWindowDto instance) =>
    <String, dynamic>{
      'startsOn': instance.startsOn,
      'endsOn': instance.endsOn,
      'active': instance.active,
    };
