import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

Future<String?> showEditMessageSheet(
  BuildContext context, {
  required String initialContent,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetCtx) => _EditSheet(initialContent: initialContent),
  );
}

class _EditSheet extends StatefulWidget {
  final String initialContent;
  const _EditSheet({required this.initialContent});

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  bool _canSave = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialContent)
      ..addListener(_onChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focus.requestFocus();
    });
    _canSave = widget.initialContent.trim().isNotEmpty;
  }

  @override
  void dispose() {
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged() {
    final has = _controller.text.trim().isNotEmpty &&
        _controller.text.trim() != widget.initialContent.trim();
    if (has != _canSave) setState(() => _canSave = has);
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: c.onSurfaceDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(TablerIcons.pencil, color: c.onSurface, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.chat_message_edit_sheet_title.tr(),
                    style: TextStyle(
                      color: c.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: c.border,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  cursorColor: c.onSurface,
                  style: TextStyle(color: c.onSurface, fontSize: 15),
                  maxLines: 6,
                  minLines: 1,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        LocaleKeys.common_cancel.tr(),
                        style: TextStyle(color: c.onSurfaceSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Material(
                      color: _canSave ? c.primary : c.onSurfaceDisabled,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: _canSave ? _submit : null,
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Center(
                            child: Text(
                              LocaleKeys.common_save.tr(),
                              style: TextStyle(
                                color: c.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
