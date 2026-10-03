import 'package:json_annotation/json_annotation.dart';

part 'report_post_request.g.dart';

@JsonSerializable()
class ReportPostRequest {
  final String categoryId;
  final String? description;

  const ReportPostRequest({
    required this.categoryId,
    this.description,
  });

  factory ReportPostRequest.fromJson(Map<String, dynamic> json) =>
      _$ReportPostRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReportPostRequestToJson(this);
}
