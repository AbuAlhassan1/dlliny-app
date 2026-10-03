import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/media/video_source.dart';
import 'package:hangout/domain/dto/response/weekly_recommendations_response.dart';
import 'package:hangout/presentation/shared/widgets/mount_entrance.dart';
import 'package:hangout/presentation/hub/controllers/weekly_venues/weekly_venues_bloc.dart';
import 'package:hangout/presentation/hub/widgets/weekly_venues/weekly_venue_card.dart';
import 'package:hangout/presentation/hub/widgets/weekly_venues/weekly_venues_loading_row.dart';

class WeeklyVenuesSection extends StatelessWidget {
  const WeeklyVenuesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WeeklyVenuesBloc, WeeklyVenuesState>(
      builder: (context, state) {
        if (state is WeeklyVenuesInitial ||
            state is WeeklyVenuesEmpty ||
            state is WeeklyVenuesError) {
          return const SizedBox.shrink();
        }

        return MountEntrance(
          child: Padding(
            padding: const EdgeInsets.only(top: 0, bottom: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                switch (state) {
                  WeeklyVenuesLoading() => const WeeklyVenuesLoadingRow(),
                  WeeklyVenuesLoaded(:final items) => _LoadedRow(items: items),
                  _ => const SizedBox.shrink(),
                },
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LoadedRow extends StatefulWidget {
  final List<WeeklyRecommendationItem> items;
  const _LoadedRow({required this.items});

  @override
  State<_LoadedRow> createState() => _LoadedRowState();
}

class _LoadedRowState extends State<_LoadedRow> {
  late final ValueNotifier<String?> _activeAudioVenueId =
      ValueNotifier<String?>(_initialActiveAudioVenueId());

  String? _initialActiveAudioVenueId() {
    for (final item in widget.items) {
      if (isVideoCover(
        coverUrl: item.coverUrl,
        coverStreamUrl: item.coverStreamUrl,
      )) {
        return item.venueId;
      }
    }
    return null;
  }

  @override
  void dispose() {
    _activeAudioVenueId.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WeeklyCoverAudioScope(
      notifier: _activeAudioVenueId,
      child: SizedBox(
        height: WeeklyVenueCard.height,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
          itemCount: widget.items.length,
          clipBehavior: Clip.hardEdge,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) => WeeklyVenueCard(item: widget.items[i]),
        ),
      ),
    );
  }
}
