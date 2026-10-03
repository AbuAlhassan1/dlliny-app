import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class HangoutCommentTile extends StatelessWidget {
  final HangoutCommentResponse comment;
  final VoidCallback? onDelete;
  final VoidCallback? onReply;

  final VoidCallback? onAuthorTap;

  final bool isReply;

  const HangoutCommentTile({
    super.key,
    required this.comment,
    this.onDelete,
    this.onReply,
    this.onAuthorTap,
    this.isReply = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
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
          GestureDetector(
            onTap: onAuthorTap,
            child: CircleAvatar(
              radius: avatarRadius,
              backgroundColor: c.surfaceMuted,
              backgroundImage: comment.author.avatarUrl != null
                  ? CachedNetworkImageProvider(comment.author.avatarUrl!)
                  : null,
              child: comment.author.avatarUrl == null
                  ? Icon(
                      Icons.person,
                      color: c.onSurfaceMuted,
                      size: avatarRadius,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: onAuthorTap,
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          comment.author.displayName.isNotEmpty
                              ? comment.author.displayName
                              : '@${comment.author.username}',
                          style: TextStyle(
                            color: c.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: isReply ? 12 : 13,
                          ),
                        ),
                      ),
                    ),
                    if (comment.mine && onDelete != null)
                      InkWell(
                        onTap: onDelete,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            TablerIcons.trash,
                            color: c.onSurfaceMuted,
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
                    color: c.onSurface,
                    fontSize: isReply ? 13 : 14,
                  ),
                ),
                if (onReply != null) ...[
                  const SizedBox(height: 6),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Material(
                      color: c.onSurface.withValues(alpha: 0.06),
                      shape: const StadiumBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onReply,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                TablerIcons.arrow_back_up,
                                size: 13,
                                color: c.onSurfaceSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                LocaleKeys.hangout_reply_short.tr(),
                                style: TextStyle(
                                  color: c.onSurfaceSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
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
