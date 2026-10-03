import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/presentation/my_profile/widgets/user_avatar.dart';
import 'package:hangout/presentation/post/widgets/post_actions_sheet.dart';

class PostDetailsHeader extends StatelessWidget {
  final PostResponse post;
  const PostDetailsHeader({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final user = post.author;
    final venue = post.venueAuthor;
    final avatarUrl = user?.avatarUrl ?? venue?.logoUrl ?? '';
    final displayName = user?.displayName ??
        user?.username ??
        venue?.nameAr ??
        venue?.nameEn ??
        '';
    final handle = user != null ? '${user.username}@' : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        children: [
          const BackButton(),
          SizedBox(
            height: 50,
            width: 50,
            child: UserAvatar(avatarUrl: avatarUrl),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: c.onSurface,
                  ),
                ),
                if (handle != null)
                  Text(
                    handle,
                    style: TextStyle(
                      fontWeight: FontWeight.normal,
                      color: c.onSurface,
                    ),
                  ),
                Text(
                  formatRelativeTime(post.createdAt),
                  style: TextStyle(
                    fontWeight: FontWeight.normal,
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () async {
              final result = await showPostActionsSheet(
                context,
                postId: post.id,
                isMine: post.mine,
                venueId: post.venueAuthor?.id,
              );
              if (result == PostActionResult.deleted && context.mounted) {
                Navigator.of(context).pop(true);
              }
            },
            icon: Icon(TablerIcons.dots_vertical, color: c.onSurface),
          ),
        ],
      ),
    );
  }
}
