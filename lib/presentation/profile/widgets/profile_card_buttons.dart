import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/helpers/open_direct_conversation.dart';
import 'package:hangout/presentation/chat/helpers/open_share_sheet.dart';
import 'package:hangout/presentation/profile/controllers/profile_bloc.dart';

class ProfileCardButtons extends StatelessWidget {
  const ProfileCardButtons({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        final bloc = context.read<ProfileBloc>();
        final isFollowing = bloc.isFollowing;
        final isPending = bloc.isPending;
        final isBusy =
            state is FollowUserLoading || state is UnfollowUserLoading;

        final hasRelationship = isFollowing || isPending;
        final String label;
        final IconData? leadingIcon;
        if (isPending) {
          label = LocaleKeys.profile_follow_button_requested.tr();
          leadingIcon = TablerIcons.clock;
        } else if (isFollowing) {
          label = LocaleKeys.profile_follow_button_unfollow.tr();
          leadingIcon = null;
        } else {
          label = LocaleKeys.profile_follow_button_follow.tr();
          leadingIcon = null;
        }

        return Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: isBusy
                    ? null
                    : () => bloc.add(
                        hasRelationship ? UnfollowUser() : FollowUser()),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: hasRelationship ? Colors.transparent : c.primary,
                    border: Border.all(color: c.onSurface, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: isBusy
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: c.onSurface,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (leadingIcon != null) ...[
                                Icon(
                                  leadingIcon,
                                  size: 16,
                                  color: c.onSurface,
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: hasRelationship
                                      ? c.onSurface
                                      : c.onPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: bloc.user == null
                    ? null
                    : () => openDirectConversation(
                          context,
                          peerType: ChatMemberType.user,
                          peerId: bloc.user!.id,
                        ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(color: c.onSurface, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          TablerIcons.message_circle,
                          size: 16,
                          color: c.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          LocaleKeys.profile_actions_message.tr(),
                          style: TextStyle(
                            fontSize: 16,
                            color: c.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: bloc.user == null
                    ? null
                    : () => openShareSheet(
                          context,
                          resourceType: SharedResourceType.user,
                          resourceId: bloc.user!.id,
                          headlineLabel: LocaleKeys.profile_actions_share_headline.tr(),
                        ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      LocaleKeys.common_share.tr(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: c.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
