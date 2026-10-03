import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class HangoutFeedDateTile extends StatelessWidget {
  final DateTime? scheduledAt;
  final bool isPast;

  const HangoutFeedDateTile({
    super.key,
    required this.scheduledAt,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final dt = scheduledAt;
    final locale = context.locale.toString();
    final day = dt == null ? '—' : DateFormat('d', locale).format(dt);
    final month = dt == null ? '' : DateFormat('MMM', locale).format(dt);
    final time = dt == null ? '' : DateFormat('h:mm', locale).format(dt);

    const tileBg = Colors.white;
    const tileFg = Color(0xFF111111);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicWidth(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 3),
              color: isPast ? c.onSurfaceMuted : c.primary,
              child: Text(
                month,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.onPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              child: Column(
                children: [
                  Text(
                    day,
                    style: const TextStyle(
                      color: tileFg,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  if (time.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: TextStyle(
                        color: tileFg.withValues(alpha: 0.65),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
