import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/app_page_gradient.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/challenge_detail_response.dart';
import 'package:hangout/domain/dto/response/challenge_enums.dart';
import 'package:hangout/domain/dto/response/objective_with_progress_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/challenges/controllers/challenge_detail/challenge_detail_bloc.dart';
import 'package:hangout/presentation/challenges/widgets/check_in_button.dart';

class ChallengeDetailPageWrapper extends StatelessWidget {
  final String challengeId;

  const ChallengeDetailPageWrapper({super.key, required this.challengeId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ChallengeDetailBloc>(
      create: (_) =>
          ChallengeDetailBloc()..add(LoadChallengeDetail(challengeId)),
      child: const _ChallengeDetailView(),
    );
  }
}

class _ChallengeDetailView extends StatelessWidget {
  const _ChallengeDetailView();

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
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: appPageGradient(context)),
        child: BlocConsumer<ChallengeDetailBloc, ChallengeDetailState>(
          listenWhen: (_, curr) =>
              curr is ChallengeJoined || curr is ChallengeJoinError,
          listener: (context, state) {
            if (state is ChallengeJoined) {
              appToast.success(LocaleKeys.challenges_join_success_toast.tr());
            } else if (state is ChallengeJoinError) {
              appToast.error(LocaleKeys.challenges_join_failed.tr());
            }
          },
          buildWhen: (_, s) =>
              s is ChallengeDetailInitial ||
              s is ChallengeDetailLoading ||
              s is ChallengeDetailLoaded ||
              s is ChallengeDetailError,
          builder: (context, state) {
            if (state is ChallengeDetailInitial ||
                (state is ChallengeDetailLoading && state.detail == null)) {
              return Center(
                child: CircularProgressIndicator(
                  color: c.onSurface,
                  strokeWidth: 1,
                ),
              );
            }
            if (state is ChallengeDetailError && state.detail == null) {
              return _ErrorState(
                message: LocaleKeys.challenge_detail_load_failed.tr(),
              );
            }
            final detail = state.detail!;
            return _DetailBody(detail: detail);
          },
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final ChallengeDetailResponse detail;
  const _DetailBody({required this.detail});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final title = context.pickBilingual(
      ar: detail.titleAr,
      en: detail.titleEn,
    );
    final description = context.pickBilingual(
      ar: detail.descriptionAr,
      en: detail.descriptionEn,
    );
    final progress = detail.myProgress;

    return RefreshIndicator(
      color: c.onSurface,
      backgroundColor: c.background,
      onRefresh: () async {
        final bloc = context.read<ChallengeDetailBloc>();
        bloc.add(const RefreshChallengeDetail());
        await bloc.stream.firstWhere(
          (s) => s is ChallengeDetailLoaded || s is ChallengeDetailError,
        );
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 90, 16, 32),
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 14,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
          const SizedBox(height: 16),
          _StatusHeader(detail: detail),
          const SizedBox(height: 20),
          Row(
            children: [
              Text(
                LocaleKeys.challenge_detail_objectives_title.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              const Spacer(),
              if (detail.requiredObjectiveCount != null)
                Text(
                  LocaleKeys.challenge_detail_required_objective_hint.tr(
                    namedArgs: {
                      'required': detail.requiredObjectiveCount.toString(),
                      'total': detail.objectives.length.toString(),
                    },
                  ),
                  style: TextStyle(
                    color: c.onSurfaceMuted,
                    fontSize: 12,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final obj in detail.objectives) ...[
            _ObjectiveTile(objective: obj, joined: progress != null),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
          if (progress == null) _JoinCta(),
        ],
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final ChallengeDetailResponse detail;
  const _StatusHeader({required this.detail});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final progress = detail.myProgress;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.divider),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.gift, color: c.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              progress?.status == ChallengeProgressStatus.completed
                  ? LocaleKeys.challenge_detail_points_earned.tr(namedArgs: {
                      'points': progress!.totalPointsEarned.toString(),
                    })
                  : LocaleKeys.challenge_detail_bonus_hint.tr(namedArgs: {
                      'points': detail.bonusPoints.toString(),
                    }),
              style: TextStyle(
                color: c.onSurface,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
          if (progress != null)
            _StatusChip(status: progress.status),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final ChallengeProgressStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (label, color) = switch (status) {
      ChallengeProgressStatus.inProgress => (
          LocaleKeys.challenge_detail_joined_in_progress.tr(),
          c.onSurfaceSecondary,
        ),
      ChallengeProgressStatus.completed => (
          LocaleKeys.challenge_detail_joined_completed.tr(),
          c.success,
        ),
      ChallengeProgressStatus.expired => (
          LocaleKeys.challenge_detail_joined_expired.tr(),
          c.onSurfaceMuted,
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}

class _ObjectiveTile extends StatelessWidget {
  final ObjectiveWithProgressResponse objective;
  final bool joined;

  const _ObjectiveTile({required this.objective, required this.joined});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final title = context.pickBilingual(
      ar: objective.titleAr,
      en: objective.titleEn,
      fallback: _fallbackTitle(objective.type),
    );
    final progressValue = objective.progressValue;
    final target = objective.target;
    final fraction =
        target > 0 && progressValue != null ? (progressValue / target) : 0.0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                objective.completed
                    ? TablerIcons.circle_check_filled
                    : TablerIcons.target,
                color: objective.completed ? c.success : c.onSurfaceSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
              if (joined)
                Text(
                  objective.completed
                      ? LocaleKeys.challenge_detail_objective_done.tr()
                      : LocaleKeys.challenge_detail_objective_progress.tr(
                          namedArgs: {
                            'value': (progressValue ?? 0).toString(),
                            'target': target.toString(),
                          },
                        ),
                  style: TextStyle(
                    color: objective.completed ? c.success : c.onSurfaceSecondary,
                    fontSize: 12,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                )
              else
                Text(
                  '/$target',
                  style: TextStyle(
                    color: c.onSurfaceMuted,
                    fontSize: 12,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
            ],
          ),
          if (joined) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: c.surfaceMuted,
                valueColor: AlwaysStoppedAnimation<Color>(c.primary),
              ),
            ),
          ],
          if (joined &&
              objective.type == ChallengeObjectiveType.visitBranch &&
              !objective.completed) ...[
            const SizedBox(height: 10),
            CheckInButton(config: objective.config),
          ],
        ],
      ),
    );
  }

  String _fallbackTitle(ChallengeObjectiveType t) {
    return switch (t) {
      ChallengeObjectiveType.visitBranch =>
        LocaleKeys.challenge_detail_objective_type_visit_branch.tr(),
      ChallengeObjectiveType.createHangout =>
        LocaleKeys.challenge_detail_objective_type_create_hangout.tr(),
      ChallengeObjectiveType.inviteFriends =>
        LocaleKeys.challenge_detail_objective_type_invite_friends.tr(),
      ChallengeObjectiveType.postCount =>
        LocaleKeys.challenge_detail_objective_type_post_count.tr(),
      ChallengeObjectiveType.memoryCount =>
        LocaleKeys.challenge_detail_objective_type_memory_count.tr(),
      ChallengeObjectiveType.followVenue =>
        LocaleKeys.challenge_detail_objective_type_follow_venue.tr(),
      ChallengeObjectiveType.reviewVenue =>
        LocaleKeys.challenge_detail_objective_type_review_venue.tr(),
    };
  }
}

class _JoinCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<ChallengeDetailBloc, ChallengeDetailState>(
      buildWhen: (_, s) =>
          s is ChallengeDetailLoaded ||
          s is ChallengeJoining ||
          s is ChallengeJoinError,
      builder: (context, state) {
        final busy = state is ChallengeJoining;
        return Material(
          color: c.primary,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: busy
                ? null
                : () => context
                    .read<ChallengeDetailBloc>()
                    .add(const JoinCurrentChallenge()),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: busy
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: c.onPrimary,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        LocaleKeys.challenge_detail_join_cta.tr(),
                        style: TextStyle(
                          color: c.onPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          message,
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
