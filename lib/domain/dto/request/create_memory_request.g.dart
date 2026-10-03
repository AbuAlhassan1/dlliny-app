// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_memory_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateMemoryRequest _$CreateMemoryRequestFromJson(Map<String, dynamic> json) =>
    CreateMemoryRequest(
      contentType: $enumDecode(_$MemoryContentTypeEnumMap, json['contentType']),
      mediaKey: json['mediaKey'] as String?,
      mediaThumbnailKey: json['mediaThumbnailKey'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
      backgroundColor: json['backgroundColor'] as String?,
      textContent: json['textContent'] as String?,
      textColor: json['textColor'] as String?,
      audioKey: json['audioKey'] as String?,
      audioDurationSeconds: (json['audioDurationSeconds'] as num?)?.toInt(),
      mentions: (json['mentions'] as List<dynamic>?)
          ?.map((e) => MemoryMentionInput.fromJson(e as Map<String, dynamic>))
          .toList(),
      engagement: json['engagement'] == null
          ? null
          : EngagementConfig.fromJson(
              json['engagement'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$CreateMemoryRequestToJson(
  CreateMemoryRequest instance,
) => <String, dynamic>{
  'contentType': _$MemoryContentTypeEnumMap[instance.contentType]!,
  'mediaKey': ?instance.mediaKey,
  'mediaThumbnailKey': ?instance.mediaThumbnailKey,
  'durationSeconds': ?instance.durationSeconds,
  'backgroundColor': ?instance.backgroundColor,
  'textContent': ?instance.textContent,
  'textColor': ?instance.textColor,
  'audioKey': ?instance.audioKey,
  'audioDurationSeconds': ?instance.audioDurationSeconds,
  'mentions': ?instance.mentions?.map((e) => e.toJson()).toList(),
  'engagement': ?instance.engagement?.toJson(),
};

const _$MemoryContentTypeEnumMap = {
  MemoryContentType.photo: 'PHOTO',
  MemoryContentType.video: 'VIDEO',
  MemoryContentType.text: 'TEXT',
};

MemoryMentionInput _$MemoryMentionInputFromJson(Map<String, dynamic> json) =>
    MemoryMentionInput(
      type: $enumDecode(_$MemoryMentionTypeEnumMap, json['type']),
      id: json['id'] as String,
      position: json['position'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$MemoryMentionInputToJson(MemoryMentionInput instance) =>
    <String, dynamic>{
      'type': _$MemoryMentionTypeEnumMap[instance.type]!,
      'id': instance.id,
      'position': ?instance.position,
    };

const _$MemoryMentionTypeEnumMap = {
  MemoryMentionType.user: 'USER',
  MemoryMentionType.venue: 'VENUE',
};

EngagementConfig _$EngagementConfigFromJson(Map<String, dynamic> json) =>
    EngagementConfig(
      type: $enumDecode(_$MemoryEngagementTypeEnumMap, json['type']),
      payload: json['payload'] as Map<String, dynamic>,
    );

Map<String, dynamic> _$EngagementConfigToJson(EngagementConfig instance) =>
    <String, dynamic>{
      'type': _$MemoryEngagementTypeEnumMap[instance.type]!,
      'payload': instance.payload,
    };

const _$MemoryEngagementTypeEnumMap = {
  MemoryEngagementType.poll: 'POLL',
  MemoryEngagementType.question: 'QUESTION',
  MemoryEngagementType.slider: 'SLIDER',
  MemoryEngagementType.quiz: 'QUIZ',
};
