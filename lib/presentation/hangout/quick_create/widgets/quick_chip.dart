import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class QuickChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool loading;

  final Widget? leading;
  final VoidCallback onTap;

  const QuickChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.active = false,
    this.loading = false,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = active ? c.onPrimary : Colors.white;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: active ? c.primary : Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            loading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                  )
                : (leading ?? Icon(icon, size: 16, color: fg)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: fg,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
