import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/order_response.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;

  final OrderStatusBadgeSize size;

  const OrderStatusBadge({
    super.key,
    required this.status,
    this.size = OrderStatusBadgeSize.small,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = _color(c);
    final fontSize = size == OrderStatusBadgeSize.large ? 12.0 : 10.0;
    final padV = size == OrderStatusBadgeSize.large ? 6.0 : 3.0;
    final padH = size == OrderStatusBadgeSize.large ? 10.0 : 7.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        _label(status),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _color(AppColors c) {
    switch (status) {
      case OrderStatus.pending:
        return c.onSurfaceSecondary;
      case OrderStatus.accepted:
        return c.primary;
      case OrderStatus.delivered:
        return c.success;
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        return c.danger;
    }
  }
}

enum OrderStatusBadgeSize { small, large }

String orderStatusLabelAr(OrderStatus s) => _label(s);

String _label(OrderStatus s) {
  switch (s) {
    case OrderStatus.pending:
      return 'بالانتظار';
    case OrderStatus.accepted:
      return 'مقبول';
    case OrderStatus.delivered:
      return 'تم التسليم';
    case OrderStatus.rejected:
      return 'مرفوض';
    case OrderStatus.cancelled:
      return 'ملغي';
  }
}
