import 'package:json_annotation/json_annotation.dart';

part 'update_conversation_request.g.dart';

@JsonSerializable(includeIfNull: false)
class UpdateConversationRequest {
  final String? title;
  final String? avatarUrl;
  final int? retentionDays;

  const UpdateConversationRequest({
    this.title,
    this.avatarUrl,
    this.retentionDays,
  });

  factory UpdateConversationRequest.fromJson(Map<String, dynamic> json) =>
      _$UpdateConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateConversationRequestToJson(this);
}
