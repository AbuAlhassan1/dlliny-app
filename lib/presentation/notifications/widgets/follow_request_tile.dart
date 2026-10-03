import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/user_summary_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/notifications/controllers/follow_requests_bloc.dart';

class FollowRequestTile extends StatelessWidget {
  final UserSummaryResponse user;
  const FollowRequestTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bloc = context.read<FollowRequestsBloc>();
    final name = (user.displayName?.isNotEmpty ?? false)
        ? user.displayName!
        : (user.username ?? '');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.surfaceMuted,
            ),
            child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                ? CachedNetworkImage(
                    imageUrl: user.avatarUrl!,
                    fit: BoxFit.cover,
                    memCacheWidth: 120,
                    errorWidget: (_, _, _) => Icon(
                      TablerIcons.user,
                      color: c.onSurfaceSecondary,
                      size: 22,
                    ),
                  )
                : Icon(
                    TablerIcons.user,
                    color: c.onSurfaceSecondary,
                    size: 22,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (user.verified) ...[
                      const SizedBox(width: 4),
                      Icon(
                        TablerIcons.rosette_discount_check_filled,
                        color: c.success,
                        size: 14,
                      ),
                    ],
                  ],
                ),
                if (user.username != null && user.username!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '@${user.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            label: LocaleKeys.chat_request_banner_accept.tr(),
            color: c.primary,
            textColor: c.onPrimary,
            onTap: () => bloc.add(AcceptFollowRequest(user.id)),
          ),
          const SizedBox(width: 6),
          _ActionButton(
            label: LocaleKeys.chat_request_banner_reject.tr(),
            color: c.surfaceMuted,
            textColor: c.onSurface,
            onTap: () => bloc.add(RejectFollowRequest(user.id)),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;
  const _ActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
