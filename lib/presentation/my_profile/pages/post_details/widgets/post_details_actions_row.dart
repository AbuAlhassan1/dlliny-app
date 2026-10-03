import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/helpers/open_share_sheet.dart';
import 'package:hangout/presentation/post/widgets/post_like_button.dart';

class PostDetailsActionsRow extends StatelessWidget {
  final PostResponse post;
  const PostDetailsActionsRow({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        PostLikeButton(
          postId: post.id,
          initialLikedByMe: post.likedByMe,
          initialLikesCount: post.likesCount,
          idleColor: c.onSurface,
        ),
        IconButton(
          onPressed: () => openShareSheet(
            context,
            resourceType: SharedResourceType.post,
            resourceId: post.id,
            headlineLabel: LocaleKeys.post_share_headline.tr(),
          ),
          icon: Icon(TablerIcons.send, color: c.onSurface),
        ),
      ],
    );
  }
}
