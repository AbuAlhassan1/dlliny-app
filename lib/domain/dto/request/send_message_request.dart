import 'package:json_annotation/json_annotation.dart';

import '../response/chat_enums.dart';

part 'send_message_request.g.dart';

@JsonSerializable(includeIfNull: false)
class SendMessageRequest {
  final MessageContentType contentType;
  final String? content;
  final String? audioKey;
  final int? audioDurationSeconds;
  final String? audioWaveform;
  final SharedResourceType? sharedResourceType;
  final String? sharedResourceId;
  final String? replyToMessageId;

  const SendMessageRequest({
    required this.contentType,
    this.content,
    this.audioKey,
    this.audioDurationSeconds,
    this.audioWaveform,
    this.sharedResourceType,
    this.sharedResourceId,
    this.replyToMessageId,
  });

  factory SendMessageRequest.text(String content, {String? replyTo}) =>
      SendMessageRequest(
        contentType: MessageContentType.text,
        content: content,
        replyToMessageId: replyTo,
      );

  factory SendMessageRequest.voice({
    required String audioKey,
    required int audioDurationSeconds,
    String? audioWaveform,
    String? replyTo,
  }) => SendMessageRequest(
    contentType: MessageContentType.voice,
    audioKey: audioKey,
    audioDurationSeconds: audioDurationSeconds,
    audioWaveform: audioWaveform,
    replyToMessageId: replyTo,
  );

  factory SendMessageRequest.share({
    required SharedResourceType resourceType,
    required String resourceId,
    String? caption,
    String? replyTo,
  }) => SendMessageRequest(
    contentType: MessageContentType.share,
    sharedResourceType: resourceType,
    sharedResourceId: resourceId,
    content: caption,
    replyToMessageId: replyTo,
  );

  factory SendMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendMessageRequestToJson(this);
}
