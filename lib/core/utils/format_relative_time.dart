import 'package:easy_localization/easy_localization.dart';
import 'package:hangout/generated/locale_keys.g.dart';

String formatRelativeTime(String? iso) {
  if (iso == null) return '';
  final created = DateTime.tryParse(iso);
  if (created == null) return '';

  final delta = DateTime.now().toUtc().difference(created.toUtc());
  if (delta.isNegative) return LocaleKeys.relative_time_now.tr();
  if (delta.inSeconds < 60) return LocaleKeys.relative_time_now.tr();
  if (delta.inMinutes < 60) {
    return LocaleKeys.relative_time_n_minutes_short
        .tr(namedArgs: {'n': '${delta.inMinutes}'});
  }
  if (delta.inHours < 24) {
    return LocaleKeys.relative_time_n_hours_short
        .tr(namedArgs: {'n': '${delta.inHours}'});
  }
  if (delta.inDays == 1) return LocaleKeys.relative_time_yesterday.tr();
  if (delta.inDays < 7) {
    return LocaleKeys.relative_time_n_days.plural(delta.inDays);
  }
  if (delta.inDays < 30) {
    final weeks = (delta.inDays / 7).floor();
    return LocaleKeys.relative_time_n_weeks.plural(weeks);
  }
  if (delta.inDays < 365) {
    final months = (delta.inDays / 30).floor();
    return LocaleKeys.relative_time_n_months.plural(months);
  }
  final years = (delta.inDays / 365).floor();
  return LocaleKeys.relative_time_n_years.plural(years);
}
