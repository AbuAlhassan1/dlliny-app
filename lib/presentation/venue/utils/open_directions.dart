import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openDirections({
  required double latitude,
  required double longitude,
}) async {
  final coords = '$latitude,$longitude';

  final candidates = <Uri>[
    if (defaultTargetPlatform == TargetPlatform.iOS)
      Uri.parse('https://maps.apple.com/?daddr=$coords')
    else
      Uri.parse('geo:$coords?q=$coords'),
    Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$coords'),
  ];

  for (final uri in candidates) {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
    }
  }

  appToast.error(LocaleKeys.common_operation_failed.tr());
}
