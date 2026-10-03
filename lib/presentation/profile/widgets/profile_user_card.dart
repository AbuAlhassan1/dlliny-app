import 'dart:ui' show ImageFilter;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart'
    show MyProfileBloc;
import 'package:hangout/presentation/profile/controllers/profile_bloc.dart';
import 'package:hangout/presentation/profile/widgets/profile_actions_sheet.dart';
import 'package:hangout/presentation/profile/widgets/profile_card_buttons.dart';
import 'package:hangout/presentation/profile/widgets/user_avatar.dart';
import 'package:hangout/presentation/shared/widgets/avatar_preview_overlay.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:wave_divider/wave_divider.dart';

class ProfileUserCard extends StatelessWidget {
  const ProfileUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isRtl = context.locale.languageCode == 'ar';
    return BlocBuilder<ProfileBloc, ProfileState>(
      builder: (context, state) {
        if (state is ProfileLoading || state is ProfileInitial) {
          return SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Shimmer(
                    duration: const Duration(milliseconds: 1200),
                    child: Container(
                      height: 265,
                      decoration: BoxDecoration(
                        color: c.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        if (state is ProfileError) {
          return SliverToBoxAdapter(
            child: Center(child: Text('Error: ${state.message}')),
          );
        }

        final UserDto? profile = context.read<ProfileBloc>().user;
        if (profile == null) return const SliverToBoxAdapter(child: SizedBox());

        return SliverToBoxAdapter(
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                InkWell(
                                  onTap: () =>
                                      Navigator.of(context).maybePop(),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: c.border,
                                        width: 1,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(100),
                                    ),
                                    child: ClipRRect(
                                      borderRadius:
                                          BorderRadius.circular(100),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 10,
                                          sigmaY: 10,
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(10),
                                          child: Icon(
                                            isRtl
                                                ? TablerIcons.chevron_right
                                                : TablerIcons.chevron_left,
                                            color: c.onSurface,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    profile.displayName ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: c.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _LevelBadge(profile: profile),
                                const SizedBox(width: 8),
                                _MoreChip(
                                  userId: profile.id,
                                  username: profile.username ?? '',
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                GestureDetector(
                                  onLongPress: () =>
                                      showAvatarPreviewOverlay(
                                    context,
                                    imageUrl: profile.avatarUrl ?? '',
                                  ),
                                  child: UserAvatar(
                                    avatarUrl: profile.avatarUrl,
                                  ),
                                ),
                                const SizedBox(width: 15),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '@${profile.username}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.onSurfaceSecondary,
                                          ),
                                        ),
                                        Text(
                                          profile.bio ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: c.onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            Row(
                              children: [
                                _StatBox(
                                  value: profile.followersCount.toString(),
                                  label: LocaleKeys.profile_stats_followers.tr(),
                                ),
                                const SizedBox(width: 10),
                                _StatBox(
                                  value: profile.followingCount.toString(),
                                  label: LocaleKeys.profile_stats_following.tr(),
                                ),
                                const SizedBox(width: 10),
                                _StatBox(
                                  value: profile.postsCount.toString(),
                                  label: LocaleKeys.profile_stats_posts.tr(),
                                ),
                                const SizedBox(width: 10),
                                _StatBox(
                                  value: profile.hangoutsCount.toString(),
                                  label: LocaleKeys.profile_stats_hangouts.tr(),
                                ),
                              ],
                            ),

                            const SizedBox(height: 15),

                            const ProfileCardButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                WaveDivider(color: c.onSurface, thickness: 1.5),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MoreChip extends StatelessWidget {
  final String userId;
  final String username;
  const _MoreChip({required this.userId, required this.username});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final myId = context.read<MyProfileBloc>().user?.id;
    if (myId != null && myId == userId) return const SizedBox.shrink();
    return InkWell(
      onTap: () => showProfileActionsSheet(
        context,
        userId: userId,
        username: username,
      ),
      borderRadius: BorderRadius.circular(100),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: c.border, width: 1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Icon(TablerIcons.dots, color: c.onSurface, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final UserDto profile;
  const _LevelBadge({required this.profile});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isMax = profile.isMaxLevel;
    final label = isMax
        ? LocaleKeys.points_max_badge.tr()
        : LocaleKeys.points_level_badge.tr(
            namedArgs: {'level': profile.level.toString()},
          );
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.border, width: 1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isMax ? TablerIcons.trophy_filled : TablerIcons.trophy,
                  color: isMax ? c.success : c.primary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String value;
  final String label;
  const _StatBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: c.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c.onSurfaceSecondary,
              fontWeight: FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
