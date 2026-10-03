// ignore_for_file: use_build_context_synchronously
import 'dart:developer';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/controller/followers_following/followers_following_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/followers_following_sheet.dart';
import 'package:hangout/presentation/my_profile/widgets/user_avatar.dart';
import 'package:hangout/presentation/my_profile/widgets/user_profile_card_buttons.dart';
import 'package:hangout/presentation/points/pages/points_page_wrapper.dart';
import 'package:hangout/presentation/settings/settings_page_wrapper.dart';
import 'package:hangout/presentation/shared/widgets/avatar_preview_overlay.dart';
import 'package:shimmer_animation/shimmer_animation.dart';
import 'package:wave_divider/wave_divider.dart';

class MyProfileUserCard extends StatelessWidget {
  const MyProfileUserCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MyProfileBloc, ProfileState>(
      builder: (context, state) {
        log(state.runtimeType.toString());
        if (state is MyProfileLoading) {
          return SliverToBoxAdapter(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(left: 15, right: 15),
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

        if (state is MyProfileError) {
          return SliverToBoxAdapter(
            child: Center(child: Text('Error: ${state.message}')),
          );
        }

        if (state is MyProfileLoaded || state is AvatarUploadUrlLoading) {
          final UserDto profile = context.read<MyProfileBloc>().user!;
          return SliverToBoxAdapter(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: Column(
                children: [
                  ClipRRect(
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
                                Expanded(
                                  child: Text(
                                    profile.displayName ?? "",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: c.onSurface,
                                    ),
                                  ),
                                ),

                                _LevelPill(profile: profile),
                                const SizedBox(width: 8),

                                InkWell(
                                  onTap: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => SettingsPageWrapper(),
                                    ),
                                  ),
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
                                          child: Icon(
                                            TablerIcons.menu_2,
                                            color: c.onSurface,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      
                            const SizedBox(height: 15),
                      
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                state is AvatarUploadUrlLoading
                                    ? ClipRRect(
                                        borderRadius: BorderRadius.circular(50),
                                        child: Shimmer(
                                          child: Container(
                                            width: 80,
                                            height: 80,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: c.surfaceMuted,
                                            ),
                                          ),
                                        ),
                                      )
                                    : GestureDetector(
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '@${profile.username}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.onSurfaceSecondary,
                                          ),
                                        ),
                                        Text(
                                          "${profile.bio}",
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
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => showFollowersFollowingSheet(
                                      context: context,
                                      kind: FollowKind.followers,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          profile.followersCount.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: c.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          LocaleKeys.profile_my_stats_followers.tr(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.onSurfaceSecondary,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => showFollowersFollowingSheet(
                                      context: context,
                                      kind: FollowKind.following,
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          profile.followingCount.toString(),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: c.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          LocaleKeys.profile_my_stats_following.tr(),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: c.onSurfaceSecondary,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        profile.postsCount.toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: c.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        LocaleKeys.profile_my_stats_posts.tr(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.onSurfaceSecondary,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        profile.hangoutsCount.toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: c.onSurface,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        LocaleKeys.profile_my_stats_hangouts.tr(),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.onSurfaceSecondary,
                                          fontWeight: FontWeight.normal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                      
                            const SizedBox(height: 15),
                      
                            UserProfileCardButtons(),
                          ],
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 10),

                  WaveDivider(
                    color: c.onSurface, thickness: 1.5
                  ),
                ],
              ),
            ),
          );
        }

        return SliverToBoxAdapter(child: SizedBox());
      },
    );
  }
}

class _LevelPill extends StatelessWidget {
  final UserDto profile;
  const _LevelPill({required this.profile});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isMax = profile.isMaxLevel;
    final label = isMax
        ? LocaleKeys.points_max_badge.tr()
        : LocaleKeys.points_level_badge.tr(
            namedArgs: {'level': profile.level.toString()},
          );
    final points = NumberFormat.compact().format(profile.totalPoints);

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const PointsPageWrapper()),
      ),
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
                  Text(
                    ' · $points',
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UserInfoBox extends StatelessWidget {
  final Widget child;
  const UserInfoBox({super.key, this.child = const SizedBox.shrink()});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(20),
          ),
          child: child,
        ),
      ),
    );
  }
}
