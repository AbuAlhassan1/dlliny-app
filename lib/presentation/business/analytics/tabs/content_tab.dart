import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/controllers/content_bloc.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';
import 'package:hangout/presentation/business/analytics/widgets/review_trend_chart.dart';
import 'package:hangout/presentation/business/analytics/widgets/top_memories_strip.dart';
import 'package:hangout/presentation/business/analytics/widgets/top_posts_grid.dart';

class ContentTab extends StatelessWidget {
  final String venueId;
  const ContentTab({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ContentBloc>(
      create: (_) => ContentBloc(
        repo: serviceLocator.get<AnalyticsRepository>(),
        venueId: venueId,
      )..add(const ContentLoaded()),
      child: const _ContentBody(),
    );
  }
}

class _ContentBody extends StatelessWidget {
  const _ContentBody();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ContentBloc>().add(const ContentRefreshed());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: BlocBuilder<ContentBloc, ContentState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(14),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _TileSlot<TopPostsResponse>(
                state: state.topPosts,
                title: LocaleKeys.business_analytics_top_posts_title.tr(),
                builder: (d) => TopPostsGrid(data: d),
              ),
              const SizedBox(height: 12),
              _TileSlot<TopMemoriesResponse>(
                state: state.topMemories,
                title: LocaleKeys.business_analytics_top_memories_title.tr(),
                builder: (d) => TopMemoriesStrip(data: d),
              ),
              const SizedBox(height: 12),
              _TileSlot<ReviewTrendResponse>(
                state: state.reviewTrend,
                title: LocaleKeys.business_analytics_review_trend_title.tr(),
                builder: (d) => ReviewTrendChart(data: d),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TileSlot<T> extends StatelessWidget {
  final TileState<T> state;
  final String title;
  final Widget Function(T data) builder;

  const _TileSlot({
    required this.state,
    required this.title,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is TileData<T>) return builder(s.data);
    if (s is TileError<T>) {
      return AnalyticsTile(
        title: title,
        child: AnalyticsTileError(
          message: s.message,
          onRetry: () =>
              context.read<ContentBloc>().add(const ContentRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: title,
      child: const AnalyticsTileLoading(),
    );
  }
}
