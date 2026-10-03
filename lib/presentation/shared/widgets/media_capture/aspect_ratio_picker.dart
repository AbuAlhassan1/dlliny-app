import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';

class AspectRatioPicker extends StatelessWidget {
  final CaptureAspectRatio current;
  final ValueChanged<CaptureAspectRatio> onChanged;
  final bool locked;

  final List<CaptureAspectRatio>? ratios;

  const AspectRatioPicker({
    super.key,
    required this.current,
    required this.onChanged,
    this.locked = false,
    this.ratios,
  });

  @override
  Widget build(BuildContext context) {
    final available = ratios ?? CaptureAspectRatio.values;
    return Opacity(
      opacity: locked ? 0.45 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final ratio in available)
              _Chip(
                label: ratio.label,
                active: ratio == current,
                onTap: locked
                    ? null
                    : () {
                        if (ratio == current) return;
                        HapticFeedback.selectionClick();
                        onChanged(ratio);
                      },
              ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback? onTap;

  const _Chip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.black : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
    );
  }
}
