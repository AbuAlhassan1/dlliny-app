import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/orders/widgets/place_order_sheet.dart';

class ProductOrderCta extends StatelessWidget {
  final String postId;
  final double price;
  final String currency;
  final String? venueName;
  final String? productCaption;

  const ProductOrderCta({
    super.key,
    required this.postId,
    required this.price,
    required this.currency,
    this.venueName,
    this.productCaption,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Icon(
          TablerIcons.shopping_bag,
          color: c.onSurfaceSecondary,
          size: 14,
        ),
        const SizedBox(width: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              price.toStringAsFixed(0),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 3),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: Text(
                currency,
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SizedBox(width: 10),
        FilledButton(
          onPressed: () => showPlaceOrderSheet(
            context,
            postId: postId,
            price: price,
            currency: currency,
            venueName: venueName,
            productCaption: productCaption,
          ),
          style: FilledButton.styleFrom(
            backgroundColor: c.primary,
            foregroundColor: c.onPrimary,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 4,
            ),
            minimumSize: const Size(0, 30),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text(
            'اطلب',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }
}
