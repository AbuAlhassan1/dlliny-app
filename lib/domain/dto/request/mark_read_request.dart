import 'package:json_annotation/json_annotation.dart';

part 'mark_read_request.g.dart';

@JsonSerializable()
class MarkReadRequest {
  final String messageId;

  const MarkReadRequest({required this.messageId});

  factory MarkReadRequest.fromJson(Map<String, dynamic> json) =>
      _$MarkReadRequestFromJson(json);

  Map<String, dynamic> toJson() => _$MarkReadRequestToJson(this);
}
