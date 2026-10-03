import 'package:json_annotation/json_annotation.dart';

part 'confirm_hangout_media_request.g.dart';

@JsonSerializable()
class ConfirmHangoutMediaRequest {
  final String key;
  final String mediaType;
  final int sortOrder;

  final double? aspectRatio;

  const ConfirmHangoutMediaRequest({
    required this.key,
    required this.mediaType,
    required this.sortOrder,
    this.aspectRatio,
  });

  factory ConfirmHangoutMediaRequest.fromJson(Map<String, dynamic> json) =>
      _$ConfirmHangoutMediaRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ConfirmHangoutMediaRequestToJson(this);
}
