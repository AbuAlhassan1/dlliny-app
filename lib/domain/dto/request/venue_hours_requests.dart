import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'venue_hours_requests.g.dart';

bool? _trueOrNull(bool value) => value ? true : null;

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpdateVenueHoursRequest {
  final WeeklyScheduleInput regular;
  final WeeklyScheduleInput? ramadan;

  @JsonKey(toJson: _trueOrNull)
  final bool removeRamadan;

  const UpdateVenueHoursRequest({
    required this.regular,
    this.ramadan,
    this.removeRamadan = false,
  });

  factory UpdateVenueHoursRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateVenueHoursRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateVenueHoursRequestToJson(this);
}

@JsonSerializable(includeIfNull: false, explicitToJson: true)
class UpdateBranchHoursRequest {
  final String mode;
  final WeeklyScheduleInput? regular;
  final WeeklyScheduleInput? ramadan;

  @JsonKey(toJson: _trueOrNull)
  final bool removeRamadan;

  const UpdateBranchHoursRequest({
    required this.mode,
    this.regular,
    this.ramadan,
    this.removeRamadan = false,
  });

  factory UpdateBranchHoursRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateBranchHoursRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateBranchHoursRequestToJson(this);
}

@JsonSerializable(explicitToJson: true)
class WeeklyScheduleInput {
  final List<HoursDayInput> days;

  const WeeklyScheduleInput({required this.days});

  factory WeeklyScheduleInput.fromDto(WeeklyScheduleDto dto) =>
      WeeklyScheduleInput(
        days: [
          for (final d in dto.days)
            HoursDayInput(
              dayOfWeek: d.dayOfWeek,
              kind: d.kind.wire,
              intervals: [
                for (final i in d.intervals)
                  HoursIntervalInput(opens: i.opens, closes: i.closes),
              ],
            ),
        ],
      );

  factory WeeklyScheduleInput.fromJson(Map<String, dynamic> json) =>
      _$WeeklyScheduleInputFromJson(json);
  Map<String, dynamic> toJson() => _$WeeklyScheduleInputToJson(this);
}

@JsonSerializable(explicitToJson: true)
class HoursDayInput {
  final int dayOfWeek;

  final String kind;

  final List<HoursIntervalInput> intervals;

  const HoursDayInput({
    required this.dayOfWeek,
    required this.kind,
    this.intervals = const [],
  });

  factory HoursDayInput.fromJson(Map<String, dynamic> json) =>
      _$HoursDayInputFromJson(json);
  Map<String, dynamic> toJson() => _$HoursDayInputToJson(this);
}

@JsonSerializable()
class HoursIntervalInput {
  final String opens;
  final String closes;

  const HoursIntervalInput({required this.opens, required this.closes});

  factory HoursIntervalInput.fromJson(Map<String, dynamic> json) =>
      _$HoursIntervalInputFromJson(json);
  Map<String, dynamic> toJson() => _$HoursIntervalInputToJson(this);
}

@JsonSerializable(includeIfNull: false)
class UpdateOperatingStatusRequest {
  final String status;

  final String? reopensOn;

  const UpdateOperatingStatusRequest({required this.status, this.reopensOn});

  factory UpdateOperatingStatusRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateOperatingStatusRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateOperatingStatusRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class UpdateBranchOperatingStatusRequest {
  final String mode;
  final String? status;
  final String? reopensOn;

  const UpdateBranchOperatingStatusRequest({
    required this.mode,
    this.status,
    this.reopensOn,
  });

  factory UpdateBranchOperatingStatusRequest.fromJson(
    Map<String, dynamic> json,
  ) => _$UpdateBranchOperatingStatusRequestFromJson(json);
  Map<String, dynamic> toJson() =>
      _$UpdateBranchOperatingStatusRequestToJson(this);
}
