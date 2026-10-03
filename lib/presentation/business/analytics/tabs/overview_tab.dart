import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/controllers/overview_bloc.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';
import 'package:hangout/presentation/business/analytics/widgets/buzz_card.dart';
import 'package:hangout/presentation/business/analytics/widgets/daily_chart.dart';
import 'package:hangout/presentation/business/analytics/widgets/hangout_funnel_card.dart';

class OverviewTab extends StatelessWidget {
  final String venueId;
  const OverviewTab({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OverviewBloc>(
      create: (_) => OverviewBloc(
        repo: serviceLocator.get<AnalyticsRepository>(),
        venueId: venueId,
      )..add(const OverviewLoaded()),
      child: const _OverviewBody(),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OverviewBloc>().add(const OverviewRefreshed());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: BlocBuilder<OverviewBloc, OverviewState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(14),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _TileSlot<BuzzAnalyticsResponse>(
                state: state.buzz,
                title: LocaleKeys.business_analytics_buzz_title.tr(),
                builder: (d) => BuzzCard(data: d),
              ),
              const SizedBox(height: 12),
              _TileSlot<DailySeriesResponse>(
                state: state.daily,
                title: LocaleKeys.business_analytics_daily_title.tr(),
                builder: (d) => DailyChart(data: d),
              ),
              const SizedBox(height: 12),
              _TileSlot<HangoutFunnelResponse>(
                state: state.hangoutFunnel,
                title: LocaleKeys.business_analytics_hangout_funnel_title.tr(),
                builder: (d) => HangoutFunnelCard(data: d),
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
              context.read<OverviewBloc>().add(const OverviewRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: title,
      child: const AnalyticsTileLoading(),
    );
  }
}
