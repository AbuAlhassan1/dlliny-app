import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/presentation/explore/utils/reel_item.dart';

class DiscoverGridTile extends StatelessWidget {
  final ReelItem item;
  final VoidCallback onTap;
  const DiscoverGridTile({super.key, required this.item, required this.onTap});

  FeedMediaItem? get _cover => item.media.isNotEmpty ? item.media.first : null;

  String? get _coverUrl {
    final m = _cover;
    if (m == null) return null;
    return m.type == 'video' ? m.thumbnailUrl : m.url;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final url = _coverUrl;
    final isVideo = _cover?.type == 'video';
    final isCarousel = item.media.length > 1;
    final isHangout = item is HangoutReel;
    final mq = MediaQuery.of(context);
    final memWidth = (mq.size.width / 3 * mq.devicePixelRatio).round();

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (url != null && url.isNotEmpty)
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              memCacheWidth: memWidth,
              placeholder: (_, _) => ColoredBox(color: c.surfaceMuted),
              errorWidget: (_, _, _) => ColoredBox(
                color: c.surfaceMuted,
                child: Icon(Icons.error_outline, color: c.onSurfaceMuted),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.surfaceElevated, c.surfaceMuted],
                ),
              ),
              child: Center(
                child: Icon(
                  isHangout ? TablerIcons.calendar_event : TablerIcons.photo,
                  color: c.onSurfaceMuted,
                  size: 26,
                ),
              ),
            ),

          if (isVideo || isCarousel)
            PositionedDirectional(
              top: 6,
              end: 6,
              child: Icon(
                isVideo
                    ? TablerIcons.player_play_filled
                    : TablerIcons.layers_subtract,
                color: Colors.white,
                size: 16,
                shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),

          if (isHangout)
            const PositionedDirectional(
              top: 6,
              start: 6,
              child: Icon(
                TablerIcons.calendar_event,
                color: Colors.white,
                size: 16,
                shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
              ),
            ),
        ],
      ),
    );
  }
}
