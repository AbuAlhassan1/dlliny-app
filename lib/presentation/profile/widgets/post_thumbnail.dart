import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/post_details_page_wrapper.dart';

class PostThumbnail extends StatelessWidget {
  final int index;
  final PostResponse post;

  const PostThumbnail({super.key, required this.post, required this.index});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PostDetailsPageWrapper(post: post),
          ),
        );
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: Builder(
          builder: (context) {
            if (post.media.isNotEmpty) {
              final first = post.media.reduce(
                (a, b) => a.sortOrder < b.sortOrder ? a : b,
              );
              final isVideo = first.mediaType == 'video';
              final imageUrl =
                  isVideo ? first.thumbnailUrl : first.url;
              final hasImage = imageUrl != null && imageUrl.isNotEmpty;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'post_${post.id}',
                    child: hasImage
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 300,
                            placeholder: (_, _) =>
                                Container(color: c.mediaSurface),
                            errorWidget: (_, _, _) =>
                                Container(color: c.mediaSurface),
                          )
                        : Container(color: c.mediaSurface),
                  ),
                  if (isVideo && !hasImage)
                    Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        color: c.onMediaSurface,
                        size: 32,
                      ),
                    ),
                ],
              );
            }

            return Container(
              color: c.mediaSurface,
              padding: const EdgeInsets.all(8),
              child: Text(
                post.caption ?? '',
                style: TextStyle(color: c.onMediaSurface, fontSize: 12),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
        ),
      ),
    );
  }
}
