import 'package:json_annotation/json_annotation.dart';

enum MemoryOwnerType {
  @JsonValue('USER')
  user,
  @JsonValue('VENUE')
  venue,
}

enum MemoryContentType {
  @JsonValue('PHOTO')
  photo,
  @JsonValue('VIDEO')
  video,
  @JsonValue('TEXT')
  text,
}

enum MemoryMentionType {
  @JsonValue('USER')
  user,
  @JsonValue('VENUE')
  venue,
}

enum MemoryEngagementType {
  @JsonValue('POLL')
  poll,
  @JsonValue('QUESTION')
  question,
  @JsonValue('SLIDER')
  slider,
  @JsonValue('QUIZ')
  quiz,
}
