import 'package:json_annotation/json_annotation.dart';

part 'update_intent_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateIntentRequest {
  final String? labelAr;
  final String? labelEn;

  final String? color;

  final int? sortOrder;
  final bool? active;
  final List<String>? vibeTagCodes;

  const UpdateIntentRequest({
    this.labelAr,
    this.labelEn,
    this.color,
    this.sortOrder,
    this.active,
    this.vibeTagCodes,
  });

  factory UpdateIntentRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateIntentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateIntentRequestToJson(this);
}
