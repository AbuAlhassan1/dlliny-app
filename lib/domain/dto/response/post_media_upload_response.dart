import 'package:json_annotation/json_annotation.dart';

part 'post_media_upload_response.g.dart';

@JsonSerializable()
class PostMediaUploadResponse {
  final String uploadUrl;
  final String key;

  const PostMediaUploadResponse({
    required this.uploadUrl,
    required this.key,
  });

  factory PostMediaUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$PostMediaUploadResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PostMediaUploadResponseToJson(this);
}
