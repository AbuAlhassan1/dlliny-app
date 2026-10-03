// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_edit_post_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminEditPostRequest _$AdminEditPostRequestFromJson(
  Map<String, dynamic> json,
) => AdminEditPostRequest(
  caption: json['caption'] as String?,
  isProduct: json['isProduct'] as bool?,
  price: (json['price'] as num?)?.toDouble(),
);

Map<String, dynamic> _$AdminEditPostRequestToJson(
  AdminEditPostRequest instance,
) => <String, dynamic>{
  'caption': ?instance.caption,
  'isProduct': ?instance.isProduct,
  'price': ?instance.price,
};
