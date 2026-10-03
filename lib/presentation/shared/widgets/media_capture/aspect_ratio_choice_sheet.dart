import 'package:flutter/material.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/aspect_ratio_picker.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';

Future<CaptureAspectRatio?> showAspectChoiceSheet(
  BuildContext context, {
  required CaptureAspectRatio initial,
  List<CaptureAspectRatio>? ratios,
}) {
  return showModalBottomSheet<CaptureAspectRatio>(
    context: context,
    backgroundColor: const Color(0xFF1A1A1A),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) =>
        _AspectChoiceSheet(initial: initial, ratios: ratios),
  );
}

class _AspectChoiceSheet extends StatefulWidget {
  final CaptureAspectRatio initial;
  final List<CaptureAspectRatio>? ratios;
  const _AspectChoiceSheet({required this.initial, this.ratios});

  @override
  State<_AspectChoiceSheet> createState() => _AspectChoiceSheetState();
}

class _AspectChoiceSheetState extends State<_AspectChoiceSheet> {
  late CaptureAspectRatio _selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'اختر نسبة الصورة',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'هاي النسبة راح تنطبق على باقي الوسائط لنفس البوست',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 12,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(height: 16),
            AspectRatioPicker(
              current: _selected,
              ratios: widget.ratios,
              onChanged: (next) => setState(() => _selected = next),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, _selected),
                    child: const Text(
                      'تأكيد',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
