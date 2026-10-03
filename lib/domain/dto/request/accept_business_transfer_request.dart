import 'package:json_annotation/json_annotation.dart';

part 'accept_business_transfer_request.g.dart';

@JsonSerializable(includeIfNull: false)
class AcceptBusinessTransferRequest {
  final String? targetBusinessId;

  const AcceptBusinessTransferRequest({this.targetBusinessId});

  factory AcceptBusinessTransferRequest.fromJson(Map<String, dynamic> json) =>
      _$AcceptBusinessTransferRequestFromJson(json);

  Map<String, dynamic> toJson() => _$AcceptBusinessTransferRequestToJson(this);
}
