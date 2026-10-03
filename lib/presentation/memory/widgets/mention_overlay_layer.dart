import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';

class MentionOverlayLayer extends StatelessWidget {
  final List<MemoryMentionResponse> mentions;

  static const double _baseWidth = 120;
  static const double _baseHeight = 32;
  static const double _padPx = 8;

  const MentionOverlayLayer({super.key, required this.mentions});

  @override
  Widget build(BuildContext context) {
    if (mentions.isEmpty) return const SizedBox.shrink();
    final positional = <MemoryMentionResponse>[];
    final nonPositional = <MemoryMentionResponse>[];
    for (final m in mentions) {
      (m.position == null ? nonPositional : positional).add(m);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            for (final m in positional)
              _PositionalHit(
                mention: m,
                canvasSize: constraints.biggest,
              ),
            if (nonPositional.isNotEmpty)
              _NonPositionalChip(mentions: nonPositional),
          ],
        );
      },
    );
  }
}

class _PositionalHit extends StatelessWidget {
  final MemoryMentionResponse mention;
  final Size canvasSize;

  const _PositionalHit({required this.mention, required this.canvasSize});

  @override
  Widget build(BuildContext context) {
    final pos = mention.position;
    if (pos == null) return const SizedBox.shrink();

    final x = (pos['x'] as num?)?.toDouble() ?? 0;
    final y = (pos['y'] as num?)?.toDouble() ?? 0;
    final scale = (pos['scale'] as num?)?.toDouble() ?? 1.0;
    final rotationDeg = (pos['rotation'] as num?)?.toDouble() ?? 0;
    final rotationRad = rotationDeg * math.pi / 180;

    final left = x * canvasSize.width;
    final top = y * canvasSize.height;

    return Positioned(
      left: left - MentionOverlayLayer._padPx,
      top: top - MentionOverlayLayer._padPx,
      child: Transform.rotate(
        angle: rotationRad,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _openMention(context, mention),
            child: SizedBox(
              width: MentionOverlayLayer._baseWidth +
                  MentionOverlayLayer._padPx * 2,
              height: MentionOverlayLayer._baseHeight +
                  MentionOverlayLayer._padPx * 2,
            ),
          ),
        ),
      ),
    );
  }
}

class _NonPositionalChip extends StatelessWidget {
  final List<MemoryMentionResponse> mentions;
  const _NonPositionalChip({required this.mentions});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Positioned(
      left: 12,
      right: 12,
      bottom: 120,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openFirstAvailable(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: c.scrimSubtle,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: c.onMediaSurface.withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                TablerIcons.at,
                color: c.onMediaSurface.withValues(alpha: 0.7),
                size: 14,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  _summary(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.onMediaSurface, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _summary() {
    final labels = mentions
        .take(3)
        .map((m) => m.displayName ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (labels.isEmpty) return 'ذُكر بعض الأشخاص';
    final extra = mentions.length - labels.length;
    final joined = labels.join('، ');
    return extra > 0 ? 'ذُكر: $joined +$extra' : 'ذُكر: $joined';
  }

  void _openFirstAvailable(BuildContext context) {
    if (mentions.isEmpty) return;
    _openMention(context, mentions.first);
  }
}

void _openMention(BuildContext context, MemoryMentionResponse mention) {
  switch (mention.type) {
    case MemoryMentionType.venue:
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VenuePageWrapper(venueId: mention.id),
        ),
      );
      return;
    case MemoryMentionType.user:
      appToast.info(
        mention.displayName ?? 'مستخدم',
        body: 'فتح ملف المستخدم سيتاح لاحقاً',
      );
      return;
  }
}
