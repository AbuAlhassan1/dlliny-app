import 'dart:ui';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/map/controller/map_bloc.dart';

class ShakeChip extends StatelessWidget {
  final VoidCallback onTap;
  const ShakeChip({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (_, s) =>
          s is ShakeLoading || s is ShakeLoaded || s is ShakeError,
      builder: (context, state) {
        final loading = state is ShakeLoading;
        return ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Material(
            color: c.background.withValues(alpha: 0.2),
            shape: StadiumBorder(
              side: BorderSide(color: c.border, width: 1),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: InkWell(
                onTap: loading ? null : onTap,
                customBorder: const StadiumBorder(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.6,
                            color: c.onSurface,
                          ),
                        )
                      else
                        Icon(
                          TablerIcons.dice_5,
                          size: 18,
                          color: c.onSurface,
                        ),
                      const SizedBox(width: 8),
                      Text(
                        (loading
                                ? LocaleKeys.map_shake_chip_loading
                                : LocaleKeys.map_shake_chip_idle)
                            .tr(),
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: "IBMPlexSansArabic",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
