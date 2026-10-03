import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/controller/create_hangout_controller/create_hangout_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/create_post_controller/create_post_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/hangouts/my_hangouts_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/posts/my_posts_bloc.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/create_hangout_page_wrapper.dart';
import 'package:hangout/presentation/my_profile/pages/create_post/create_post_page_wrapper.dart';

class AddContentButton extends StatelessWidget {
  const AddContentButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.onSurface.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: PopupMenuButton<String>(
            onOpened: () => HapticFeedback.warningNotification(),
            onSelected: (String result) {
              if (result == 'post') {
                final myPostsBloc = context.read<MyPostsBloc>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => CreatePostBloc()),
                        BlocProvider.value(value: myPostsBloc),
                      ],
                      child: const CreatePostPageWrapper(),
                    ),
                  ),
                );
              } else if (result == 'hangout') {
                final myHangoutsBloc = context.read<MyHangoutsBloc>();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => MultiBlocProvider(
                      providers: [
                        BlocProvider(create: (_) => CreateHangoutBloc()),
                        BlocProvider.value(value: myHangoutsBloc),
                      ],
                      child: const CreateHangoutPageWrapper(),
                    ),
                  ),
                );
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'post',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.profile_my_add_content_post.tr(),
                      style: TextStyle(color: c.onSurface),
                    ),
                    Icon(TablerIcons.photo_plus, color: c.onSurface, size: 18),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'hangout',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      LocaleKeys.profile_my_add_content_hangout.tr(),
                      style: TextStyle(color: c.onSurface),
                    ),
                    Icon(TablerIcons.users, color: c.onSurface, size: 18),
                  ],
                ),
              ),
            ],
            borderRadius: BorderRadius.circular(10),
            color: c.surfaceElevated,
            padding: EdgeInsetsGeometry.zero,
            menuPadding: EdgeInsets.zero,
            icon: Icon(TablerIcons.plus, color: c.onSurface),
            position: PopupMenuPosition.under,
          ),
        ),
      ),
    );
  }
}
