import 'package:json_annotation/json_annotation.dart';

part 'intent_response.g.dart';

@JsonSerializable(explicitToJson: false)
class IntentResponse {
  final String code;
  final String labelAr;
  final String labelEn;

  final String? color;

  final int sortOrder;
  final bool active;
  @JsonKey(defaultValue: <String>[])
  final List<String> vibeTagCodes;

  const IntentResponse({
    required this.code,
    required this.labelAr,
    required this.labelEn,
    this.color,
    required this.sortOrder,
    required this.active,
    this.vibeTagCodes = const [],
  });

  factory IntentResponse.fromJson(Map<String, dynamic> json) =>
      _$IntentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$IntentResponseToJson(this);
}
