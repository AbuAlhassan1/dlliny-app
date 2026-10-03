import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/points/controllers/user_points_bloc.dart';

class LevelUpToastListener extends StatelessWidget {
  final Widget child;
  const LevelUpToastListener({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocListener<UserPointsBloc, UserPointsState>(
      listenWhen: (_, curr) =>
          curr is UserPointsLoaded &&
          curr.previousLevel != null &&
          curr.points != null &&
          curr.previousLevel != curr.points!.level,
      listener: (context, state) {
        final level = (state as UserPointsLoaded).points!.level;
        appToast.success(
          LocaleKeys.points_level_up_toast.tr(
            namedArgs: {'level': level.toString()},
          ),
        );
      },
      child: child,
    );
  }
}
