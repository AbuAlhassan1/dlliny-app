// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderProductSummaryDto _$OrderProductSummaryDtoFromJson(
  Map<String, dynamic> json,
) => OrderProductSummaryDto(
  postId: json['postId'] as String,
  caption: json['caption'] as String?,
  mediaUrl: json['mediaUrl'] as String?,
  mediaType: json['mediaType'] as String?,
  currentPrice: (json['currentPrice'] as num?)?.toDouble(),
);

Map<String, dynamic> _$OrderProductSummaryDtoToJson(
  OrderProductSummaryDto instance,
) => <String, dynamic>{
  'postId': instance.postId,
  'caption': instance.caption,
  'mediaUrl': instance.mediaUrl,
  'mediaType': instance.mediaType,
  'currentPrice': instance.currentPrice,
};

OrderVenueSummaryDto _$OrderVenueSummaryDtoFromJson(
  Map<String, dynamic> json,
) => OrderVenueSummaryDto(
  id: json['id'] as String,
  handle: json['handle'] as String?,
  nameAr: json['nameAr'] as String?,
  nameEn: json['nameEn'] as String?,
  logoUrl: json['logoUrl'] as String?,
  phone: json['phone'] as String?,
);

Map<String, dynamic> _$OrderVenueSummaryDtoToJson(
  OrderVenueSummaryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'handle': instance.handle,
  'nameAr': instance.nameAr,
  'nameEn': instance.nameEn,
  'logoUrl': instance.logoUrl,
  'phone': instance.phone,
};

OrderCustomerSummaryDto _$OrderCustomerSummaryDtoFromJson(
  Map<String, dynamic> json,
) => OrderCustomerSummaryDto(
  id: json['id'] as String,
  username: json['username'] as String,
  displayName: json['displayName'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
);

Map<String, dynamic> _$OrderCustomerSummaryDtoToJson(
  OrderCustomerSummaryDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'username': instance.username,
  'displayName': instance.displayName,
  'avatarUrl': instance.avatarUrl,
};

OrderMessageResponse _$OrderMessageResponseFromJson(
  Map<String, dynamic> json,
) => OrderMessageResponse(
  id: json['id'] as String,
  senderUserId: json['senderUserId'] as String,
  senderRole: $enumDecode(_$OrderSenderRoleEnumMap, json['senderRole']),
  body: json['body'] as String,
  createdAt: json['createdAt'] as String,
  readAt: json['readAt'] as String?,
);

Map<String, dynamic> _$OrderMessageResponseToJson(
  OrderMessageResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'senderUserId': instance.senderUserId,
  'senderRole': _$OrderSenderRoleEnumMap[instance.senderRole]!,
  'body': instance.body,
  'createdAt': instance.createdAt,
  'readAt': instance.readAt,
};

const _$OrderSenderRoleEnumMap = {
  OrderSenderRole.customer: 'CUSTOMER',
  OrderSenderRole.venue: 'VENUE',
};

OrderResponse _$OrderResponseFromJson(Map<String, dynamic> json) =>
    OrderResponse(
      id: json['id'] as String,
      status: $enumDecode(_$OrderStatusEnumMap, json['status']),
      inquiryLocked: json['inquiryLocked'] as bool,
      price: (json['price'] as num).toDouble(),
      priceCurrency: json['priceCurrency'] as String?,
      product: OrderProductSummaryDto.fromJson(
        json['product'] as Map<String, dynamic>,
      ),
      venue: OrderVenueSummaryDto.fromJson(
        json['venue'] as Map<String, dynamic>,
      ),
      customer: OrderCustomerSummaryDto.fromJson(
        json['customer'] as Map<String, dynamic>,
      ),
      createdAt: json['createdAt'] as String,
      respondedAt: json['respondedAt'] as String?,
      deliveredAt: json['deliveredAt'] as String?,
      cancelledAt: json['cancelledAt'] as String?,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => OrderMessageResponse.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadMessageCount: (json['unreadMessageCount'] as num).toInt(),
    );

Map<String, dynamic> _$OrderResponseToJson(OrderResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$OrderStatusEnumMap[instance.status]!,
      'inquiryLocked': instance.inquiryLocked,
      'price': instance.price,
      'priceCurrency': instance.priceCurrency,
      'product': instance.product.toJson(),
      'venue': instance.venue.toJson(),
      'customer': instance.customer.toJson(),
      'createdAt': instance.createdAt,
      'respondedAt': instance.respondedAt,
      'deliveredAt': instance.deliveredAt,
      'cancelledAt': instance.cancelledAt,
      'messages': instance.messages.map((e) => e.toJson()).toList(),
      'unreadMessageCount': instance.unreadMessageCount,
    };

const _$OrderStatusEnumMap = {
  OrderStatus.pending: 'PENDING',
  OrderStatus.accepted: 'ACCEPTED',
  OrderStatus.rejected: 'REJECTED',
  OrderStatus.cancelled: 'CANCELLED',
  OrderStatus.delivered: 'DELIVERED',
};

OrderSummaryResponse _$OrderSummaryResponseFromJson(
  Map<String, dynamic> json,
) => OrderSummaryResponse(
  id: json['id'] as String,
  status: $enumDecode(_$OrderStatusEnumMap, json['status']),
  price: (json['price'] as num).toDouble(),
  priceCurrency: json['priceCurrency'] as String?,
  productCaption: json['productCaption'] as String?,
  productMediaUrl: json['productMediaUrl'] as String?,
  venueId: json['venueId'] as String,
  venueNameAr: json['venueNameAr'] as String?,
  venueNameEn: json['venueNameEn'] as String?,
  venueLogoUrl: json['venueLogoUrl'] as String?,
  customerId: json['customerId'] as String,
  customerUsername: json['customerUsername'] as String,
  customerDisplayName: json['customerDisplayName'] as String?,
  customerAvatarUrl: json['customerAvatarUrl'] as String?,
  createdAt: json['createdAt'] as String,
  unreadMessageCount: (json['unreadMessageCount'] as num).toInt(),
);

Map<String, dynamic> _$OrderSummaryResponseToJson(
  OrderSummaryResponse instance,
) => <String, dynamic>{
  'id': instance.id,
  'status': _$OrderStatusEnumMap[instance.status]!,
  'price': instance.price,
  'priceCurrency': instance.priceCurrency,
  'productCaption': instance.productCaption,
  'productMediaUrl': instance.productMediaUrl,
  'venueId': instance.venueId,
  'venueNameAr': instance.venueNameAr,
  'venueNameEn': instance.venueNameEn,
  'venueLogoUrl': instance.venueLogoUrl,
  'customerId': instance.customerId,
  'customerUsername': instance.customerUsername,
  'customerDisplayName': instance.customerDisplayName,
  'customerAvatarUrl': instance.customerAvatarUrl,
  'createdAt': instance.createdAt,
  'unreadMessageCount': instance.unreadMessageCount,
};
