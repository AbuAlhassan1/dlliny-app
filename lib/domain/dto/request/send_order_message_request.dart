import 'package:json_annotation/json_annotation.dart';

part 'send_order_message_request.g.dart';

@JsonSerializable()
class SendOrderMessageRequest {
  final String body;

  const SendOrderMessageRequest({required this.body});

  factory SendOrderMessageRequest.fromJson(Map<String, dynamic> json) =>
      _$SendOrderMessageRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendOrderMessageRequestToJson(this);
}
