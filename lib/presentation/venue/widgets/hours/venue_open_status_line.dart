import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';

String hoursLocaleOf(BuildContext context) =>
    (EasyLocalization.of(context)?.locale ??
            Localizations.maybeLocaleOf(context) ??
            const Locale('ar'))
        .toString();

Color hoursToneColor(BuildContext context, HoursStatusTone tone) {
  final c = context.c;
  return switch (tone) {
    HoursStatusTone.success => c.success,
    HoursStatusTone.warning => c.warning,
    HoursStatusTone.muted => c.onSurfaceSecondary,
    HoursStatusTone.danger => c.danger,
  };
}

class VenueOpenStatusLine extends StatelessWidget {
  final OpenStatusDto? status;
  final double fontSize;

  const VenueOpenStatusLine({
    super.key,
    required this.status,
    this.fontSize = 14,
  });

  @override
  Widget build(BuildContext context) {
    final s = status;
    final tone = s == null ? null : statusTone(s);
    if (s == null || tone == null) return const SizedBox.shrink();
    final c = context.c;
    final color = hoursToneColor(context, tone);
    final label = statusLabel(s, hoursLocaleOf(context));
    final cut = label.indexOf(' · ');
    final head = cut < 0 ? label : label.substring(0, cut);
    final tail = cut < 0 ? '' : label.substring(cut);
    return Row(
      children: [
        ExcludeSemantics(child: VenueOpenStatusDot(status: s, size: 8)),
        const SizedBox(width: 8),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: head,
                  style: TextStyle(color: color, fontWeight: FontWeight.bold),
                ),
                if (tail.isNotEmpty)
                  TextSpan(
                    text: tail,
                    style: TextStyle(
                      color: c.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
            style: TextStyle(
              fontSize: fontSize,
              height: 1.4,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ],
    );
  }
}

class VenueOpenStatusDot extends StatelessWidget {
  final OpenStatusDto? status;
  final double size;

  const VenueOpenStatusDot({super.key, required this.status, this.size = 8});

  @override
  Widget build(BuildContext context) {
    final s = status;
    final tone = s == null ? null : statusTone(s);
    if (s == null || tone == null) return const SizedBox.shrink();
    return Semantics(
      label: statusLabel(s, hoursLocaleOf(context)),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: hoursToneColor(context, tone),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class VenueScopeStatusLine extends StatelessWidget {
  final VenueOpeningHoursDto? openingHours;
  final String? locationId;
  final EdgeInsetsGeometry padding;

  const VenueScopeStatusLine({
    super.key,
    required this.openingHours,
    this.locationId,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final status = openingHours?.scopeFor(locationId).status;
    if (!isStatusVisible(status)) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: VenueOpenStatusLine(status: status),
    );
  }
}
