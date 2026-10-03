import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';

const double _leadingSize = 40;

class RecentAttendedCard extends StatelessWidget {
  static const double width = 260;
  static const double height = 60;

  final HangoutResponse hangout;
  const RecentAttendedCard({super.key, required this.hangout});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final daysLeft = _daysLeftToUpload(hangout.scheduledAt);

    return SizedBox(
      width: width,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HangoutDetailsPageWrapper(
                hangoutId: hangout.id,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Leading(),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hangout.venueNameAr,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          height: 1.2,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                      const SizedBox(height: 3),
                      _WindowRow(daysLeft: daysLeft),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  TablerIcons.photo_plus,
                  size: 18,
                  color: c.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Leading extends StatelessWidget {
  const _Leading();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: _leadingSize,
      height: _leadingSize,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: c.border),
      ),
      child: Icon(
        TablerIcons.camera,
        color: c.onSurfaceSecondary,
        size: 20,
      ),
    );
  }
}

class _WindowRow extends StatelessWidget {
  final int daysLeft;
  const _WindowRow({required this.daysLeft});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Icon(
          TablerIcons.clock,
          size: 11,
          color: c.onSurfaceSecondary,
        ),
        const SizedBox(width: 3),
        Expanded(
          child: Text(
            LocaleKeys.home_memories_days_left.plural(daysLeft),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ],
    );
  }
}

int _daysLeftToUpload(String scheduledAtIso) {
  final scheduled = DateTime.tryParse(scheduledAtIso);
  if (scheduled == null) return 0;
  final closesAt = scheduled.add(const Duration(days: 7));
  final delta = closesAt.difference(DateTime.now());
  if (delta.isNegative) return 0;
  return delta.inDays;
}
