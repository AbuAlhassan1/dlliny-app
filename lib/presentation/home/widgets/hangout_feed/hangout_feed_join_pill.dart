import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed/hangout_join_ui_state.dart';

class HangoutFeedJoinPill extends StatelessWidget {
  final HangoutJoinUiState state;
  final bool loading;
  final VoidCallback onTap;

  const HangoutFeedJoinPill({
    super.key,
    required this.state,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isJoined = state == HangoutJoinUiState.joined;
    return Material(
      color: isJoined
          ? Colors.black.withValues(alpha: 0.55)
          : c.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: (isJoined || loading) ? null : onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    color: c.onPrimary,
                    strokeWidth: 1.5,
                  ),
                )
              else
                Icon(
                  isJoined ? TablerIcons.check : TablerIcons.plus,
                  size: 14,
                  color: isJoined ? Colors.white : c.onPrimary,
                ),
              const SizedBox(width: 5),
              Text(
                (isJoined
                        ? LocaleKeys.hangout_joined
                        : LocaleKeys.hangout_join)
                    .tr(),
                style: TextStyle(
                  color: isJoined ? Colors.white : c.onPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
