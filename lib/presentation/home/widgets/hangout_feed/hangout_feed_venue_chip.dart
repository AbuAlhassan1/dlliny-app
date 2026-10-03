import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class HangoutFeedVenueChip extends StatelessWidget {
  final HangoutOrganizerVenue venue;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  final HangoutFeedBranch? branch;

  const HangoutFeedVenueChip({
    super.key,
    required this.venue,
    required this.onTap,
    this.onLongPress,
    this.branch,
  });

  String? _branchLine(BuildContext context) {
    final b = branch;
    if (b == null) return null;
    final label = context.pickBilingual(
      ar: b.labelAr,
      en: b.labelEn,
      fallback: '',
    );
    if (label.isNotEmpty) return label;
    final address = context.pickBilingual(
      ar: b.addressAr,
      en: b.addressEn,
      fallback: '',
    );
    if (address.isNotEmpty) return address;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = context.pickBilingual(ar: venue.nameAr, en: venue.nameEn);
    final district = venue.district;

    return Material(
      color: c.onSurface.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
          child: Row(
            children: [
              _LogoSquare(url: venue.logoUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: c.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            LocaleKeys.hangout_role_pill_venue.tr(),
                            style: TextStyle(
                              color: c.onPrimary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (district != null && district.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            TablerIcons.map_pin,
                            size: 11,
                            color: c.onSurfaceSecondary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              district,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (_branchLine(context) != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            TablerIcons.building,
                            size: 11,
                            color: c.onSurfaceSecondary,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              _branchLine(context)!,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                TablerIcons.chevron_left,
                size: 16,
                color: c.onSurfaceSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogoSquare extends StatelessWidget {
  final String? url;
  const _LogoSquare({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 38,
      height: 38,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
      ),
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Icon(
                TablerIcons.building_store,
                color: c.onSurface,
                size: 18,
              ),
            )
          : Icon(
              TablerIcons.building_store,
              color: c.onSurface,
              size: 18,
            ),
    );
  }
}
