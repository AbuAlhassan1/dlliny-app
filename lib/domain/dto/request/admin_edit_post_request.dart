import 'package:json_annotation/json_annotation.dart';

part 'admin_edit_post_request.g.dart';

@JsonSerializable(includeIfNull: false)
class AdminEditPostRequest {
  final String? caption;

  final bool? isProduct;

  final double? price;

  const AdminEditPostRequest({
    this.caption,
    this.isProduct,
    this.price,
  });

  factory AdminEditPostRequest.fromJson(Map<String, dynamic> json) =>
      _$AdminEditPostRequestFromJson(json);
  Map<String, dynamic> toJson() => _$AdminEditPostRequestToJson(this);
}
