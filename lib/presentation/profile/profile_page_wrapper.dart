// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/app_page_gradient.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/presentation/profile/controllers/hangouts/user_hangouts_bloc.dart';
import 'package:hangout/presentation/profile/controllers/posts/user_posts_bloc.dart';
import 'package:hangout/presentation/profile/controllers/profile_bloc.dart';
import 'package:hangout/presentation/profile/widgets/content_tabs_bar.dart';
import 'package:hangout/presentation/profile/widgets/hangouts_grid.dart';
import 'package:hangout/presentation/profile/widgets/posts_grid.dart';
import 'package:hangout/presentation/profile/widgets/profile_user_card.dart';

class ProfilePageWrapper extends StatefulWidget {
  final String username;
  const ProfilePageWrapper({super.key, required this.username});

  @override
  State<ProfilePageWrapper> createState() => _ProfilePageWrapperState();
}

class _ProfilePageWrapperState extends State<ProfilePageWrapper> {
  final ScrollController scrollController = ScrollController();
  final PageController pageController = PageController();
  int pageIndex = 0;

  void switchPage(int index) {
    if (index == pageIndex) return;
    setState(() => pageIndex = index);
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
    HapticFeedback.selectionClick();
  }

  @override
  void dispose() {
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return MultiBlocProvider(
      providers: [
        BlocProvider<ProfileBloc>(
          create: (_) =>
              ProfileBloc()..add(GetUserProfile(widget.username)),
        ),
        BlocProvider<UserPostsBloc>(create: (_) => UserPostsBloc()),
        BlocProvider<UserHangoutsBloc>(create: (_) => UserHangoutsBloc()),
      ],
      child: BlocListener<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileLoaded) {
            final user = context.read<ProfileBloc>().user;
            if (user != null) {
              context.read<UserPostsBloc>().add(GetUserPosts(user.id));
              context.read<UserHangoutsBloc>().add(GetUserHangouts(user.id));
            }
          }
          if (state is FollowUserError) appToast.error(state.message);
          if (state is UnfollowUserError) appToast.error(state.message);
        },
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: DecoratedBox(
            decoration: BoxDecoration(gradient: appPageGradient(context)),
            child: SafeArea(
              bottom: false,
              child: NestedScrollView(
              controller: scrollController,
              physics: const BouncingScrollPhysics(),
              clipBehavior: Clip.none,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                const ProfileUserCard(),
                const SliverToBoxAdapter(child: SizedBox(height: 5)),
                ContentTabsBar(
                  onTabSelected: switchPage,
                  pageIndex: pageIndex,
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 5)),
              ],
              body: PageView(
                controller: pageController,
                physics: const NeverScrollableScrollPhysics(),
                clipBehavior: Clip.none,
                children: [
                  RefreshIndicator(
                    onRefresh: () async => context
                        .read<ProfileBloc>()
                        .add(GetUserProfile(widget.username)),
                    color: c.onSurface,
                    strokeWidth: 2,
                    child: BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        final user = context.read<ProfileBloc>().user;
                        if (user == null) {
                          return const SizedBox();
                        }
                        return PostsGrid(userId: user.id);
                      },
                    ),
                  ),
                  BlocBuilder<ProfileBloc, ProfileState>(
                    builder: (context, state) {
                      final user = context.read<ProfileBloc>().user;
                      if (user == null) {
                        return const SizedBox();
                      }
                      return HangoutsGrid(userId: user.id);
                    },
                  ),
                ],
              ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
