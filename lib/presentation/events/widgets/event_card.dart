import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/public_event_response.dart';

class EventCard extends StatelessWidget {
  final PublicEventResponse event;
  final VoidCallback onTap;
  final VoidCallback onToggleInterest;

  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    required this.onToggleInterest,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final title = context.pickBilingual(ar: event.titleAr, en: event.titleEn);
    final dt = DateTime.tryParse(event.startsAt)?.toLocal();
    final dateLabel = dt == null
        ? null
        : DateFormat('EEEE d MMM • h:mm a', context.locale.toString()).format(dt);
    final url = event.coverUrl;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url != null && url.isNotEmpty)
              CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (_, _) => ColoredBox(color: c.surfaceMuted),
                errorWidget: (_, _, _) => _placeholder(c),
              )
            else
              _placeholder(c),

            const Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66000000), Color(0x00000000), Color(0xD9000000)],
                      stops: [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            PositionedDirectional(
              top: 8,
              end: 8,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleInterest,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        event.interestedByMe
                            ? TablerIcons.heart_filled
                            : TablerIcons.heart,
                        color: event.interestedByMe
                            ? const Color(0xFFEC4899)
                            : Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.interestedCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            PositionedDirectional(
              start: 12,
              end: 12,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (dateLabel != null)
                    Text(
                      dateLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'IBMPlexSansArabic',
                        shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.2,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'IBMPlexSansArabic',
                      shadows: [Shadow(color: Colors.black87, blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(AppColors c) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.surfaceElevated, c.surfaceMuted],
          ),
        ),
        child: Center(
          child: Icon(TablerIcons.calendar_star, color: c.onSurfaceMuted, size: 34),
        ),
      );
}
