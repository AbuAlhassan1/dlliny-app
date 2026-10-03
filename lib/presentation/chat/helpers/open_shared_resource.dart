import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';

Future<void> openSharedResource(
  BuildContext context,
  SharedResourcePreview preview,
) async {
  if (!preview.available) return;

  switch (preview.type) {
    case SharedResourceType.venue:
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VenuePageWrapper(venueId: preview.id),
        ),
      );
      return;

    case SharedResourceType.user:
      final username = _extractUsername(preview.subtitle);
      if (username == null) {
        _showUnavailable(context);
        return;
      }
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProfilePageWrapper(username: username),
        ),
      );
      return;

    case SharedResourceType.post:
    case SharedResourceType.hangout:
    case SharedResourceType.memory:
      _showUnavailable(context);
      return;
  }
}

String? _extractUsername(String? subtitle) {
  if (subtitle == null) return null;
  final trimmed = subtitle.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.startsWith('@')) return trimmed.substring(1);
  return null;
}

void _showUnavailable(BuildContext context) {
  appToast.info(LocaleKeys.chat_shared_resource_cannot_open_here.tr());
}
