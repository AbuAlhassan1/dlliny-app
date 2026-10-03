import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/presentation/post/widgets/heart_burst_overlay.dart';

class HangoutLikeButton extends StatefulWidget {
  final bool likedByMe;
  final VoidCallback onLike;
  final Color likedColor;
  final Color idleColor;

  const HangoutLikeButton({
    super.key,
    required this.likedByMe,
    required this.onLike,
    this.likedColor = Colors.red,
    this.idleColor = Colors.white,
  });

  @override
  State<HangoutLikeButton> createState() => _HangoutLikeButtonState();
}

class _HangoutLikeButtonState extends State<HangoutLikeButton> {
  final HeartBurstController _burst = HeartBurstController();

  @override
  Widget build(BuildContext context) {
    final liked = widget.likedByMe;
    return HeartBurstOverlay(
      controller: _burst,
      child: IconButton(
        onPressed: () {
          final wasLiked = liked;
          widget.onLike();
          if (!wasLiked) _burst.fire();
        },
        icon: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            liked ? TablerIcons.heart_filled : TablerIcons.heart,
            key: ValueKey(liked),
            color: liked ? widget.likedColor : widget.idleColor,
          ),
        ),
      ),
    );
  }
}
