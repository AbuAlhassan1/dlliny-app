import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
class HangoutFeedHeroVenueChip extends StatelessWidget {
  final HangoutOrganizerVenue venue;
  final HangoutFeedBranch? branch;
  final VoidCallback onTap;
  final double maxWidth;

  const HangoutFeedHeroVenueChip({
    super.key,
    required this.venue,
    required this.branch,
    required this.onTap,
    required this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = context.pickBilingual(
      ar: venue.nameAr,
      en: venue.nameEn,
      fallback: venue.nameAr ?? venue.nameEn ?? '',
    );
    final branchLine = _branchLine(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 60,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsetsDirectional.all(10),
              child: Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  _LogoSquare(url: venue.logoUrl),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                        if (branchLine != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            branchLine,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 10,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
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
}

class _LogoSquare extends StatelessWidget {
  final String? url;
  const _LogoSquare({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
      ),
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => const Icon(
                TablerIcons.building_store,
                color: Colors.white70,
                size: 16,
              ),
            )
          : const Icon(
              TablerIcons.building_store,
              color: Colors.white70,
              size: 16,
            ),
    );
  }
}
