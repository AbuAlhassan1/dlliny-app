import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class LoyalistsList extends StatelessWidget {
  final LoyalistsResponse data;
  const LoyalistsList({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_loyalists_title.tr(),
      subtitle: LocaleKeys.business_analytics_loyalists_subtitle.tr(
        namedArgs: {
          'days': '${data.days}',
          'min': '${data.minMentions}',
        },
      ),
      child: data.items.isEmpty
          ? AnalyticsTileEmpty(
              icon: TablerIcons.users,
              message: LocaleKeys.business_analytics_loyalists_empty.tr(),
            )
          : Column(
              children: [
                for (final loyalist in data.items) _Row(loyalist: loyalist),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final Loyalist loyalist;
  const _Row({required this.loyalist});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          _Avatar(url: loyalist.avatarUrl),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  loyalist.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '@${loyalist.username}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.onSurfaceSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: c.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(TablerIcons.heart_filled, color: c.primary, size: 11),
                const SizedBox(width: 4),
                Text(
                  '${loyalist.mentionCount}',
                  style: TextStyle(
                    color: c.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 36,
      height: 36,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.surfaceMuted,
      ),
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              memCacheWidth: 108,
              errorWidget: (_, _, _) =>
                  Icon(TablerIcons.user, color: c.onSurfaceSecondary, size: 18),
            )
          : Icon(TablerIcons.user, color: c.onSurfaceSecondary, size: 18),
    );
  }
}
