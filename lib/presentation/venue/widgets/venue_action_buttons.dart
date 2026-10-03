import 'dart:developer';
import 'dart:ui' show ImageFilter;
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/helpers/open_direct_conversation.dart';
import 'package:hangout/presentation/chat/helpers/open_share_sheet.dart';
import 'package:hangout/presentation/venue/manage_venue_page_wrapper.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:hangout/presentation/venue/utils/open_directions.dart';
import 'package:hangout/presentation/venue/widgets/venue_directions_sheet.dart';

class _Glass extends StatelessWidget {
  final Widget child;
  const _Glass({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: child,
      ),
    );
  }
}

class VenueActionButtons extends StatelessWidget {
  final VenueResponse venue;
  const VenueActionButtons({super.key, required this.venue});

  @override
  Widget build(BuildContext context) {
    log(venue.viewerRole.toString());
    final canEdit = userHasOnVenue(context, VenuePerm.update, venue.id);
    return Container(
      color: Colors.transparent,
      height: 35,
      child: Row(
        children: [
          if (canEdit) ...[
            Expanded(child: _EditButton(venue: venue)),
            const SizedBox(width: 8),
          ],
          _FollowButton(venue: venue),
          const SizedBox(width: 8),
          _MessageButton(venue: venue),
          const SizedBox(width: 8),
          Flexible(child: _ShareButton(venue: venue)),
          if (venue.locations.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(child: _DirectionsButton(venue: venue)),
          ],
        ],
      ),
    );
  }
}

class _DirectionsButton extends StatelessWidget {
  final VenueResponse venue;
  const _DirectionsButton({required this.venue});

  void _onPressed(BuildContext context) {
    final locations = venue.locations;
    if (locations.length > 1) {
      showVenueDirectionsSheet(context, locations);
    } else {
      final loc = locations.first;
      openDirections(latitude: loc.latitude, longitude: loc.longitude);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return _Glass(
      child: OutlinedButton.icon(
        onPressed: () => _onPressed(context),
        icon: const Icon(TablerIcons.route, size: 18),
        label: Text(
          LocaleKeys.venue_actions_directions.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontFamily: "IBMPlexSansArabic"),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.onMediaSurface,
          backgroundColor: c.mediaSurface.withValues(alpha: 0.22),
          side: BorderSide(
            color: c.onMediaSurface.withValues(alpha: 0.5),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  final VenueResponse venue;
  const _ShareButton({required this.venue});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return _Glass(
      child: OutlinedButton.icon(
        onPressed: () => openShareSheet(
          context,
          resourceType: SharedResourceType.venue,
          resourceId: venue.id,
          headlineLabel: LocaleKeys.venue_actions_share_headline.tr(),
        ),
        icon: const Icon(TablerIcons.send, size: 18),
        label: Text(
          LocaleKeys.common_share.tr(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontFamily: "IBMPlexSansArabic"),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.onMediaSurface,
          backgroundColor: c.mediaSurface.withValues(alpha: 0.22),
          side: BorderSide(
            color: c.onMediaSurface.withValues(alpha: 0.5),
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  final VenueResponse venue;
  const _MessageButton({required this.venue});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: 35,
      child: _Glass(
        child: OutlinedButton(
          onPressed: () => openDirectConversation(
            context,
            peerType: ChatMemberType.venue,
            peerId: venue.id,
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.onMediaSurface,
            backgroundColor: c.mediaSurface.withValues(alpha: 0.22),
            side: BorderSide(
              color: c.onMediaSurface.withValues(alpha: 0.5),
              width: 1,
            ),
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Center(child: Icon(TablerIcons.message_circle, size: 18)),
        ),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VenueResponse venue;
  const _EditButton({required this.venue});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return _Glass(
      child: OutlinedButton.icon(
        onPressed: () => ManageVenuePageWrapper.push(context, venue),
        icon: const Icon(TablerIcons.settings, size: 18),
        label: Text(
          LocaleKeys.venue_actions_manage.tr(),
          style: const TextStyle(
              fontWeight: FontWeight.bold, fontFamily: "IBMPlexSansArabic"),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: c.onMediaSurface,
          backgroundColor: c.mediaSurface.withValues(alpha: 0.22),
          side: BorderSide(
            color: c.onMediaSurface.withValues(alpha: 0.5),
            width: 1,
          ),
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _FollowButton extends StatefulWidget {
  final VenueResponse venue;
  const _FollowButton({required this.venue});

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  final ApiService _api = serviceLocator.get<ApiService>();
  late bool _isFollowing = widget.venue.isFollowing;
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !wasFollowing;
      _busy = true;
    });

    try {
      if (wasFollowing) {
        await _api.unfollowVenue(widget.venue.id);
      } else {
        await _api.followVenue(widget.venue.id);
      }
    } on DioException catch (e) {
      log('follow toggle failed: ${e.message}');
      if (mounted) {
        setState(() => _isFollowing = wasFollowing);
        appToast.error(LocaleKeys.venue_actions_follow_update_failed
            .tr(namedArgs: {'message': e.message ?? ''}));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final following = _isFollowing;
    return SizedBox(
      width: 35,
      child: _Glass(
        child: ElevatedButton(
          onPressed: _busy ? null : _toggle,
          style: ElevatedButton.styleFrom(
            backgroundColor: c.mediaSurface.withValues(alpha: 0.22),
            side: BorderSide(
              color: c.onMediaSurface.withValues(alpha: 0.5),
              width: 1,
            ),
            padding: EdgeInsets.zero,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
          child: Center(
            child: _busy
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.onMediaSurface,
                    ),
                  )
                : Icon(
                    following ? TablerIcons.heart_filled : TablerIcons.heart,
                    size: 18,
                    color: following ? const Color(0xFFE0245E) : c.onMediaSurface,
                  ),
          ),
        ),
      ),
    );
  }
}
