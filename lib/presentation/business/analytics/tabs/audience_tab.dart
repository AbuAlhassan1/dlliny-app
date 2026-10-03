import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/controllers/audience_bloc.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';
import 'package:hangout/presentation/business/analytics/widgets/demographics_bars.dart';
import 'package:hangout/presentation/business/analytics/widgets/footfall_heatmap.dart';
import 'package:hangout/presentation/business/analytics/widgets/loyalists_list.dart';
import 'package:hangout/presentation/business/analytics/widgets/pro_gate.dart';

class AudienceTab extends StatelessWidget {
  final String venueId;
  const AudienceTab({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AudienceBloc>(
      create: (_) => AudienceBloc(
        repo: serviceLocator.get<AnalyticsRepository>(),
        venueId: venueId,
      )..add(const AudienceLoaded()),
      child: const _AudienceBody(),
    );
  }
}

class _AudienceBody extends StatelessWidget {
  const _AudienceBody();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<AudienceBloc>().add(const AudienceRefreshed());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: BlocBuilder<AudienceBloc, AudienceState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(14),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _DemographicsSlot(state: state.demographics),
              const SizedBox(height: 12),
              _ActivitySlot(state: state.activity),
              const SizedBox(height: 12),
              _LoyalistsSlot(state: state.loyalists),
            ],
          );
        },
      ),
    );
  }
}

class _DemographicsSlot extends StatelessWidget {
  final TileState<AudienceDemographicsResponse> state;
  const _DemographicsSlot({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is TileData<AudienceDemographicsResponse>) {
      return DemographicsBars(data: s.data);
    }
    if (s is TileProLocked<AudienceDemographicsResponse>) {
      return ProGate(
        locked: true,
        feature: s.feature,
        child: DemographicsBars(data: _placeholderDemographics),
      );
    }
    if (s is TileError<AudienceDemographicsResponse>) {
      return AnalyticsTile(
        title: LocaleKeys.business_analytics_demographics_title.tr(),
        child: AnalyticsTileError(
          message: s.message,
          onRetry: () =>
              context.read<AudienceBloc>().add(const AudienceRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_demographics_title.tr(),
      child: const AnalyticsTileLoading(height: 180),
    );
  }
}

class _ActivitySlot extends StatelessWidget {
  final TileState<AudienceActivityResponse> state;
  const _ActivitySlot({required this.state});

  FootfallHeatmapResponse _asFootfall(AudienceActivityResponse a) {
    return FootfallHeatmapResponse(
      cells: [
        for (final cell in a.cells)
          FootfallCell(
            dayOfWeek: cell.dayOfWeek,
            hourOfDay: cell.hourOfDay,
            count: cell.count,
          ),
      ],
      maxCount: a.maxCount,
      privacyFloorApplied: a.privacyFloorApplied,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is TileData<AudienceActivityResponse>) {
      return FootfallHeatmap(
        data: _asFootfall(s.data),
        title: LocaleKeys.business_analytics_audience_section_when_active.tr(),
        subtitle: LocaleKeys.business_analytics_footfall_subtitle_30_days.tr(),
      );
    }
    if (s is TileProLocked<AudienceActivityResponse>) {
      return ProGate(
        locked: true,
        feature: s.feature,
        child: FootfallHeatmap(
          data: _placeholderActivity,
          title: LocaleKeys.business_analytics_audience_section_when_active.tr(),
          subtitle: LocaleKeys.business_analytics_footfall_subtitle_30_days.tr(),
        ),
      );
    }
    if (s is TileError<AudienceActivityResponse>) {
      return AnalyticsTile(
        title: LocaleKeys.business_analytics_audience_section_when_active.tr(),
        child: AnalyticsTileError(
          message: s.message,
          onRetry: () =>
              context.read<AudienceBloc>().add(const AudienceRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_audience_section_when_active.tr(),
      child: const AnalyticsTileLoading(height: 180),
    );
  }
}

class _LoyalistsSlot extends StatelessWidget {
  final TileState<LoyalistsResponse> state;
  const _LoyalistsSlot({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is TileData<LoyalistsResponse>) return LoyalistsList(data: s.data);
    if (s is TileProLocked<LoyalistsResponse>) {
      return ProGate(
        locked: true,
        feature: s.feature,
        child: LoyalistsList(data: _placeholderLoyalists),
      );
    }
    if (s is TileError<LoyalistsResponse>) {
      return AnalyticsTile(
        title: LocaleKeys.business_analytics_loyalists_title.tr(),
        child: AnalyticsTileError(
          message: s.message,
          onRetry: () =>
              context.read<AudienceBloc>().add(const AudienceRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_loyalists_title.tr(),
      child: const AnalyticsTileLoading(height: 140),
    );
  }
}

const _placeholderDemographics = AudienceDemographicsResponse(
  venueId: 'preview',
  totalFollowers: 240,
  byDistrict: [
    DemographicBucket(label: 'Karrada', count: 86),
    DemographicBucket(label: 'Mansour', count: 64),
    DemographicBucket(label: '_other_', count: 38),
  ],
  byCity: [
    DemographicBucket(label: 'Baghdad', count: 188),
    DemographicBucket(label: 'Erbil', count: 52),
  ],
  byLanguage: [
    DemographicBucket(label: 'ar', count: 196),
    DemographicBucket(label: 'en', count: 44),
  ],
  byGender: [
    DemographicBucket(label: 'male', count: 142),
    DemographicBucket(label: 'female', count: 88),
    DemographicBucket(label: 'anonymous', count: 10),
  ],
  privacyFloorApplied: true,
);

final _placeholderActivity = FootfallHeatmapResponse(
  cells: [
    for (var d = 0; d < 7; d++)
      for (var h = 0; h < 24; h++)
        if (h >= 8 && h <= 22)
          FootfallCell(
            dayOfWeek: d,
            hourOfDay: h,
            count: ((h - 12).abs() < 6
                    ? 10 - ((h - 19).abs())
                    : 2)
                .clamp(0, 10),
          ),
  ],
  maxCount: 10,
  privacyFloorApplied: false,
);

const _placeholderLoyalists = LoyalistsResponse(
  venueId: 'preview',
  days: 30,
  minMentions: 3,
  page: 0,
  size: 20,
  totalElements: 3,
  totalPages: 1,
  items: [
    Loyalist(
      userId: '1',
      username: 'sara',
      displayName: 'سارة',
      mentionCount: 12,
    ),
    Loyalist(
      userId: '2',
      username: 'ali',
      displayName: 'علي',
      mentionCount: 8,
    ),
    Loyalist(
      userId: '3',
      username: 'noor',
      displayName: 'نور',
      mentionCount: 5,
    ),
  ],
);
