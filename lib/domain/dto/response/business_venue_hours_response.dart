import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'business_venue_hours_response.g.dart';

@JsonSerializable(explicitToJson: true)
class BusinessVenueHoursResponse {
  final String venueId;

  final String timezone;

  final String evaluatedAt;

  final String? today;

  final RamadanWindowDto? ramadanWindow;

  final EditableScopeHoursDto venue;

  @JsonKey(defaultValue: <EditableScopeHoursDto>[])
  final List<EditableScopeHoursDto> branches;

  const BusinessVenueHoursResponse({
    required this.venueId,
    required this.timezone,
    required this.evaluatedAt,
    this.today,
    this.ramadanWindow,
    required this.venue,
    this.branches = const [],
  });

  String get baghdadToday => today ?? evaluatedAt.substring(0, 10);

  EditableScopeHoursDto? branch(String locationId) =>
      branches.where((b) => b.locationId == locationId).firstOrNull;

  factory BusinessVenueHoursResponse.fromJson(Map<String, dynamic> json) =>
      _$BusinessVenueHoursResponseFromJson(json);

  Map<String, dynamic> toJson() => _$BusinessVenueHoursResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class EditableScopeHoursDto {
  final String? locationId;
  final String? labelAr;
  final String? labelEn;

  final String? districtNameAr;
  final String? districtNameEn;

  @JsonKey(defaultValue: false)
  final bool isPrimary;

  final String hoursMode;
  final String statusMode;

  final String? operatingStatus;
  final String? reopensOn;

  @JsonKey(defaultValue: false)
  final bool statusExpired;

  final WeeklyScheduleDto? regular;
  final WeeklyScheduleDto? ramadan;

  final OpenStatusDto effectiveStatus;

  final String? hoursUpdatedAt;

  const EditableScopeHoursDto({
    this.locationId,
    this.labelAr,
    this.labelEn,
    this.districtNameAr,
    this.districtNameEn,
    this.isPrimary = false,
    required this.hoursMode,
    required this.statusMode,
    this.operatingStatus,
    this.reopensOn,
    this.statusExpired = false,
    this.regular,
    this.ramadan,
    required this.effectiveStatus,
    this.hoursUpdatedAt,
  });

  bool get ownsHours => hoursMode == HoursScopeMode.own;
  bool get ownsStatus => statusMode == HoursScopeMode.own;

  factory EditableScopeHoursDto.fromJson(Map<String, dynamic> json) =>
      _$EditableScopeHoursDtoFromJson(json);

  Map<String, dynamic> toJson() => _$EditableScopeHoursDtoToJson(this);
}
