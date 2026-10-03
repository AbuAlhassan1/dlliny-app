import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/controllers/competition_bloc.dart';
import 'package:hangout/presentation/business/analytics/controllers/tile_state.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';
import 'package:hangout/presentation/business/analytics/widgets/leaderboard_card.dart';
import 'package:hangout/presentation/business/analytics/widgets/movers_strip.dart';
import 'package:hangout/presentation/business/analytics/widgets/peer_benchmark_bars.dart';
import 'package:hangout/presentation/business/analytics/widgets/pro_gate.dart';

class CompetitionTab extends StatelessWidget {
  final String venueId;
  const CompetitionTab({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CompetitionBloc>(
      create: (_) => CompetitionBloc(
        repo: serviceLocator.get<AnalyticsRepository>(),
        venueId: venueId,
      )..add(const CompetitionLoaded()),
      child: const _CompetitionBody(),
    );
  }
}

class _CompetitionBody extends StatelessWidget {
  const _CompetitionBody();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<CompetitionBloc>().add(const CompetitionRefreshed());
        await Future.delayed(const Duration(milliseconds: 600));
      },
      child: BlocBuilder<CompetitionBloc, CompetitionState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(14),
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              _LeaderboardSlot(state: state.leaderboard),
              const SizedBox(height: 12),
              _MoversSlot(state: state.movers),
              const SizedBox(height: 12),
              _PeerBenchmarkSlot(state: state.peerBenchmark),
            ],
          );
        },
      ),
    );
  }
}

class _LeaderboardSlot extends StatelessWidget {
  final TileState<CategoryLeaderboardResponse> state;
  const _LeaderboardSlot({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is TileData<CategoryLeaderboardResponse>) {
      return LeaderboardCard(data: s.data);
    }
    if (s is TileProLocked<CategoryLeaderboardResponse>) {
      return ProGate(
        locked: true,
        feature: s.feature,
        child: LeaderboardCard(data: _placeholderLeaderboard),
      );
    }
    if (s is TileError<CategoryLeaderboardResponse>) {
      return AnalyticsTile(
        title: LocaleKeys.business_analytics_leaderboard_title.tr(),
        child: AnalyticsTileError(
          message: s.message,
          onRetry: () => context
              .read<CompetitionBloc>()
              .add(const CompetitionRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_leaderboard_title.tr(),
      child: const AnalyticsTileLoading(height: 160),
    );
  }
}

class _MoversSlot extends StatelessWidget {
  final TileState<MoversResponse> state;
  const _MoversSlot({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is TileData<MoversResponse>) return MoversStrip(data: s.data);
    if (s is TileProLocked<MoversResponse>) {
      return ProGate(
        locked: true,
        feature: s.feature,
        child: MoversStrip(data: _placeholderMovers),
      );
    }
    if (s is TileError<MoversResponse>) {
      return AnalyticsTile(
        title: LocaleKeys.business_analytics_movers_title_risers.tr(),
        child: AnalyticsTileError(
          message: s.message,
          onRetry: () => context
              .read<CompetitionBloc>()
              .add(const CompetitionRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_movers_title_risers.tr(),
      child: const AnalyticsTileLoading(height: 100),
    );
  }
}

class _PeerBenchmarkSlot extends StatelessWidget {
  final TileState<PeerBenchmarkResponse> state;
  const _PeerBenchmarkSlot({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state;
    if (s is TileData<PeerBenchmarkResponse>) {
      return PeerBenchmarkBars(data: s.data);
    }
    if (s is TileProLocked<PeerBenchmarkResponse>) {
      return ProGate(
        locked: true,
        feature: s.feature,
        child: PeerBenchmarkBars(data: _placeholderBenchmark),
      );
    }
    if (s is TileError<PeerBenchmarkResponse>) {
      return AnalyticsTile(
        title: LocaleKeys.business_analytics_peer_benchmark_title.tr(),
        child: AnalyticsTileError(
          message: s.message,
          onRetry: () => context
              .read<CompetitionBloc>()
              .add(const CompetitionRefreshed()),
        ),
      );
    }
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_peer_benchmark_title.tr(),
      child: const AnalyticsTileLoading(height: 160),
    );
  }
}

const _cohort = AnalyticsCohort(
  categoryNameAr: 'كافيهات',
  districtNameAr: 'الكرادة',
  size: 14,
);

const _placeholderLeaderboard = CategoryLeaderboardResponse(
  weekStart: '—',
  cohort: _cohort,
  entries: [
    LeaderboardEntry(
      rank: 1,
      venueId: 'a',
      venueNameAr: 'منشأة المركز',
      venueNameEn: '',
      buzzScore: 184.0,
      isYou: false,
    ),
    LeaderboardEntry(
      rank: 2,
      venueId: 'b',
      venueNameAr: 'منشأة الثاني',
      venueNameEn: '',
      buzzScore: 162.5,
      isYou: false,
    ),
    LeaderboardEntry(
      rank: 3,
      venueId: 'c',
      venueNameAr: 'منشأتك',
      venueNameEn: '',
      buzzScore: 140.0,
      isYou: true,
    ),
  ],
);

const _placeholderMovers = MoversResponse(
  weekStart: '—',
  direction: 'risers',
  entries: [
    MoverEntry(
      venueId: 'x',
      venueNameAr: 'مثال صاعد',
      venueNameEn: '',
      buzzScore: 152.0,
      deltaFromPrev: 34.0,
      rankInCohort: 2,
      isYou: false,
    ),
    MoverEntry(
      venueId: 'y',
      venueNameAr: 'منشأتك',
      venueNameEn: '',
      buzzScore: 140.0,
      deltaFromPrev: 22.0,
      rankInCohort: 3,
      isYou: true,
    ),
    MoverEntry(
      venueId: 'z',
      venueNameAr: 'مثال ثالث',
      venueNameEn: '',
      buzzScore: 96.0,
      deltaFromPrev: 12.0,
      rankInCohort: 5,
      isYou: false,
    ),
  ],
);

const _placeholderBenchmark = PeerBenchmarkResponse(
  from: '—',
  to: '—',
  cohort: _cohort,
  metrics: [
    BenchmarkMetric(
      key: 'memory_mentions',
      you: 48,
      median: 32,
      p25: 20,
      p75: 50,
      percentileYou: 68,
    ),
    BenchmarkMetric(
      key: 'new_followers',
      you: 12,
      median: 18,
      p25: 8,
      p75: 28,
      percentileYou: 35,
    ),
    BenchmarkMetric(
      key: 'review_count',
      you: 6,
      median: 4,
      p25: 2,
      p75: 7,
      percentileYou: 72,
    ),
  ],
);
