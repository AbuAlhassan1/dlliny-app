import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/data_sources/camera_service.dart';
import 'package:hangout/helper/image_picker.dart';

sealed class MemorySourceChoice {
  const MemorySourceChoice();
}

class MemorySourcePhoto extends MemorySourceChoice {
  final File file;
  const MemorySourcePhoto(this.file);
}

class MemorySourceVideo extends MemorySourceChoice {
  final File file;
  const MemorySourceVideo(this.file);
}

class MemorySourceTextCard extends MemorySourceChoice {
  const MemorySourceTextCard();
}

Future<MemorySourceChoice?> showMemorySourcePicker(BuildContext context) {
  final c = context.c;
  return showModalBottomSheet<MemorySourceChoice>(
    context: context,
    backgroundColor: c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: c.onSurfaceDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'إنشاء قصة',
              style: TextStyle(
                color: c.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            _SourceTile(
              icon: TablerIcons.camera,
              label: 'التقاط صورة',
              onTap: () async {
                final file = await CameraService().takePhoto();
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext)
                    .pop(file == null ? null : MemorySourcePhoto(file));
              },
            ),
            _SourceTile(
              icon: TablerIcons.video,
              label: 'تصوير فيديو',
              onTap: () async {
                final file = await CameraService().takeVideo();
                if (!sheetContext.mounted) return;
                Navigator.of(sheetContext)
                    .pop(file == null ? null : MemorySourceVideo(file));
              },
            ),
            _SourceTile(
              icon: TablerIcons.photo,
              label: 'من المعرض',
              onTap: () async {
                final file = await pickMedia();
                if (!sheetContext.mounted) return;
                if (file == null) {
                  Navigator.of(sheetContext).pop();
                  return;
                }
                final choice = isVideoFile(file)
                    ? MemorySourceVideo(file)
                    : MemorySourcePhoto(file);
                Navigator.of(sheetContext).pop(choice);
              },
            ),
            _SourceTile(
              icon: TablerIcons.text_caption,
              label: 'بطاقة نصية',
              onTap: () => Navigator.of(sheetContext)
                  .pop(const MemorySourceTextCard()),
            ),
          ],
        ),
      ),
    ),
  );
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.onSurface.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: c.onSurface, size: 22),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
