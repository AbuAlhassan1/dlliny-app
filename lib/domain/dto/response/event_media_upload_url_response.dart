import 'package:json_annotation/json_annotation.dart';

part 'event_media_upload_url_response.g.dart';

@JsonSerializable()
class EventMediaUploadUrlResponse {
  final String uploadUrl;
  final String key;

  const EventMediaUploadUrlResponse({
    required this.uploadUrl,
    required this.key,
  });

  factory EventMediaUploadUrlResponse.fromJson(Map<String, dynamic> json) =>
      _$EventMediaUploadUrlResponseFromJson(json);
  Map<String, dynamic> toJson() => _$EventMediaUploadUrlResponseToJson(this);
}
