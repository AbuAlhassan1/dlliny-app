import 'package:json_annotation/json_annotation.dart';

part 'submit_business_request.g.dart';

@JsonSerializable()
class SubmitBusinessRequest {
  final String companyName;
  final String description;

  const SubmitBusinessRequest({required this.companyName, required this.description});

  factory SubmitBusinessRequest.fromJson(Map<String, dynamic> json) =>
      _$SubmitBusinessRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SubmitBusinessRequestToJson(this);
}
