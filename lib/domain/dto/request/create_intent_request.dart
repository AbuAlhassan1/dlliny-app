import 'package:json_annotation/json_annotation.dart';

part 'create_intent_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateIntentRequest {
  final String code;
  final String labelAr;
  final String labelEn;

  final String? color;

  final int? sortOrder;
  final bool? active;
  final List<String>? vibeTagCodes;

  const CreateIntentRequest({
    required this.code,
    required this.labelAr,
    required this.labelEn,
    this.color,
    this.sortOrder,
    this.active,
    this.vibeTagCodes,
  });

  factory CreateIntentRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateIntentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateIntentRequestToJson(this);
}
