import 'package:json_annotation/json_annotation.dart';

part 'mute_conversation_request.g.dart';

@JsonSerializable()
class MuteConversationRequest {
  final bool muted;

  const MuteConversationRequest({required this.muted});

  factory MuteConversationRequest.fromJson(Map<String, dynamic> json) =>
      _$MuteConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MuteConversationRequestToJson(this);
}
