import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/post/controllers/post_interactions_bloc.dart';
import 'package:hangout/presentation/post/widgets/heart_burst_overlay.dart';

class PostLikeButton extends StatefulWidget {
  final String postId;
  final bool initialLikedByMe;
  final int initialLikesCount;
  final Color likedColor;
  final Color? idleColor;

  const PostLikeButton({
    super.key,
    required this.postId,
    required this.initialLikedByMe,
    required this.initialLikesCount,
    this.likedColor = Colors.red,
    this.idleColor,
  });

  @override
  State<PostLikeButton> createState() => _PostLikeButtonState();
}

class _PostLikeButtonState extends State<PostLikeButton> {
  final HeartBurstController _burst = HeartBurstController();

  @override
  Widget build(BuildContext context) {
    final resolvedIdleColor = widget.idleColor ?? context.c.onSurface;
    return BlocBuilder<PostInteractionsBloc, PostInteractionsState>(
      buildWhen: (prev, curr) =>
          curr is PostInteractionUpdated && curr.postId == widget.postId,
      builder: (context, _) {
        final bloc = context.read<PostInteractionsBloc>();
        final liked = bloc.likedByMe(widget.postId, widget.initialLikedByMe);

        return HeartBurstOverlay(
          controller: _burst,
          child: IconButton(
            onPressed: () {
              final wasLiked = liked;
              bloc.add(ToggleLike(
                postId: widget.postId,
                currentLikedByMe: liked,
                currentLikesCount: bloc.likesCount(
                  widget.postId,
                  widget.initialLikesCount,
                ),
              ));
              if (!wasLiked) _burst.fire();
            },
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(
                liked ? TablerIcons.heart_filled : TablerIcons.heart,
                key: ValueKey(liked),
                color: liked ? widget.likedColor : resolvedIdleColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class PostLikesCountText extends StatelessWidget {
  final String postId;
  final int initialLikesCount;
  final TextStyle? style;

  const PostLikesCountText({
    super.key,
    required this.postId,
    required this.initialLikesCount,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostInteractionsBloc, PostInteractionsState>(
      buildWhen: (prev, curr) =>
          curr is PostInteractionUpdated && curr.postId == postId,
      builder: (context, _) {
        final bloc = context.read<PostInteractionsBloc>();
        return Text(
          bloc.likesCount(postId, initialLikesCount).toString(),
          style: style,
        );
      },
    );
  }
}

class PostCommentsCountText extends StatelessWidget {
  final String postId;
  final int initialCommentsCount;
  final TextStyle? style;
  final String Function(int count)? builder;

  const PostCommentsCountText({
    super.key,
    required this.postId,
    required this.initialCommentsCount,
    this.style,
    this.builder,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostInteractionsBloc, PostInteractionsState>(
      buildWhen: (prev, curr) =>
          curr is PostInteractionUpdated && curr.postId == postId,
      builder: (context, _) {
        final bloc = context.read<PostInteractionsBloc>();
        final count = bloc.commentsCount(postId, initialCommentsCount);
        return Text(
          builder?.call(count) ?? count.toString(),
          style: style,
        );
      },
    );
  }
}
