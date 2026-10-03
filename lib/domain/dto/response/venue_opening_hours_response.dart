import 'package:json_annotation/json_annotation.dart';

part 'venue_opening_hours_response.g.dart';

enum OpenState {
  @JsonValue('OPEN')
  open,
  @JsonValue('CLOSED')
  closed,
  @JsonValue('TEMPORARILY_CLOSED')
  temporarilyClosed,
  @JsonValue('PERMANENTLY_CLOSED')
  permanentlyClosed,
  @JsonValue('UNKNOWN')
  unknown,
}

enum HoursSource {
  @JsonValue('VENUE')
  venue,
  @JsonValue('BRANCH')
  branch,
  @JsonValue('NONE')
  none,
}

enum HoursDayKind {
  @JsonValue('CLOSED')
  closed,
  @JsonValue('OPEN_24H')
  open24h,
  @JsonValue('HOURS')
  hours,
}

extension HoursDayKindWire on HoursDayKind {
  String get wire => _$HoursDayKindEnumMap[this]!;
}

enum HoursSeason {
  @JsonValue('REGULAR')
  regular,
  @JsonValue('RAMADAN')
  ramadan,
}

abstract class VenueOperatingStatus {
  static const open = 'OPEN';
  static const temporarilyClosed = 'TEMPORARILY_CLOSED';
  static const permanentlyClosed = 'PERMANENTLY_CLOSED';
}

abstract class HoursScopeMode {
  static const own = 'OWN';
  static const inherit = 'INHERIT';
}

@JsonSerializable(explicitToJson: true)
class VenueOpeningHoursDto {
  final String timezone;

  final String evaluatedAt;

  final RamadanWindowDto? ramadanWindow;

  final ScopeHoursDto summary;

  @JsonKey(defaultValue: <ScopeHoursDto>[])
  final List<ScopeHoursDto> branches;

  const VenueOpeningHoursDto({
    required this.timezone,
    required this.evaluatedAt,
    this.ramadanWindow,
    required this.summary,
    this.branches = const [],
  });

  ScopeHoursDto? branch(String locationId) =>
      branches.where((b) => b.locationId == locationId).firstOrNull;

  ScopeHoursDto scopeFor(String? locationId) =>
      (locationId == null ? null : branch(locationId)) ?? summary;

  bool get variesByBranch => branches.any(
    (b) =>
        b.hoursSource == HoursSource.branch ||
        b.statusSource == HoursSource.branch,
  );

  factory VenueOpeningHoursDto.fromJson(Map<String, dynamic> json) =>
      _$VenueOpeningHoursDtoFromJson(json);

  Map<String, dynamic> toJson() => _$VenueOpeningHoursDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ScopeHoursDto {
  final String? locationId;

  @JsonKey(defaultValue: HoursSource.none, unknownEnumValue: HoursSource.none)
  final HoursSource hoursSource;

  @JsonKey(defaultValue: HoursSource.venue, unknownEnumValue: HoursSource.venue)
  final HoursSource statusSource;

  final String? operatingStatus;

  final String? reopensOn;

  final OpenStatusDto status;

  final TodayHoursDto? today;

  final TodayHoursDto? lastNight;

  final WeeklyScheduleDto? regular;
  final WeeklyScheduleDto? ramadan;

  final String? hoursUpdatedAt;

  const ScopeHoursDto({
    this.locationId,
    this.hoursSource = HoursSource.none,
    this.statusSource = HoursSource.venue,
    this.operatingStatus,
    this.reopensOn,
    required this.status,
    this.today,
    this.lastNight,
    this.regular,
    this.ramadan,
    this.hoursUpdatedAt,
  });

  factory ScopeHoursDto.fromJson(Map<String, dynamic> json) =>
      _$ScopeHoursDtoFromJson(json);

  Map<String, dynamic> toJson() => _$ScopeHoursDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OpenStatusDto {
  @JsonKey(defaultValue: OpenState.unknown, unknownEnumValue: OpenState.unknown)
  final OpenState state;

  final bool? openNow;

  @JsonKey(defaultValue: false)
  final bool closingSoon;

  @JsonKey(defaultValue: false)
  final bool openingSoon;

  @JsonKey(defaultValue: false)
  final bool alwaysOpen;

  final HoursMomentDto? closesAt;

  final HoursMomentDto? opensAt;

  final String? nextChangeAt;

  @JsonKey(
    defaultValue: HoursSeason.regular,
    unknownEnumValue: HoursSeason.regular,
  )
  final HoursSeason season;

  final String? reopensOn;

  final String? spanOperatingDate;

  @JsonKey(unknownEnumValue: HoursSeason.regular)
  final HoursSeason? spanSeason;

  const OpenStatusDto({
    this.state = OpenState.unknown,
    this.openNow,
    this.closingSoon = false,
    this.openingSoon = false,
    this.alwaysOpen = false,
    this.closesAt,
    this.opensAt,
    this.nextChangeAt,
    this.season = HoursSeason.regular,
    this.reopensOn,
    this.spanOperatingDate,
    this.spanSeason,
  });

  factory OpenStatusDto.fromJson(Map<String, dynamic> json) =>
      _$OpenStatusDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OpenStatusDtoToJson(this);
}

@JsonSerializable()
class HoursMomentDto {
  final String at;

  final String localTime;

  final String localDate;

  final int dayOfWeek;

  final int dayOffset;

  const HoursMomentDto({
    required this.at,
    required this.localTime,
    required this.localDate,
    required this.dayOfWeek,
    required this.dayOffset,
  });

  factory HoursMomentDto.fromJson(Map<String, dynamic> json) =>
      _$HoursMomentDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HoursMomentDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WeeklyScheduleDto {
  @JsonKey(defaultValue: <DayScheduleDto>[])
  final List<DayScheduleDto> days;

  const WeeklyScheduleDto({this.days = const []});

  DayScheduleDto? day(int dayOfWeek) =>
      days.where((d) => d.dayOfWeek == dayOfWeek).firstOrNull;

  factory WeeklyScheduleDto.fromJson(Map<String, dynamic> json) =>
      _$WeeklyScheduleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyScheduleDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DayScheduleDto {
  final int dayOfWeek;

  @JsonKey(
    defaultValue: HoursDayKind.closed,
    unknownEnumValue: HoursDayKind.closed,
  )
  final HoursDayKind kind;

  @JsonKey(defaultValue: <HoursIntervalDto>[])
  final List<HoursIntervalDto> intervals;

  const DayScheduleDto({
    required this.dayOfWeek,
    this.kind = HoursDayKind.closed,
    this.intervals = const [],
  });

  factory DayScheduleDto.fromJson(Map<String, dynamic> json) =>
      _$DayScheduleDtoFromJson(json);

  Map<String, dynamic> toJson() => _$DayScheduleDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class TodayHoursDto {
  final String date;

  final int dayOfWeek;

  @JsonKey(
    defaultValue: HoursSeason.regular,
    unknownEnumValue: HoursSeason.regular,
  )
  final HoursSeason season;

  @JsonKey(
    defaultValue: HoursDayKind.closed,
    unknownEnumValue: HoursDayKind.closed,
  )
  final HoursDayKind kind;

  @JsonKey(defaultValue: <HoursIntervalDto>[])
  final List<HoursIntervalDto> intervals;

  @JsonKey(defaultValue: <HoursIntervalDto>[])
  final List<HoursIntervalDto> ramadanEveIntervals;

  const TodayHoursDto({
    required this.date,
    required this.dayOfWeek,
    this.season = HoursSeason.regular,
    this.kind = HoursDayKind.closed,
    this.intervals = const [],
    this.ramadanEveIntervals = const [],
  });

  factory TodayHoursDto.fromJson(Map<String, dynamic> json) =>
      _$TodayHoursDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TodayHoursDtoToJson(this);
}

@JsonSerializable()
class HoursIntervalDto {
  final String opens;
  final String closes;

  @JsonKey(defaultValue: false)
  final bool overnight;

  const HoursIntervalDto({
    required this.opens,
    required this.closes,
    this.overnight = false,
  });

  factory HoursIntervalDto.fromJson(Map<String, dynamic> json) =>
      _$HoursIntervalDtoFromJson(json);

  Map<String, dynamic> toJson() => _$HoursIntervalDtoToJson(this);
}

@JsonSerializable()
class RamadanWindowDto {
  final String startsOn;
  final String endsOn;

  @JsonKey(defaultValue: false)
  final bool active;

  const RamadanWindowDto({
    required this.startsOn,
    required this.endsOn,
    this.active = false,
  });

  factory RamadanWindowDto.fromJson(Map<String, dynamic> json) =>
      _$RamadanWindowDtoFromJson(json);

  Map<String, dynamic> toJson() => _$RamadanWindowDtoToJson(this);
}
