import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/presentation/post/widgets/post_like_button.dart';

class PostDetailsLikesCount extends StatelessWidget {
  final PostResponse post;
  const PostDetailsLikesCount({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          PostLikesCountText(
            postId: post.id,
            initialLikesCount: post.likesCount,
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(' إعجاب', style: TextStyle(color: c.onSurface)),
        ],
      ),
    );
  }
}
