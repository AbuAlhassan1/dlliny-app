import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/intent_response.dart';

class IntentChip extends StatelessWidget {
  final IntentResponse intent;
  final bool selected;
  final VoidCallback onTap;
  const IntentChip({
    super.key,
    required this.intent,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tint = _parseHexColor(intent.color);

    final Color bg;
    final Color borderColor;
    final Color fg;
    if (tint != null) {
      if (selected) {
        bg = tint;
        borderColor = tint;
        fg = _contrastOn(tint);
      } else {
        bg = Color.alphaBlend(tint.withValues(alpha: 0.12), c.surface);
        borderColor = tint.withValues(alpha: 0.55);
        fg = c.onSurface;
      }
    } else {
      bg = selected ? c.primary : c.surface;
      borderColor = selected ? c.primary : c.border;
      fg = selected ? c.onPrimary : c.onSurface;
    }

    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(
            intent.labelAr,
            style: TextStyle(
              color: fg,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ),
    );
  }

  static Color _contrastOn(Color background) =>
      background.computeLuminance() > 0.5 ? Colors.black : Colors.white;

  static Color? _parseHexColor(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    var s = hex.startsWith('#') ? hex.substring(1) : hex;
    if (s.length == 6) {
      s = 'FF$s';
    } else if (s.length == 8) {
      s = s.substring(6) + s.substring(0, 6);
    } else {
      return null;
    }
    final value = int.tryParse(s, radix: 16);
    return value == null ? null : Color(value);
  }
}
