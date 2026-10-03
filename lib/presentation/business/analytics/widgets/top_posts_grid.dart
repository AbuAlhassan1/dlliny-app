import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class TopPostsGrid extends StatelessWidget {
  final TopPostsResponse data;
  const TopPostsGrid({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final posts = data.posts;
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_top_posts_title.tr(),
      subtitle: '${data.from} → ${data.to}',
      child: posts.isEmpty
          ? AnalyticsTileEmpty(
              icon: TablerIcons.photo,
              message: LocaleKeys.business_analytics_top_posts_empty.tr(),
            )
          : SizedBox(
              height: 152,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: posts.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _PostCard(post: posts[i]),
              ),
            ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final TopPost post;
  const _PostCard({required this.post});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 116,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: post.thumbnailUrl != null && post.thumbnailUrl!.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: post.thumbnailUrl!,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => _Placeholder(),
                    placeholder: (_, _) => _Placeholder(),
                  )
                : _Placeholder(),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(TablerIcons.heart, color: c.danger, size: 12),
                const SizedBox(width: 3),
                Text(
                  '${post.likesCount}',
                  style: TextStyle(color: c.onSurface, fontSize: 11),
                ),
                const SizedBox(width: 8),
                Icon(
                  TablerIcons.message_circle_2,
                  color: c.onSurfaceSecondary,
                  size: 12,
                ),
                const SizedBox(width: 3),
                Text(
                  '${post.commentsCount}',
                  style: TextStyle(color: c.onSurface, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ColoredBox(
      color: c.surface,
      child: Center(
        child: Icon(
          TablerIcons.photo,
          color: c.onSurfaceDisabled,
          size: 28,
        ),
      ),
    );
  }
}
