// ignore_for_file: use_build_context_synchronously
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/app_page_gradient.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/controller/hangouts/my_hangouts_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/posts/my_posts_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/complete_profile_dialog.dart';
import 'package:hangout/presentation/my_profile/widgets/content_tabs_bar.dart';
import 'package:hangout/presentation/my_profile/widgets/hangouts_grid.dart';
import 'package:hangout/presentation/my_profile/widgets/posts_grid.dart';
import 'package:hangout/presentation/my_profile/widgets/profile_user_card.dart';

class MyProfilePageWrapper extends StatefulWidget {
  const MyProfilePageWrapper({super.key});

  @override
  State<MyProfilePageWrapper> createState() => _MyProfilePageWrapperState();
}

class _MyProfilePageWrapperState extends State<MyProfilePageWrapper>
    with AutomaticKeepAliveClientMixin {
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

  void onRefresh() {
    context.read<MyProfileBloc>().add(GetMyProfile());
    context.read<MyPostsBloc>().add(GetMyPosts());
    context.read<MyHangoutsBloc>().add(GetMyHangouts());
  }

  @override
  void initState() {
    context.read<MyPostsBloc>().add(GetMyPosts());
    context.read<MyHangoutsBloc>().add(GetMyHangouts());
    Future.delayed(const Duration(seconds: 1)).then((_) {
      if (!mounted) return;
      blocListener(context, context.read<MyProfileBloc>().state);
    });
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.c;
    return BlocListener<MyProfileBloc, ProfileState>(
      listener: blocListener,
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
              MyProfileUserCard(),
              SliverToBoxAdapter(child: SizedBox(height: 5)),
              ContentTabsBar(onTabSelected: switchPage, pageIndex: pageIndex),
              SliverToBoxAdapter(child: SizedBox(height: 5)),
            ],
            body: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      RefreshIndicator(
                        onRefresh: () async => onRefresh(),
                        color: c.onSurface,
                        strokeWidth: 2,
                        child: PostsGrid(),
                      ),
                      HangoutsGrid(),
                      Container(
                        color: Colors.transparent,
                        child: Center(
                          child: Text(
                            LocaleKeys.profile_my_tabs_invited_hangouts.tr(),
                          ),
                        ),
                      ),
                    ],
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

  void blocListener(BuildContext context, ProfileState state) {
    if (state is MyProfileLoaded) {
      final UserDto profile = context.read<MyProfileBloc>().user!;
      if (profile.displayName == null ||
          profile.displayName!.isEmpty ||
          profile.username == null ||
          profile.username!.isEmpty ||
          profile.username!.startsWith("user")
        ) {
        showCompleteProfileDialog(context);
      }
    }

    if (state is MyPostsMoreError) {
      appToast.error((state as MyPostsMoreError).message);
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class MyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  const MyHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(MyHeaderDelegate oldDelegate) {
    return oldDelegate.maxHeight != maxHeight ||
        oldDelegate.minHeight != minHeight ||
        oldDelegate.child != child;
  }
}
