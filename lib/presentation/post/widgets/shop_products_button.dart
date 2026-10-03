import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/venue_products_page_wrapper.dart';

class ShopProductsButton extends StatelessWidget {
  final String venueId;
  final String? venueName;
  const ShopProductsButton({
    super.key,
    required this.venueId,
    this.venueName,
  });

  void _onTap(BuildContext context) {
    HapticFeedback.heavyImpact();
    VenueProductsPageWrapper.push(
      context,
      venueId: venueId,
      venueName: venueName,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10)),
        child: Stack(
          children: [
            const Positioned.fill(
              child: MovingBackground(
                backgroundColor: Colors.deepPurple,
                animationType: AnimationType.move,
                duration: Duration(milliseconds: 1000),
                circles: [
                  MovingCircle(color: Colors.pinkAccent, radius: 80),
                  MovingCircle(color: Colors.deepPurple, radius: 80),
                  MovingCircle(color: Colors.indigo, radius: 80),
                  MovingCircle(color: Colors.orangeAccent, radius: 80),
                  MovingCircle(color: Colors.blueAccent, radius: 80),
                  MovingCircle(color: Colors.white, radius: 80),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      TablerIcons.shopping_bag,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      LocaleKeys.post_venue_cta_shop_products.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
