import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/hub/controllers/my_hangouts/my_hub_hangouts_bloc.dart';
import 'package:hangout/presentation/hub/widgets/my_hangouts/hangout_post_card.dart';
import 'package:hangout/presentation/hub/widgets/my_hangouts/my_hangouts_skeleton.dart';

class MyHangoutsSection extends StatelessWidget {
  const MyHangoutsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyHubHangoutsBloc, MyHubHangoutsState>(
      builder: (context, state) {
        if (state is MyHubHangoutsInitial ||
            state is MyHubHangoutsEmpty ||
            state is MyHubHangoutsError) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SectionHeader(),
              const SizedBox(height: 12),
              switch (state) {
                MyHubHangoutsLoading() => const MyHangoutsSkeleton(),
                MyHubHangoutsLoaded(:final items, :final loadingMore) =>
                  _LoadedList(items: items, loadingMore: loadingMore),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 8),
      child: Row(
        children: [
          Icon(TablerIcons.calendar_event, size: 22, color: c.onSurface),
          const SizedBox(width: 6),
          Text(
            LocaleKeys.hub_my_hangouts_section_title.tr(),
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadedList extends StatelessWidget {
  final List<HangoutFeedItem> items;
  final bool loadingMore;
  const _LoadedList({required this.items, required this.loadingMore});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.only(left: 15, right: 15, bottom: 14),
            child: HangoutPostCard(
              key: ValueKey('hub-hangout-${item.id}'),
              item: item,
            ),
          ),
        if (loadingMore)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1,
              ),
            ),
          ),
      ],
    );
  }
}
