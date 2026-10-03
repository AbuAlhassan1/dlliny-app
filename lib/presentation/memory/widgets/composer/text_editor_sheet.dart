import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';

class TextEditorResult {
  final String text;
  final Color color;
  const TextEditorResult({required this.text, required this.color});
}

const List<Color> _textColors = [
  Colors.white,
  Colors.black,
  Color(0xFFFFCC00),
  Color(0xFFFF3B30),
  Color(0xFF34C759),
  Color(0xFF007AFF),
  Color(0xFFFF2D55),
  Color(0xFFAF52DE),
];

Future<TextEditorResult?> showTextOverlayEditor(
  BuildContext context, {
  String initialText = '',
  Color initialColor = Colors.white,
}) {
  return showModalBottomSheet<TextEditorResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _TextEditorBody(
      initialText: initialText,
      initialColor: initialColor,
    ),
  );
}

class _TextEditorBody extends StatefulWidget {
  final String initialText;
  final Color initialColor;

  const _TextEditorBody({
    required this.initialText,
    required this.initialColor,
  });

  @override
  State<_TextEditorBody> createState() => _TextEditorBodyState();
}

class _TextEditorBodyState extends State<_TextEditorBody> {
  late final TextEditingController _controller;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _color = widget.initialColor;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    Navigator.of(context).pop(TextEditorResult(text: text, color: _color));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: t.onSurfaceDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 4,
                minLines: 1,
                cursorColor: t.onSurface,
                style: TextStyle(
                  color: _color,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'اكتب…',
                  hintStyle: TextStyle(color: t.onSurfaceMuted),
                  border: InputBorder.none,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 32,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _textColors.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final c = _textColors[i];
                    final selected = c.toARGB32() == _color.toARGB32();
                    return GestureDetector(
                      onTap: () => setState(() => _color = c),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 140),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected
                                ? t.onSurface
                                : t.onSurfaceDisabled,
                            width: selected ? 2.5 : 1.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: t.primary,
                    foregroundColor: t.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(TablerIcons.check),
                  label: const Text('تم',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
