import 'package:json_annotation/json_annotation.dart';

part 'set_intent_vibe_tags_request.g.dart';

@JsonSerializable()
class SetIntentVibeTagsRequest {
  final List<String> vibeTagCodes;

  const SetIntentVibeTagsRequest({required this.vibeTagCodes});

  factory SetIntentVibeTagsRequest.fromJson(Map<String, dynamic> json) =>
      _$SetIntentVibeTagsRequestFromJson(json);
  Map<String, dynamic> toJson() => _$SetIntentVibeTagsRequestToJson(this);
}
