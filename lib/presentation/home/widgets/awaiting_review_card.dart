import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/domain/dto/response/pending_venue_review_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/controllers/awaiting_review/awaiting_review_bloc.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';

class AwaitingReviewCard extends StatelessWidget {
  const AwaitingReviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AwaitingReviewBloc, AwaitingReviewState>(
      listenWhen: (_, curr) => curr is AwaitingReviewSubmitError,
      listener: (context, state) {
        if (state is AwaitingReviewSubmitError) {
          appToast.error(state.message);
        }
      },
      builder: (context, state) {
        final mode = _modeFrom(state);
        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: Alignment.topCenter,
          child: mode.item == null
              ? const SizedBox(width: double.infinity)
              : _Pill(mode: mode),
        );
      },
    );
  }

  _Mode _modeFrom(AwaitingReviewState s) {
    return switch (s) {
      AwaitingReviewLoaded(:final item) => _Mode(
        item: item,
        picked: 0,
        kind: _Kind.picking,
      ),
      AwaitingReviewConfirming(:final item, :final selectedRating) => _Mode(
        item: item,
        picked: selectedRating,
        kind: _Kind.confirming,
      ),
      AwaitingReviewSubmitting(:final item, :final selectedRating) => _Mode(
        item: item,
        picked: selectedRating,
        kind: _Kind.submitting,
      ),
      AwaitingReviewSubmitError(:final item) => _Mode(
        item: item,
        picked: 0,
        kind: _Kind.picking,
      ),
      _ => const _Mode(item: null, picked: 0, kind: _Kind.picking),
    };
  }
}

enum _Kind { picking, confirming, submitting }

class _Mode {
  final PendingVenueReviewResponse? item;
  final int picked;
  final _Kind kind;
  const _Mode({required this.item, required this.picked, required this.kind});
}

class _Pill extends StatelessWidget {
  final _Mode mode;
  const _Pill({required this.mode});

  PendingVenueReviewResponse get _item => mode.item!;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Logo(url: _item.venueLogoUrl, venueId: _item.venueId),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.pickBilingual(
                          ar: _item.venueNameAr,
                          en: _item.venueNameEn,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      _Subtitle(mode: mode),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Stars(mode: mode),
                        if (mode.picked > 0) ...[
                          const SizedBox(width: 6),
                          _ConfirmButton(mode: mode),
                        ],
                      ],
                    ),
                    if (mode.picked == 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        LocaleKeys.home_awaiting_review_rate_at_venue.tr(
                          namedArgs: {
                            'venue': context.pickBilingual(
                              ar: _item.venueNameAr,
                              en: _item.venueNameEn,
                            ),
                          },
                        ),
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  final String? url;
  final String venueId;
  const _Logo({required this.url, required this.venueId});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VenuePageWrapper(venueId: venueId)),
      ),
      child: Container(
        width: 50,
        height: 50,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: c.onSurface, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: (url != null && url!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: url!,
                  fit: BoxFit.cover,
                  memCacheWidth: 150,
                  errorWidget: (_, _, _) => Icon(
                    TablerIcons.building_store,
                    color: c.onSurfaceSecondary,
                    size: 18,
                  ),
                )
              : Icon(
                  TablerIcons.building_store,
                  color: c.onSurfaceSecondary,
                  size: 18,
                ),
        ),
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final _Mode mode;
  const _Subtitle({required this.mode});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    switch (mode.kind) {
      case _Kind.confirming:
        return _pickingSubtitle(context);
      case _Kind.submitting:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: c.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              LocaleKeys.home_awaiting_review_submitting.tr(),
              style: TextStyle(
                color: c.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      case _Kind.picking:
        return _pickingSubtitle(context);
    }
  }

  Widget _pickingSubtitle(BuildContext context) {
    final c = context.c;
    final item = mode.item!;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _relativeDate(item.scheduledAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 11),
          ),
        ),
        if (item.attendees.isNotEmpty) ...[
          Text(
            ' · ',
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 11),
          ),
          _TinyFacepile(attendees: item.attendees),
          const SizedBox(width: 4),
          Text(
            '${item.attendees.length}',
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _TinyFacepile extends StatelessWidget {
  final List<HangoutAttendee> attendees;
  const _TinyFacepile({required this.attendees});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    const maxVisible = 3;
    const size = 14.0;
    const overlap = 5.0;
    final visible = attendees.take(maxVisible).toList();
    final stackWidth = size + (visible.length - 1) * (size - overlap);

    return SizedBox(
      height: size,
      width: stackWidth,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (int i = 0; i < visible.length; i++)
            PositionedDirectional(
              start: i * (size - overlap),
              child: Container(
                width: size,
                height: size,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.surfaceElevated,
                  border: Border.all(color: c.surfaceMuted, width: 1.5),
                ),
                child:
                    (visible[i].avatarUrl != null &&
                        visible[i].avatarUrl!.isNotEmpty)
                    ? CachedNetworkImage(
                        imageUrl: visible[i].avatarUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        errorWidget: (_, _, _) => Icon(
                          Icons.person,
                          color: c.onSurfaceSecondary,
                          size: 8,
                        ),
                      )
                    : Icon(Icons.person, color: c.onSurfaceSecondary, size: 8),
              ),
            ),
        ],
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final _Mode mode;
  const _Stars({required this.mode});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final busy = mode.kind == _Kind.submitting;
    return Opacity(
      opacity: busy ? 0.55 : 1.0,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final value = i + 1;
          final filled = value <= mode.picked;
          return InkResponse(
            onTap: busy ? null : () => _onTap(context, value),
            radius: 16,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                filled ? TablerIcons.star_filled : TablerIcons.star,
                color: filled ? const Color(0xFFFFB000) : c.onSurfaceSecondary,
                size: 22,
              ),
            ),
          );
        }),
      ),
    );
  }

  void _onTap(BuildContext context, int value) {
    HapticFeedback.heavyImpact();
    if (mode.kind == _Kind.submitting) return;
    context.read<AwaitingReviewBloc>().add(SelectRating(value));
  }
}

class _ConfirmButton extends StatelessWidget {
  final _Mode mode;
  const _ConfirmButton({required this.mode});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final busy = mode.kind == _Kind.submitting;
    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: busy
            ? null
            : () {
                HapticFeedback.mediumImpact();
                context.read<AwaitingReviewBloc>().add(ConfirmRating());
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: busy
              ? SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: c.onPrimary,
                  ),
                )
              : Text(
                  LocaleKeys.home_awaiting_review_confirm_button.tr(),
                  style: TextStyle(
                    color: c.onPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

String _relativeDate(String iso) {
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return iso;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(dt.year, dt.month, dt.day);
  final days = today.difference(that).inDays;
  if (days == 0) return LocaleKeys.home_relative_date_today.tr();
  if (days == 1) return LocaleKeys.home_relative_date_yesterday.tr();
  final locale = Intl.getCurrentLocale();
  if (days < 7) {
    return LocaleKeys.home_relative_date_n_days_ago.tr(
      namedArgs: {'n': '$days'},
    );
  }
  if (days < 14) {
    return LocaleKeys.home_relative_date_last_weekday.tr(
      namedArgs: {'weekday': DateFormat('EEEE', locale).format(dt)},
    );
  }
  return DateFormat('d MMM', locale).format(dt);
}
