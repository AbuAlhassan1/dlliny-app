import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/challenge_enums.dart';
import 'package:hangout/domain/dto/response/challenge_list_item_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/challenges/controllers/challenges_list/challenges_list_bloc.dart';
import 'package:hangout/presentation/challenges/controllers/my_joined_challenges/my_joined_challenges_bloc.dart';
import 'package:hangout/presentation/challenges/pages/challenge_detail_page_wrapper.dart';
import 'package:hangout/presentation/challenges/widgets/challenge_card.dart';

class ChallengesPageWrapper extends StatelessWidget {
  const ChallengesPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ChallengesListBloc>(
          create: (_) => ChallengesListBloc()
            ..add(const LoadChallenges())
            ..add(const LoadChallenges(cadence: ChallengeCadence.daily))
            ..add(const LoadChallenges(cadence: ChallengeCadence.weekly)),
        ),
        BlocProvider<MyJoinedChallengesBloc>(
          create: (_) =>
              MyJoinedChallengesBloc()..add(const LoadMyJoinedChallenges()),
        ),
      ],
      child: const _ChallengesView(),
    );
  }
}

class _ChallengesView extends StatelessWidget {
  const _ChallengesView();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          elevation: 0,
          leading: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(TablerIcons.chevron_right, color: c.onSurface),
          ),
          title: Text(
            LocaleKeys.challenges_page_title.tr(),
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.bold,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: c.onSurface,
            labelColor: c.onSurface,
            unselectedLabelColor: c.onSurfaceSecondary,
            dividerHeight: 0,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: 'IBMPlexSansArabic',
            ),
            unselectedLabelStyle: const TextStyle(
              fontFamily: 'IBMPlexSansArabic',
            ),
            tabs: [
              Tab(text: LocaleKeys.challenges_tab_for_you.tr()),
              Tab(text: LocaleKeys.challenges_tab_daily.tr()),
              Tab(text: LocaleKeys.challenges_tab_weekly.tr()),
              Tab(text: LocaleKeys.challenges_tab_mine.tr()),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DiscoveryTab(
              cadence: null,
              emptyKey: 'challenges_empty_for_you',
            ),
            _DiscoveryTab(
              cadence: ChallengeCadence.daily,
              emptyKey: 'challenges_empty_daily',
            ),
            _DiscoveryTab(
              cadence: ChallengeCadence.weekly,
              emptyKey: 'challenges_empty_weekly',
            ),
            _MineTab(),
          ],
        ),
      ),
    );
  }
}

class _DiscoveryTab extends StatelessWidget {
  final ChallengeCadence? cadence;
  final String emptyKey;
  const _DiscoveryTab({required this.cadence, required this.emptyKey});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<ChallengesListBloc, ChallengesListState>(
      builder: (context, state) {
        final items = state.byCadence[cadence] ?? const [];
        final isLoadingThisTab =
            state is ChallengesListLoading && state.cadence == cadence;
        final isErrorThisTab =
            state is ChallengesListError && state.cadence == cadence;

        if (items.isEmpty && isLoadingThisTab) {
          return Center(
            child: CircularProgressIndicator(color: c.onSurface, strokeWidth: 1),
          );
        }
        if (items.isEmpty && isErrorThisTab) {
          return _ErrorMessage(
            message: LocaleKeys.challenges_load_failed.tr(),
            onRetry: () => context
                .read<ChallengesListBloc>()
                .add(LoadChallenges(cadence: cadence)),
          );
        }
        if (items.isEmpty) {
          return _EmptyMessage(text: _emptyText());
        }

        return RefreshIndicator(
          color: c.onSurface,
          backgroundColor: c.background,
          onRefresh: () async {
            final bloc = context.read<ChallengesListBloc>();
            bloc.add(LoadChallenges(cadence: cadence));
            await bloc.stream.firstWhere(
              (s) => (s is ChallengesListLoaded && s.cadence == cadence) ||
                  (s is ChallengesListError && s.cadence == cadence),
            );
          },
          child: _ChallengeGrid(items: items),
        );
      },
    );
  }

  String _emptyText() {
    return switch (emptyKey) {
      'challenges_empty_daily' => LocaleKeys.challenges_empty_daily.tr(),
      'challenges_empty_weekly' => LocaleKeys.challenges_empty_weekly.tr(),
      _ => LocaleKeys.challenges_empty_for_you.tr(),
    };
  }
}

class _MineTab extends StatelessWidget {
  const _MineTab();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MyJoinedChallengesBloc, MyJoinedChallengesState>(
      builder: (context, state) {
        final items = state.items;
        if (items.isEmpty && state is MyJoinedChallengesLoading) {
          return Center(
            child: CircularProgressIndicator(color: c.onSurface, strokeWidth: 1),
          );
        }
        if (items.isEmpty && state is MyJoinedChallengesError) {
          return _ErrorMessage(
            message: LocaleKeys.challenges_load_failed.tr(),
            onRetry: () => context
                .read<MyJoinedChallengesBloc>()
                .add(const LoadMyJoinedChallenges()),
          );
        }
        if (items.isEmpty) {
          return _EmptyMessage(
            text: LocaleKeys.challenges_empty_mine_in_progress.tr(),
          );
        }
        final inProgress = <ChallengeListItemResponse>[];
        final completed = <ChallengeListItemResponse>[];
        final expired = <ChallengeListItemResponse>[];
        for (final it in items) {
          final s = it.myProgress?.status;
          if (s == ChallengeProgressStatus.completed) {
            completed.add(it);
          } else if (s == ChallengeProgressStatus.expired) {
            expired.add(it);
          } else {
            inProgress.add(it);
          }
        }

        return RefreshIndicator(
          color: c.onSurface,
          backgroundColor: c.background,
          onRefresh: () async {
            final bloc = context.read<MyJoinedChallengesBloc>();
            bloc.add(const LoadMyJoinedChallenges());
            await bloc.stream.firstWhere(
              (s) => s is MyJoinedChallengesLoaded ||
                  s is MyJoinedChallengesError,
            );
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            children: [
              if (inProgress.isNotEmpty) ...[
                _SectionHeading(
                  label: LocaleKeys.challenges_section_in_progress.tr(),
                ),
                _ChallengeGrid(items: inProgress),
              ],
              if (completed.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionHeading(
                  label: LocaleKeys.challenges_section_completed.tr(),
                ),
                _ChallengeGrid(items: completed),
              ],
              if (expired.isNotEmpty) ...[
                const SizedBox(height: 16),
                _SectionHeading(
                  label: LocaleKeys.challenges_section_expired.tr(),
                ),
                _ChallengeGrid(items: expired, dimmed: true),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _ChallengeGrid extends StatelessWidget {
  final List<ChallengeListItemResponse> items;
  final bool dimmed;
  const _ChallengeGrid({required this.items, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 3/2,
      ),
      itemBuilder: (context, i) {
        final item = items[i];
        final card = ChallengeCard(
          item: item,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) =>
                  ChallengeDetailPageWrapper(challengeId: item.id),
            ),
          ),
        );
        if (!dimmed) return card;
        return Opacity(opacity: 0.55, child: card);
      },
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String label;
  const _SectionHeading({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(6, 12, 6, 4),
      child: Text(
        label,
        style: TextStyle(
          color: c.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.bold,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String text;
  const _EmptyMessage({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorMessage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Retry',
                style: TextStyle(
                  color: c.primary,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
