import 'package:json_annotation/json_annotation.dart';

part 'order_response.g.dart';

enum OrderStatus {
  @JsonValue('PENDING')
  pending,
  @JsonValue('ACCEPTED')
  accepted,
  @JsonValue('REJECTED')
  rejected,
  @JsonValue('CANCELLED')
  cancelled,
  @JsonValue('DELIVERED')
  delivered,
}

enum OrderSenderRole {
  @JsonValue('CUSTOMER')
  customer,
  @JsonValue('VENUE')
  venue,
}

@JsonSerializable()
class OrderProductSummaryDto {
  final String postId;
  final String? caption;
  final String? mediaUrl;
  final String? mediaType;

  final double? currentPrice;

  const OrderProductSummaryDto({
    required this.postId,
    this.caption,
    this.mediaUrl,
    this.mediaType,
    this.currentPrice,
  });

  factory OrderProductSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$OrderProductSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderProductSummaryDtoToJson(this);
}

@JsonSerializable()
class OrderVenueSummaryDto {
  final String id;
  final String? handle;
  final String? nameAr;
  final String? nameEn;
  final String? logoUrl;
  final String? phone;

  const OrderVenueSummaryDto({
    required this.id,
    this.handle,
    this.nameAr,
    this.nameEn,
    this.logoUrl,
    this.phone,
  });

  factory OrderVenueSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$OrderVenueSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderVenueSummaryDtoToJson(this);
}

@JsonSerializable()
class OrderCustomerSummaryDto {
  final String id;
  final String username;
  final String? displayName;
  final String? avatarUrl;

  const OrderCustomerSummaryDto({
    required this.id,
    required this.username,
    this.displayName,
    this.avatarUrl,
  });

  factory OrderCustomerSummaryDto.fromJson(Map<String, dynamic> json) =>
      _$OrderCustomerSummaryDtoFromJson(json);

  Map<String, dynamic> toJson() => _$OrderCustomerSummaryDtoToJson(this);
}

@JsonSerializable()
class OrderMessageResponse {
  final String id;
  final String senderUserId;
  final OrderSenderRole senderRole;
  final String body;
  final String createdAt;
  final String? readAt;

  const OrderMessageResponse({
    required this.id,
    required this.senderUserId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
    this.readAt,
  });

  factory OrderMessageResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderMessageResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderMessageResponseToJson(this);
}

@JsonSerializable(explicitToJson: true)
class OrderResponse {
  final String id;
  final OrderStatus status;

  final bool inquiryLocked;

  final double price;
  final String? priceCurrency;

  final OrderProductSummaryDto product;
  final OrderVenueSummaryDto venue;
  final OrderCustomerSummaryDto customer;

  final String createdAt;
  final String? respondedAt;
  final String? deliveredAt;
  final String? cancelledAt;

  final List<OrderMessageResponse> messages;

  final int unreadMessageCount;

  const OrderResponse({
    required this.id,
    required this.status,
    required this.inquiryLocked,
    required this.price,
    this.priceCurrency,
    required this.product,
    required this.venue,
    required this.customer,
    required this.createdAt,
    this.respondedAt,
    this.deliveredAt,
    this.cancelledAt,
    required this.messages,
    required this.unreadMessageCount,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderResponseToJson(this);
}

@JsonSerializable()
class OrderSummaryResponse {
  final String id;
  final OrderStatus status;
  final double price;
  final String? priceCurrency;

  final String? productCaption;
  final String? productMediaUrl;

  final String venueId;
  final String? venueNameAr;
  final String? venueNameEn;
  final String? venueLogoUrl;

  final String customerId;
  final String customerUsername;
  final String? customerDisplayName;
  final String? customerAvatarUrl;

  final String createdAt;
  final int unreadMessageCount;

  const OrderSummaryResponse({
    required this.id,
    required this.status,
    required this.price,
    this.priceCurrency,
    this.productCaption,
    this.productMediaUrl,
    required this.venueId,
    this.venueNameAr,
    this.venueNameEn,
    this.venueLogoUrl,
    required this.customerId,
    required this.customerUsername,
    this.customerDisplayName,
    this.customerAvatarUrl,
    required this.createdAt,
    required this.unreadMessageCount,
  });

  factory OrderSummaryResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderSummaryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderSummaryResponseToJson(this);
}
