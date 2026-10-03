import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/post/widgets/hangout_here_button.dart';

class ReelBottomInfo extends StatelessWidget {
  final String authorName;
  final String? username;
  final String? avatarUrl;
  final String? caption;
  final bool isVenue;
  final String? venueId;
  final String? venueName;
  final VoidCallback? onAuthorTap;

  const ReelBottomInfo({
    super.key,
    required this.authorName,
    this.username,
    required this.avatarUrl,
    required this.caption,
    required this.isVenue,
    required this.venueId,
    required this.venueName,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasCaption = caption != null && caption!.trim().isNotEmpty;
    final hasUsername = username != null && username!.trim().isNotEmpty;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(left: 15, right: 15, bottom: 120),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAuthorTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _Avatar(url: avatarUrl, isVenue: isVenue),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  authorName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.onMediaSurface,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (isVenue) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  TablerIcons.rosette_discount_check_filled,
                                  color: c.success,
                                  size: 16,
                                ),
                              ],
                            ],
                          ),
                          if (hasUsername) ...[
                            const SizedBox(height: 2),
                            Text(
                              '@${username!}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: c.onMediaSurface.withValues(alpha: 0.75),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (hasCaption) ...[
                const SizedBox(height: 8),
                ExpandableText(
                  caption!.trim(),
                  expandText: LocaleKeys.common_more_short.tr(),
                  collapseText: LocaleKeys.common_less_short.tr(),
                  maxLines: 2,
                  linkColor: c.onMediaSurface.withValues(alpha: 0.85),
                  animation: true,
                  animationCurve: Curves.easeOut,
                  animationDuration: const Duration(milliseconds: 220),
                  expandOnTextTap: true,
                  collapseOnTextTap: true,
                  style: TextStyle(
                    color: c.onMediaSurface,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
              if (venueId != null) ...[
                const SizedBox(height: 12),
                HangoutHereButton(venueId: venueId!, venueName: venueName),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final bool isVenue;
  const _Avatar({required this.url, required this.isVenue});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fallback = Icon(
      isVenue ? TablerIcons.building_store : TablerIcons.user,
      color: c.onMediaSurface,
      size: 18,
    );
    return Container(
      width: 32,
      height: 32,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.onMediaSurface, width: 1.5),
        color: c.mediaSurface.withValues(alpha: 0.4),
      ),
      child: (url != null && url!.isNotEmpty)
          ? ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: 96,
                errorWidget: (_, _, _) => Center(child: fallback),
              ),
          )
          : Center(child: fallback),
    );
  }
}
