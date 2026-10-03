import 'package:json_annotation/json_annotation.dart';

part 'admin_media_upload_response.g.dart';

@JsonSerializable()
class AdminMediaUploadResponse {
  final String uploadUrl;
  final String key;

  const AdminMediaUploadResponse({
    required this.uploadUrl,
    required this.key,
  });

  factory AdminMediaUploadResponse.fromJson(Map<String, dynamic> json) =>
      _$AdminMediaUploadResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AdminMediaUploadResponseToJson(this);
}
