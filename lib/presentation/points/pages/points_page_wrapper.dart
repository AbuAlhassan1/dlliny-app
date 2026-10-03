import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/app_page_gradient.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/points/controllers/user_points_bloc.dart';
import 'package:hangout/presentation/points/widgets/level_progress_card.dart';

class PointsPageWrapper extends StatefulWidget {
  const PointsPageWrapper({super.key});

  @override
  State<PointsPageWrapper> createState() => _PointsPageWrapperState();
}

class _PointsPageWrapperState extends State<PointsPageWrapper> {
  @override
  void initState() {
    super.initState();
    context.read<UserPointsBloc>().add(RefreshUserPoints());
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: Icon(TablerIcons.chevron_right, color: c.onSurface),
        ),
        title: Text(
          LocaleKeys.points_page_title.tr(),
          style: TextStyle(
            color: c.onSurface,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        centerTitle: true,
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: appPageGradient(context)),
        child: RefreshIndicator(
          color: c.onSurface,
          backgroundColor: c.background,
          onRefresh: () async {
            final bloc = context.read<UserPointsBloc>();
            bloc.add(RefreshUserPoints());
            await bloc.stream.firstWhere(
              (s) => s is UserPointsLoaded || s is UserPointsError,
            );
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 90, 16, 24),
            children: const [
              LevelProgressCard(),
            ],
          ),
        ),
      ),
    );
  }
}
