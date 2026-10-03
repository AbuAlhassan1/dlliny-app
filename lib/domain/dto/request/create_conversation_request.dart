import 'package:json_annotation/json_annotation.dart';

import '../response/chat_enums.dart';

part 'create_conversation_request.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CreateConversationRequest {
  final ConversationType type;
  final List<Participant> participants;
  final String? title;
  final String? avatarUrl;

  const CreateConversationRequest({
    required this.type,
    required this.participants,
    this.title,
    this.avatarUrl,
  });

  factory CreateConversationRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateConversationRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateConversationRequestToJson(this);
}

@JsonSerializable()
class Participant {
  final ChatMemberType type;
  final String id;

  const Participant({required this.type, required this.id});

  factory Participant.fromJson(Map<String, dynamic> json) =>
      _$ParticipantFromJson(json);

  Map<String, dynamic> toJson() => _$ParticipantToJson(this);
}
