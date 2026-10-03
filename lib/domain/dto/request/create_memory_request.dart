import 'package:json_annotation/json_annotation.dart';

import '../response/memory_enums.dart';

part 'create_memory_request.g.dart';

@JsonSerializable(explicitToJson: true, includeIfNull: false)
class CreateMemoryRequest {
  final MemoryContentType contentType;
  final String? mediaKey;
  final String? mediaThumbnailKey;
  final int? durationSeconds;
  final String? backgroundColor;
  final String? textContent;
  final String? textColor;
  final String? audioKey;
  final int? audioDurationSeconds;
  final List<MemoryMentionInput>? mentions;
  final EngagementConfig? engagement;

  const CreateMemoryRequest({
    required this.contentType,
    this.mediaKey,
    this.mediaThumbnailKey,
    this.durationSeconds,
    this.backgroundColor,
    this.textContent,
    this.textColor,
    this.audioKey,
    this.audioDurationSeconds,
    this.mentions,
    this.engagement,
  });

  factory CreateMemoryRequest.photo({
    required String mediaKey,
    String? audioKey,
    int? audioDurationSeconds,
    List<MemoryMentionInput>? mentions,
    EngagementConfig? engagement,
  }) => CreateMemoryRequest(
    contentType: MemoryContentType.photo,
    mediaKey: mediaKey,
    audioKey: audioKey,
    audioDurationSeconds: audioDurationSeconds,
    mentions: mentions,
    engagement: engagement,
  );

  factory CreateMemoryRequest.video({
    required String mediaKey,
    required int durationSeconds,
    String? mediaThumbnailKey,
    String? audioKey,
    int? audioDurationSeconds,
    List<MemoryMentionInput>? mentions,
    EngagementConfig? engagement,
  }) => CreateMemoryRequest(
    contentType: MemoryContentType.video,
    mediaKey: mediaKey,
    mediaThumbnailKey: mediaThumbnailKey,
    durationSeconds: durationSeconds,
    audioKey: audioKey,
    audioDurationSeconds: audioDurationSeconds,
    mentions: mentions,
    engagement: engagement,
  );

  factory CreateMemoryRequest.text({
    required String textContent,
    required String backgroundColor,
    String? textColor,
    String? audioKey,
    int? audioDurationSeconds,
    List<MemoryMentionInput>? mentions,
    EngagementConfig? engagement,
  }) => CreateMemoryRequest(
    contentType: MemoryContentType.text,
    textContent: textContent,
    backgroundColor: backgroundColor,
    textColor: textColor,
    audioKey: audioKey,
    audioDurationSeconds: audioDurationSeconds,
    mentions: mentions,
    engagement: engagement,
  );

  factory CreateMemoryRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateMemoryRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateMemoryRequestToJson(this);
}

@JsonSerializable(includeIfNull: false)
class MemoryMentionInput {
  final MemoryMentionType type;
  final String id;
  final Map<String, dynamic>? position;

  const MemoryMentionInput({
    required this.type,
    required this.id,
    this.position,
  });

  factory MemoryMentionInput.fromJson(Map<String, dynamic> json) =>
      _$MemoryMentionInputFromJson(json);

  Map<String, dynamic> toJson() => _$MemoryMentionInputToJson(this);
}

@JsonSerializable()
class EngagementConfig {
  final MemoryEngagementType type;
  final Map<String, dynamic> payload;

  const EngagementConfig({required this.type, required this.payload});

  factory EngagementConfig.fromJson(Map<String, dynamic> json) =>
      _$EngagementConfigFromJson(json);

  Map<String, dynamic> toJson() => _$EngagementConfigToJson(this);
}
