import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/media_strip.dart';
import 'package:hangout/presentation/my_profile/widgets/author_picker.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/media_capture_camera.dart';

class StepOneMedia extends StatelessWidget {
  final AuthorIdentity author;
  final ValueChanged<AuthorIdentity> onAuthorChanged;

  final CaptureAspectRatio aspect;
  final bool aspectLocked;
  final ValueChanged<CaptureAspectRatio> onAspectChanged;
  final ValueChanged<CapturedMedia> onCaptured;

  final List<File> media;
  final ScrollController mediaScrollController;
  final VoidCallback onAddMediaTap;
  final ValueChanged<int> onRemoveMedia;

  final List<CaptureAspectRatio>? ratios;

  final VoidCallback? onBack;

  const StepOneMedia({
    super.key,
    required this.author,
    required this.onAuthorChanged,
    required this.aspect,
    required this.aspectLocked,
    required this.onAspectChanged,
    required this.onCaptured,
    required this.media,
    required this.mediaScrollController,
    required this.onAddMediaTap,
    required this.onRemoveMedia,
    this.ratios = hangoutAspectRatios,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 4,
              end: 12,
              top: 8,
              bottom: 4,
            ),
            child: Row(
              children: [
                if (onBack != null) ...[
                  _BackChevron(onTap: onBack!),
                ] else
                  const SizedBox(width: 8),
                Expanded(
                  child: AuthorPickerSwitcher(
                    current: author,
                    onChanged: onAuthorChanged,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: MediaCaptureCamera(
              aspect: aspect,
              aspectLocked: aspectLocked,
              onAspectChanged: onAspectChanged,
              onCaptured: onCaptured,
              ratios: ratios,
            ),
          ),
          const SizedBox(height: 15),
          MediaStrip(
            media: media,
            scrollController: mediaScrollController,
            onAddTap: onAddMediaTap,
            onRemove: onRemoveMedia,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _BackChevron extends StatelessWidget {
  final VoidCallback onTap;
  const _BackChevron({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return IconButton(
      onPressed: onTap,
      icon: Icon(TablerIcons.chevron_right, color: c.onSurface),
      tooltip: LocaleKeys.hangout_create_step_back_tooltip.tr(),
    );
  }
}
