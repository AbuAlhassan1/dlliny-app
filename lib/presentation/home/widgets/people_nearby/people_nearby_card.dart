import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/follow_action_response.dart';
import 'package:hangout/domain/dto/response/nearby_suggestion_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/widgets/user_avatar.dart';

const double _avatarSize = 64;

const double _contextSlotHeight = 30;

class PeopleNearbyCard extends StatelessWidget {
  static const double width = 150;
  static const double height = 210;

  final NearbySuggestionResponse person;

  final FollowStatus? followStatus;

  final VoidCallback onFollow;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const PeopleNearbyCard({
    super.key,
    required this.person,
    required this.followStatus,
    required this.onFollow,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        color: c.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: c.border, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 20, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    UserAvatar(
                      avatarUrl: person.avatarUrl,
                      size: _avatarSize,
                    ),
                    const SizedBox(height: 8),
                    _NameRow(
                      displayName: person.displayName,
                      verified: person.verified,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${person.username}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.onSurfaceMuted,
                        fontSize: 11,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      height: _contextSlotHeight,
                      child: _ContextLine(person: person),
                    ),
                    const Spacer(),
                    _FollowButton(status: followStatus, onFollow: onFollow),
                  ],
                ),
              ),
              PositionedDirectional(
                top: 2,
                end: 2,
                child: _DismissButton(onDismiss: onDismiss),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NameRow extends StatelessWidget {
  final String displayName;
  final bool verified;
  const _NameRow({required this.displayName, required this.verified});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              height: 1.2,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
        if (verified) ...[
          const SizedBox(width: 3),
          Icon(
            TablerIcons.rosette_discount_check_filled,
            color: c.success,
            size: 13,
          ),
        ],
      ],
    );
  }
}

class _ContextLine extends StatelessWidget {
  final NearbySuggestionResponse person;
  const _ContextLine({required this.person});

  @override
  Widget build(BuildContext context) {
    if (person.hasSharedVenue) {
      final venue = context.pickBilingual(
        ar: person.sharedVenueNameAr,
        en: person.sharedVenueNameEn,
      );
      return _ContextRow(
        icon: TablerIcons.map_pin,
        text: LocaleKeys.people_nearby_context_shared_venue.tr(
          namedArgs: {'venue': venue},
        ),
      );
    }

    if (person.mutualFollowers > 0) {
      return _ContextRow(
        icon: TablerIcons.users,
        text: LocaleKeys.people_nearby_context_mutual.tr(
          namedArgs: {'count': '${person.mutualFollowers}'},
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _ContextRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContextRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 11, color: c.onSurfaceSecondary),
        ),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 11,
              height: 1.25,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ],
    );
  }
}

class _FollowButton extends StatelessWidget {
  final FollowStatus? status;
  final VoidCallback onFollow;
  const _FollowButton({required this.status, required this.onFollow});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final settled = status != null;

    final (String label, IconData? icon) = switch (status) {
      null => (LocaleKeys.people_nearby_follow_button_follow.tr(), null),
      FollowStatus.pending => (
          LocaleKeys.people_nearby_follow_button_requested.tr(),
          TablerIcons.clock,
        ),
      FollowStatus.accepted => (
          LocaleKeys.people_nearby_follow_button_following.tr(),
          TablerIcons.check,
        ),
    };
    final fg = settled ? c.onSurfaceSecondary : c.onPrimary;

    return SizedBox(
      width: double.infinity,
      height: 30,
      child: Material(
        color: settled ? Colors.transparent : c.primary,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: settled ? c.border : c.primary, width: 1),
        ),
        child: InkWell(
          onTap: settled ? () {} : onFollow,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: fg),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DismissButton extends StatelessWidget {
  final VoidCallback onDismiss;
  const _DismissButton({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Semantics(
      button: true,
      label: LocaleKeys.people_nearby_dismiss.tr(),
      child: InkResponse(
        onTap: onDismiss,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(TablerIcons.x, size: 14, color: c.onSurfaceMuted),
        ),
      ),
    );
  }
}
