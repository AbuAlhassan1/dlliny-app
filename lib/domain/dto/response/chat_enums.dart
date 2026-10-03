import 'package:json_annotation/json_annotation.dart';

enum ConversationType {
  @JsonValue('DIRECT')
  direct,
  @JsonValue('GROUP')
  group,
}

enum ChatMemberType {
  @JsonValue('USER')
  user,
  @JsonValue('VENUE')
  venue,
}

enum ChatMemberRole {
  @JsonValue('MEMBER')
  member,
  @JsonValue('ADMIN')
  admin,
}

enum ChatRequestState {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
}

enum MessageContentType {
  @JsonValue('TEXT')
  text,
  @JsonValue('VOICE')
  voice,
  @JsonValue('SHARE')
  share,
}

enum SharedResourceType {
  @JsonValue('POST')
  post,
  @JsonValue('HANGOUT')
  hangout,
  @JsonValue('VENUE')
  venue,
  @JsonValue('USER')
  user,
  @JsonValue('MEMORY')
  memory,
}
