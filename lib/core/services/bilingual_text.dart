import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

extension BilingualPick on BuildContext {
  String pickBilingual({
    String? ar,
    String? en,
    String fallback = '',
  }) {
    final isAr = locale.languageCode == 'ar';
    final preferred = isAr ? ar : en;
    final secondary = isAr ? en : ar;
    if (preferred != null && preferred.isNotEmpty) return preferred;
    if (secondary != null && secondary.isNotEmpty) return secondary;
    return fallback;
  }
}
