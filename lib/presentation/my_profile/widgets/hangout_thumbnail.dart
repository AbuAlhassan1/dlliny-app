import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';

class HangoutThumbnail extends StatelessWidget {
  final HangoutResponse hangout;

  const HangoutThumbnail({super.key, required this.hangout});

  bool get _isVideo => hangout.thumbnailMediaType == 'video';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final date = DateTime.tryParse(hangout.scheduledAt);
    final formattedDate = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : hangout.scheduledAt;

    final url = hangout.thumbnailUrl;
    final isVideo = _isVideo;
    final posterUrl = (url != null && url.isNotEmpty) ? url : null;

    return Material(
      color: c.mediaSurface,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HangoutDetailsPageWrapper(hangoutId: hangout.id),
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (posterUrl != null)
              CachedNetworkImage(
                imageUrl: posterUrl,
                fit: BoxFit.cover,
                memCacheWidth: 300,
                placeholder: (_, _) => ColoredBox(color: c.mediaSurface),
                errorWidget: (_, _, _) => ColoredBox(color: c.mediaSurface),
              )
            else
              ColoredBox(color: c.mediaSurface),
            if (isVideo && posterUrl == null)
              Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: c.onMediaSurface,
                  size: 32,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hangout.venueNameAr,
                    style: TextStyle(
                      color: c.onMediaSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 11,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        formattedDate,
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.people_outline,
                        size: 11,
                        color: Colors.white
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${hangout.attendeeCount}',
                        style: TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
