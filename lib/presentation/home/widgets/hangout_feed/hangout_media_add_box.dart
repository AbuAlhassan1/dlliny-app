import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class HangoutMediaAddBox extends StatefulWidget {
  final VoidCallback onAddMedia;
  final double maxWidth;

  const HangoutMediaAddBox({
    super.key,
    required this.onAddMedia,
    this.maxWidth = 140,
  });

  @override
  State<HangoutMediaAddBox> createState() => _HangoutMediaAddBoxState();
}

class _HangoutMediaAddBoxState extends State<HangoutMediaAddBox> {

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: InkWell(
          onTap: widget.onAddMedia,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  TablerIcons.photo_plus,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.8),
                ),

                const SizedBox(width: 5),

                Text(
                  LocaleKeys.hangout_actions_add_media_box_cta.tr(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                )
              ]
            ),
          ),
        ),
      ),
    );
  }
}
