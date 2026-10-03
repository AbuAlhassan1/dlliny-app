import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/router/routes.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';
import 'package:share_plus/share_plus.dart';

const String kDeepLinkHost = 'dlliny.com';

String buildHangoutInviteUrl(String inviteToken) =>
    'https://$kDeepLinkHost/invite/$inviteToken';

Future<void> shareHangoutInvite(
  String inviteToken, {
  String? message,
  Rect? sharePositionOrigin,
}) async {
  final url = buildHangoutInviteUrl(inviteToken);
  final text = (message != null && message.isNotEmpty) ? '$message\n$url' : url;
  await Share.share(text, sharePositionOrigin: sharePositionOrigin);
}

NavigatorState? get _navigator => appNavigatorKey.currentState;

Future<bool> handleDeepLink(Uri uri) async {
  if (uri.host != kDeepLinkHost) return false;

  final segments = uri.pathSegments;
  if (segments.length >= 2 && segments.first == 'invite') {
    final token = segments[1];
    if (token.isNotEmpty) {
      await _openHangoutByInvite(token);
      return true;
    }
  }
  return false;
}

Future<void> _openHangoutByInvite(String token) async {
  final api = serviceLocator.get<ApiService>();
  try {
    final res = await api.getHangoutByInviteLink(token);
    if (!res.success || res.data == null) {
      log('deep link: invite resolve failed: ${res.error}');
      return;
    }
    final nav = _navigator;
    if (nav == null) return;
    nav.push(
      MaterialPageRoute(
        builder: (_) => HangoutDetailsPageWrapper(hangoutId: res.data!.id),
      ),
    );
  } catch (e) {
    log('deep link: invite exception: $e');
  }
}
