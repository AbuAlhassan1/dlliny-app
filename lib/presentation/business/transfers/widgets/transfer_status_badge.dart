import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/business/transfers/utils/transfer_enums.dart';

class TransferStatusBadge extends StatelessWidget {
  final TransferStatus status;
  final TransferStatusBadgeSize size;

  const TransferStatusBadge({
    super.key,
    required this.status,
    this.size = TransferStatusBadgeSize.small,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = _color(c);
    final fontSize = size == TransferStatusBadgeSize.large ? 12.0 : 10.0;
    final padV = size == TransferStatusBadgeSize.large ? 6.0 : 3.0;
    final padH = size == TransferStatusBadgeSize.large ? 10.0 : 7.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        transferStatusLabelAr(status),
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
      case TransferStatus.pending:
        return c.onSurfaceSecondary;
      case TransferStatus.accepted:
        return c.success;
      case TransferStatus.declined:
      case TransferStatus.cancelled:
        return c.danger;
      case TransferStatus.expired:
        return c.onSurfaceMuted;
    }
  }
}

enum TransferStatusBadgeSize { small, large }
