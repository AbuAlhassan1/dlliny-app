import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_like_button.dart';
import 'package:wave_divider/wave_divider.dart';

class HangoutFeedActionsBar extends StatelessWidget {
  final bool likedByMe;
  final int likesCount;
  final int commentsCount;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;

  const HangoutFeedActionsBar({
    super.key,
    required this.likedByMe,
    required this.likesCount,
    required this.commentsCount,
    required this.onLike,
    required this.onComment,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(
                TablerIcons.heart_filled,
                color: Colors.red,
                size: 15,
              ),
              const SizedBox(width: 5),
              Text(
                '$likesCount',
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                LocaleKeys.hangout_comments_count.tr(
                  namedArgs: {'n': '$commentsCount'},
                ),
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 5),
        
        WaveDivider(
          color: c.divider,
          padding: EdgeInsets.zero,
          thickness: 1,
          waveHeight: 1,
        ),

        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            HangoutLikeButton(
              likedByMe: likedByMe,
              onLike: onLike,
              idleColor: c.onSurface,
            ),
            IconButton(
              onPressed: onComment,
              icon: Icon(TablerIcons.message, color: c.onSurface),
            ),
            IconButton(
              onPressed: onShare,
              icon: Icon(TablerIcons.send, color: c.onSurface),
            ),
            const Spacer(),
          ],
        ),
      ],
    );
  }
}
