// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_message_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendMessageRequest _$SendMessageRequestFromJson(Map<String, dynamic> json) =>
    SendMessageRequest(
      contentType: $enumDecode(
        _$MessageContentTypeEnumMap,
        json['contentType'],
      ),
      content: json['content'] as String?,
      audioKey: json['audioKey'] as String?,
      audioDurationSeconds: (json['audioDurationSeconds'] as num?)?.toInt(),
      audioWaveform: json['audioWaveform'] as String?,
      sharedResourceType: $enumDecodeNullable(
        _$SharedResourceTypeEnumMap,
        json['sharedResourceType'],
      ),
      sharedResourceId: json['sharedResourceId'] as String?,
      replyToMessageId: json['replyToMessageId'] as String?,
    );

Map<String, dynamic> _$SendMessageRequestToJson(SendMessageRequest instance) =>
    <String, dynamic>{
      'contentType': _$MessageContentTypeEnumMap[instance.contentType]!,
      'content': ?instance.content,
      'audioKey': ?instance.audioKey,
      'audioDurationSeconds': ?instance.audioDurationSeconds,
      'audioWaveform': ?instance.audioWaveform,
      'sharedResourceType':
          ?_$SharedResourceTypeEnumMap[instance.sharedResourceType],
      'sharedResourceId': ?instance.sharedResourceId,
      'replyToMessageId': ?instance.replyToMessageId,
    };

const _$MessageContentTypeEnumMap = {
  MessageContentType.text: 'TEXT',
  MessageContentType.voice: 'VOICE',
  MessageContentType.share: 'SHARE',
};

const _$SharedResourceTypeEnumMap = {
  SharedResourceType.post: 'POST',
  SharedResourceType.hangout: 'HANGOUT',
  SharedResourceType.venue: 'VENUE',
  SharedResourceType.user: 'USER',
  SharedResourceType.memory: 'MEMORY',
};
