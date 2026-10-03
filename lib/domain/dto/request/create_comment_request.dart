import 'package:json_annotation/json_annotation.dart';

part 'create_comment_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateCommentRequest {
  final String body;
  final String? parentCommentId;

  const CreateCommentRequest({
    required this.body,
    this.parentCommentId,
  });

  factory CreateCommentRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateCommentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateCommentRequestToJson(this);
}
