import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/core/utils/format_relative_time.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/create_review_request.dart';
import 'package:hangout/domain/dto/response/review_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_hours/venue_hours_bloc.dart';
import 'package:hangout/presentation/venue/widgets/venue_about_section.dart';
import 'package:hangout/presentation/venue/widgets/venue_branches_section.dart';

class VenueReviewsTab extends StatefulWidget {
  final String venueId;
  const VenueReviewsTab({super.key, required this.venueId});

  @override
  State<VenueReviewsTab> createState() => _VenueReviewsTabState();
}

class _VenueReviewsTabState extends State<VenueReviewsTab> {
  List<ReviewResponse> _reviews = [];

  ReviewResponse? _myReview;

  bool _loading = true;
  bool _failed = false;

  final GlobalKey _branchesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    final api = serviceLocator.get<ApiService>();
    final myReviewFuture = _fetchMyReview(api);
    final listFuture = _fetchList(api);
    final myReview = await myReviewFuture;
    final list = await listFuture;
    if (!mounted) return;
    setState(() {
      _myReview = myReview;
      if (list != null) {
        _reviews = list;
      } else {
        _failed = true;
      }
      _loading = false;
    });
  }

  Future<List<ReviewResponse>?> _fetchList(ApiService api) async {
    try {
      final res = await api.getVenueReviews(widget.venueId);
      if (!res.success || res.data == null) return null;
      return res.data;
    } catch (_) {
      return null;
    }
  }

  Future<ReviewResponse?> _fetchMyReview(ApiService api) async {
    try {
      final res = await api.getMyReviewForVenue(widget.venueId);
      if (!res.success || res.data == null) return null;
      return res.data;
    } on DioException catch (_) {
      return null;
    } catch (_) {
      return null;
    }
  }

  void _onReviewCreated(ReviewResponse created) {
    if (!mounted) return;
    setState(() {
      _myReview = created;
      _reviews = [created, ..._reviews.where((r) => r.id != created.id)];
    });
    context.read<VenueBloc>().add(GetVenueDetails(widget.venueId));
    _load();
  }

  void _scrollToBranches() {
    final target = _branchesKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasMyReview = _myReview != null;
    final others = hasMyReview
        ? _reviews.where((r) => r.id != _myReview!.id).toList()
        : _reviews;
    return RefreshIndicator(
      onRefresh: () async {
        maybeVenueHoursBloc(context)?.add(const VenueHoursRefreshRequested());
        context.read<VenueBloc>().add(GetVenueDetails(widget.venueId));
        await _load();
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          VenueAboutSection(onShowBranches: _scrollToBranches),
          VenueBranchesSection(key: _branchesKey),
          if (hasMyReview)
            _MyReviewTile(review: _myReview!)
          else
            _RatingCard(
              venueId: widget.venueId,
              onCreated: _onReviewCreated,
            ),
          const SizedBox(height: 20),
          _ReviewsHeader(count: others.length),
          const SizedBox(height: 8),
          if (_loading && others.isEmpty)
            const _Loading()
          else if (_failed && others.isEmpty)
            _Error(onRetry: _load)
          else if (others.isEmpty)
            const _Empty()
          else
            for (final r in others) ...[
              _ReviewTile(review: r),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _MyReviewTile extends StatelessWidget {
  final ReviewResponse review;
  const _MyReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasBody = review.body != null && review.body!.trim().isNotEmpty;
    final hasReply =
        review.businessReply != null && review.businessReply!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: c.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  LocaleKeys.venue_reviews_your_review_label.tr(),
                  style: TextStyle(
                    color: c.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < review.ratingOverall;
                  return Icon(
                    filled ? TablerIcons.star_filled : TablerIcons.star,
                    color: filled
                        ? const Color(0xFFFFB000)
                        : c.onSurfaceDisabled,
                    size: 11,
                  );
                }),
              ),
              const Spacer(),
              Text(
                formatRelativeTime(review.createdAt),
                style: TextStyle(color: c.onSurfaceSecondary, fontSize: 10),
              ),
            ],
          ),
          if (hasBody) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 2),
              child: Text(
                review.body!.trim(),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (hasReply) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsetsDirectional.only(end: 8),
                  decoration: BoxDecoration(
                    color: c.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        LocaleKeys.venue_reviews_venue_reply_label.tr(),
                        style: TextStyle(
                          color: c.onSurfaceSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        review.businessReply!.trim(),
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RatingCard extends StatefulWidget {
  final String venueId;

  final ValueChanged<ReviewResponse> onCreated;

  const _RatingCard({required this.venueId, required this.onCreated});

  @override
  State<_RatingCard> createState() => _RatingCardState();
}

class _RatingCardState extends State<_RatingCard> {
  int _picked = 0;
  final TextEditingController _bodyController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_picked == 0 || _submitting) return;
    setState(() => _submitting = true);

    ReviewResponse? created;
    String? errorMessage;
    try {
      final body = _bodyController.text.trim();
      final res = await serviceLocator.get<ApiService>().createReview(
            CreateReviewRequest(
              venueId: widget.venueId,
              ratingOverall: _picked,
              body: body.isEmpty ? null : body,
            ),
          );
      if (!mounted) return;
      if (!res.success || res.data == null) {
        errorMessage = res.error ?? LocaleKeys.venue_reviews_error_submit_fallback.tr();
      } else {
        created = res.data;
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        errorMessage = LocaleKeys.venue_reviews_error_already_reviewed.tr();
      } else {
        errorMessage = LocaleKeys.venue_reviews_error_submit_fallback.tr();
      }
    } catch (_) {
      errorMessage = LocaleKeys.venue_reviews_error_submit_fallback.tr();
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (errorMessage != null) {
      appToast.error(errorMessage);
      return;
    }
    if (created == null) return;
    _bodyController.clear();
    setState(() => _picked = 0);
    appToast.success(LocaleKeys.venue_reviews_success_submitted.tr());
    widget.onCreated(created);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<VenueBloc, VenueState>(
      builder: (context, state) {
        final venue = state is GetVenueDetailsLoaded ? state.venue : null;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    TablerIcons.star_filled,
                    color: const Color(0xFFFFB000),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    venue == null ? '—' : venue.avgRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    venue == null ? '' : '· ${venue.totalRatings}',
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StarRow(
                      picked: _picked,
                      enabled: !_submitting,
                      onPick: (n) => setState(() => _picked = n),
                    ),
                  ),
                  _SendButton(
                    enabled: _picked > 0 && !_submitting,
                    busy: _submitting,
                    onTap: _submit,
                  ),
                ],
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                alignment: Alignment.topCenter,
                child: _picked == 0
                    ? const SizedBox(width: double.infinity)
                    : Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: TextField(
                          controller: _bodyController,
                          maxLines: 3,
                          minLines: 1,
                          enabled: !_submitting,
                          style: TextStyle(color: c.onSurface, fontSize: 13),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: LocaleKeys.venue_reviews_comment_hint_optional.tr(),
                            hintStyle: TextStyle(
                              color: c.onSurfaceMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 6,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool enabled;
  final bool busy;
  final VoidCallback onTap;

  const _SendButton({
    required this.enabled,
    required this.busy,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = enabled ? c.primary : c.onSurfaceDisabled;
    return TextButton(
      onPressed: enabled ? onTap : null,
      style: TextButton.styleFrom(
        foregroundColor: c.primary,
        disabledForegroundColor: c.onSurfaceDisabled,
        minimumSize: Size.zero,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: busy
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: c.primary,
                strokeWidth: 1.5,
              ),
            )
          : Text(
              LocaleKeys.venue_reviews_submit_button.tr(),
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final int picked;
  final bool enabled;
  final ValueChanged<int> onPick;
  const _StarRow({
    required this.picked,
    required this.enabled,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final value = i + 1;
        final filled = value <= picked;
        return InkResponse(
          onTap: enabled ? () => onPick(value) : null,
          radius: 18,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            child: Icon(
              filled ? TablerIcons.star_filled : TablerIcons.star,
              color: filled
                  ? const Color(0xFFFFB000)
                  : c.onSurfaceDisabled,
              size: 22,
            ),
          ),
        );
      }),
    );
  }
}

class _ReviewsHeader extends StatelessWidget {
  final int? count;
  const _ReviewsHeader({required this.count});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        children: [
          Icon(TablerIcons.messages, color: c.onSurface, size: 16),
          const SizedBox(width: 6),
          Text(
            LocaleKeys.venue_reviews_section_title.tr(),
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Text(
              '· $count',
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final ReviewResponse review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasBody = review.body != null && review.body!.trim().isNotEmpty;
    final hasReply =
        review.businessReply != null && review.businessReply!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surfaceMuted,
                ),
                child: review.userAvatarUrl != null &&
                        review.userAvatarUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: review.userAvatarUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => Icon(
                          TablerIcons.user,
                          color: c.onSurfaceSecondary,
                          size: 14,
                        ),
                      )
                    : Icon(
                        TablerIcons.user,
                        color: c.onSurfaceSecondary,
                        size: 14,
                      ),
              ),
              const SizedBox(width: 8),
              Text(
                review.username,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < review.ratingOverall;
                  return Icon(
                    filled ? TablerIcons.star_filled : TablerIcons.star,
                    color: filled
                        ? const Color(0xFFFFB000)
                        : c.onSurfaceDisabled,
                    size: 11,
                  );
                }),
              ),
              const Spacer(),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      formatRelativeTime(review.createdAt),
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasBody) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 32),
              child: Text(
                review.body!.trim(),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (hasReply) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 32),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 2,
                    height: 28,
                    margin: const EdgeInsetsDirectional.only(end: 8),
                    decoration: BoxDecoration(
                      color: c.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.venue_reviews_venue_reply_label.tr(),
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          review.businessReply!.trim(),
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Center(
        child: CircularProgressIndicator(
          color: c.onSurface,
          strokeWidth: 1.5,
        ),
      ),
    );
  }
}

class _Error extends StatelessWidget {
  final Future<void> Function() onRetry;
  const _Error({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Icon(TablerIcons.cloud_off, color: c.onSurfaceDisabled, size: 28),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.venue_reviews_error_load.tr(),
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => onRetry(),
            child: Text(
              LocaleKeys.venue_reviews_button_retry.tr(),
              style: TextStyle(color: c.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        children: [
          Icon(TablerIcons.message_off, color: c.onSurfaceDisabled, size: 28),
          const SizedBox(height: 8),
          Text(
            LocaleKeys.venue_reviews_empty.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
