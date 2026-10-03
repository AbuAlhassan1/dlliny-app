import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class CommentTile extends StatelessWidget {
  final CommentResponse comment;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;
  final bool isReply;

  const CommentTile({
    super.key,
    required this.comment,
    this.onDelete,
    this.onReply,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final avatarRadius = isReply ? 14.0 : 18.0;
    final horizontalPadding = isReply
        ? const EdgeInsetsDirectional.only(start: 52, end: 16)
        : const EdgeInsetsDirectional.symmetric(horizontal: 16);

    return Padding(
      padding: horizontalPadding.add(
        const EdgeInsets.symmetric(vertical: 8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: Colors.grey[800],
            backgroundImage: comment.author.avatarUrl != null
                ? CachedNetworkImageProvider(comment.author.avatarUrl!)
                : null,
            child: comment.author.avatarUrl == null
                ? Icon(Icons.person, color: Colors.white, size: avatarRadius)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.author.displayName ??
                            '@${comment.author.username}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: isReply ? 12 : 13,
                        ),
                      ),
                    ),
                    if (comment.mine && onDelete != null)
                      InkWell(
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            TablerIcons.trash,
                            color: Colors.white54,
                            size: 16,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  comment.body,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isReply ? 13 : 14,
                  ),
                ),
                if (onReply != null) ...[
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: onReply,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        LocaleKeys.post_comments_sheet_reply_short.tr(),
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
