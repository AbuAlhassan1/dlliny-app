import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/controllers/funnel_bloc.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';
import 'package:hangout/presentation/business/analytics/widgets/footfall_heatmap.dart';
import 'package:hangout/presentation/business/analytics/widgets/funnel_viz.dart';
import 'package:hangout/presentation/business/analytics/widgets/pro_gate.dart';

class FunnelTab extends StatelessWidget {
  final String venueId;
  const FunnelTab({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FunnelBloc>(
      create: (_) => FunnelBloc(
        repo: serviceLocator.get<AnalyticsRepository>(),
        venueId: venueId,
      )..add(const FunnelLoaded()),
      child: const _FunnelBody(),
    );
  }
}

class _FunnelBody extends StatelessWidget {
  const _FunnelBody();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<FunnelBloc>().add(const FunnelRefreshed());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: BlocBuilder<FunnelBloc, FunnelState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(14),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _FunnelSlot(state: state.funnel),
              const SizedBox(height: 12),
              _FootfallSlot(state: state.footfall),
            ],
          );
        },
      ),
    );
  }
}

class _FunnelSlot extends StatelessWidget {
  final TileState<ConversionFunnelResponse> state;
  const _FunnelSlot({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is TileData<ConversionFunnelResponse>) {
      return FunnelViz(data: s.data);
    }
    if (s is TileProLocked<ConversionFunnelResponse>) {
      return ProGate(
        locked: true,
        feature: s.feature,
        child: FunnelViz(data: _placeholderFunnel),
      );
    }
    if (s is TileError<ConversionFunnelResponse>) {
      return AnalyticsTile(
        title: LocaleKeys.business_analytics_funnel_title.tr(),
        child: AnalyticsTileError(
          message: s.message,
          onRetry: () =>
              context.read<FunnelBloc>().add(const FunnelRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_funnel_title.tr(),
      child: const AnalyticsTileLoading(height: 140),
    );
  }
}

class _FootfallSlot extends StatelessWidget {
  final TileState<FootfallHeatmapResponse> state;
  const _FootfallSlot({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is TileData<FootfallHeatmapResponse>) {
      return FootfallHeatmap(data: s.data);
    }
    if (s is TileProLocked<FootfallHeatmapResponse>) {
      return ProGate(
        locked: true,
        feature: s.feature,
        child: FootfallHeatmap(data: _placeholderFootfall),
      );
    }
    if (s is TileError<FootfallHeatmapResponse>) {
      return AnalyticsTile(
        title: LocaleKeys.business_analytics_footfall_title.tr(),
        child: AnalyticsTileError(
          message: s.message,
          onRetry: () =>
              context.read<FunnelBloc>().add(const FunnelRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_footfall_title.tr(),
      child: const AnalyticsTileLoading(height: 180),
    );
  }
}

const _placeholderFunnel = ConversionFunnelResponse(
  venueId: 'preview',
  from: '—',
  to: '—',
  feedImpressions: 1200,
  mapImpressions: 480,
  searchImpressions: 240,
  profileViews: 360,
  newFollowers: 84,
  visitIntent: 52,
  repeatVisitors: 18,
  impressionsSampleRate: 0.1,
);

final _placeholderFootfall = FootfallHeatmapResponse(
  cells: [
    for (var d = 0; d < 7; d++)
      for (var h = 0; h < 24; h++)
        if ((d + h) % 5 != 0)
          FootfallCell(
            dayOfWeek: d,
            hourOfDay: h,
            count: ((h - 12).abs() < 4 ? 12 - (h - 18).abs() : 2)
                .clamp(0, 12),
          ),
  ],
  maxCount: 12,
  privacyFloorApplied: false,
);
