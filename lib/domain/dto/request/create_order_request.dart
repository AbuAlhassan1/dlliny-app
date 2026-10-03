import 'package:json_annotation/json_annotation.dart';

part 'create_order_request.g.dart';

@JsonSerializable(includeIfNull: false)
class CreateOrderRequest {
  final String postId;
  final String? note;

  const CreateOrderRequest({
    required this.postId,
    this.note,
  });

  factory CreateOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateOrderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateOrderRequestToJson(this);
}
