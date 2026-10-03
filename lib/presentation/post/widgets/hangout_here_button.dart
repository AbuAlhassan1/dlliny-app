import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/create_hangout_page_wrapper.dart';


class HangoutHereButton extends StatelessWidget {
  final String venueId;
  final String? venueName;
  const HangoutHereButton({
    super.key,
    required this.venueId,
    this.venueName,
  });

  void _onTap(BuildContext context) {
    HapticFeedback.heavyImpact();
    final preselect = VenueSearchResultDto(
      id: venueId,
      nameAr: venueName ?? '',
      nameEn: venueName ?? '',
      avgRating: null,
      verified: false,
    );
    openCreateHangoutPage(context, initialVenue: preselect);
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
                backgroundColor: Colors.orange,
                animationType: AnimationType.moveAndFade,
                duration: Duration(milliseconds: 4000),
                circles: [
                  MovingCircle(color: Colors.orangeAccent, radius: 150),
                  MovingCircle(color: Colors.white, radius: 150),
                  MovingCircle(color: Colors.yellow, radius: 150),
                  MovingCircle(color: Colors.pink, radius: 150),
                  MovingCircle(color: Colors.red, radius: 150),
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
                      TablerIcons.calendar_plus,
                      color: Colors.white,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      LocaleKeys.venue_has_hangout_badge.tr(),
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
