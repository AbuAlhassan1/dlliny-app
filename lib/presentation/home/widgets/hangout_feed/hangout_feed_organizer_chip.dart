import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/widgets/user_avatar.dart';

class HangoutFeedOrganizerChip extends StatelessWidget {
  final HangoutOrganizerUser user;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? createdLabel;

  const HangoutFeedOrganizerChip({
    super.key,
    required this.user,
    required this.onTap,
    this.onLongPress,
    this.createdLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = user.displayName?.isNotEmpty == true
        ? user.displayName!
        : user.username;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Row(
        children: [
          SizedBox(
            width: 45,
            height: 45,
            child: UserAvatar(avatarUrl: user.avatarUrl ?? ''),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: c.onSurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        LocaleKeys.hangout_role_pill_organizer.tr(),
                        style: TextStyle(
                          color: c.surfaceMuted,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        name,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '@${user.username}',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                  ),
                ),
                if (createdLabel != null && createdLabel!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        TablerIcons.clock,
                        size: 10,
                        color: c.onSurfaceMuted,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          createdLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurfaceMuted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
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
