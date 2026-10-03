import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/media_strip.dart';
import 'package:hangout/presentation/my_profile/widgets/author_picker.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/aspect_ratio_picker.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/media_capture_camera.dart';

class FullscreenStepOne extends StatelessWidget {
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

  final VoidCallback onNext;

  final VoidCallback? onBack;

  const FullscreenStepOne({
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
    required this.onNext,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: c.mediaSurface,
        body: Stack(
          children: [
            Positioned.fill(
              child: MediaCaptureCamera(
                aspect: aspect,
                aspectLocked: aspectLocked,
                onAspectChanged: onAspectChanged,
                onCaptured: onCaptured,
                fullscreen: true,
              ),
            ),

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [c.scrim, Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          if (onBack != null) ...[
                            IconButton(
                              onPressed: onBack,
                              icon: Icon(
                                TablerIcons.chevron_right,
                                color: c.onMediaSurface,
                                size: 24,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor:
                                    c.onMediaSurface.withValues(alpha: 0.12),
                                shape: const CircleBorder(),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: AuthorPickerSwitcher(
                              current: author,
                              onChanged: onAuthorChanged,
                            ),
                          ),
                          IconButton(
                            onPressed: onNext,
                            icon: Icon(
                              TablerIcons.chevron_left,
                              color: c.onMediaSurface,
                              size: 28,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor:
                                  c.onMediaSurface.withValues(alpha: 0.12),
                              shape: const CircleBorder(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      AspectRatioPicker(
                        current: aspect,
                        locked: aspectLocked,
                        onChanged: onAspectChanged,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).padding.bottom + 116,
              child: MediaStrip(
                media: media,
                scrollController: mediaScrollController,
                onAddTap: onAddMediaTap,
                onRemove: onRemoveMedia,
                compact: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
