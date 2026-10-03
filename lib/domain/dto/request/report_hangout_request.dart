import 'package:json_annotation/json_annotation.dart';

part 'report_hangout_request.g.dart';

@JsonSerializable()
class ReportHangoutRequest {
  final String categoryId;
  final String? description;

  const ReportHangoutRequest({
    required this.categoryId,
    this.description,
  });

  factory ReportHangoutRequest.fromJson(Map<String, dynamic> json) =>
      _$ReportHangoutRequestFromJson(json);

  Map<String, dynamic> toJson() => _$ReportHangoutRequestToJson(this);
}
