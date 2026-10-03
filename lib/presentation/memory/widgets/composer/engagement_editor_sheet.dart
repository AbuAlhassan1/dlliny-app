import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/request/create_memory_request.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';

Future<EngagementConfig?> showEngagementEditor(
  BuildContext context, {
  EngagementConfig? initial,
}) {
  return showModalBottomSheet<EngagementConfig>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _EngagementEditorBody(initial: initial),
    ),
  );
}

class _EngagementEditorBody extends StatefulWidget {
  final EngagementConfig? initial;
  const _EngagementEditorBody({this.initial});

  @override
  State<_EngagementEditorBody> createState() => _EngagementEditorBodyState();
}

class _EngagementEditorBodyState extends State<_EngagementEditorBody> {
  late MemoryEngagementType _type;

  late final TextEditingController _question = TextEditingController();
  late final TextEditingController _prompt = TextEditingController();
  late final List<TextEditingController> _options = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _correctIndex = 0;
  String _sliderEmoji = '🔥';

  static const List<String> _sliderEmojiChoices = [
    '🔥', '❤️', '😂', '😮', '👍', '😢', '⭐️', '🎯',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) {
      _type = MemoryEngagementType.poll;
      return;
    }
    _type = initial.type;
    final payload = initial.payload;
    switch (initial.type) {
      case MemoryEngagementType.poll:
        _question.text = (payload['question'] as String?) ?? '';
        _hydrateOptions(payload['options']);
        break;
      case MemoryEngagementType.question:
        _prompt.text = (payload['prompt'] as String?) ?? '';
        break;
      case MemoryEngagementType.slider:
        _question.text = (payload['question'] as String?) ?? '';
        _sliderEmoji = (payload['emoji'] as String?) ?? '🔥';
        break;
      case MemoryEngagementType.quiz:
        _question.text = (payload['question'] as String?) ?? '';
        _hydrateOptions(payload['options']);
        _correctIndex = (payload['correctIndex'] as int?) ?? 0;
        break;
    }
  }

  void _hydrateOptions(dynamic raw) {
    if (raw is! List) return;
    _options.clear();
    for (final v in raw) {
      _options.add(TextEditingController(text: v?.toString() ?? ''));
    }
    while (_options.length < 2) {
      _options.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _question.dispose();
    _prompt.dispose();
    for (final c in _options) {
      c.dispose();
    }
    super.dispose();
  }

  String? _validate() {
    switch (_type) {
      case MemoryEngagementType.poll:
      case MemoryEngagementType.quiz:
        if (_question.text.trim().isEmpty) return 'اكتب السؤال';
        final filled =
            _options.where((c) => c.text.trim().isNotEmpty).toList();
        if (filled.length < 2) return 'أضف خيارَين على الأقل';
        if (filled.length > 4) return 'الحد الأقصى 4 خيارات';
        if (_type == MemoryEngagementType.quiz) {
          if (_correctIndex < 0 || _correctIndex >= filled.length) {
            return 'اختَر الإجابة الصحيحة';
          }
        }
        return null;
      case MemoryEngagementType.question:
        if (_prompt.text.trim().isEmpty) return 'اكتب السؤال';
        return null;
      case MemoryEngagementType.slider:
        if (_question.text.trim().isEmpty) return 'اكتب السؤال';
        return null;
    }
  }

  EngagementConfig _build() {
    switch (_type) {
      case MemoryEngagementType.poll:
        return EngagementConfig(
          type: _type,
          payload: {
            'question': _question.text.trim(),
            'options': _options
                .map((c) => c.text.trim())
                .where((s) => s.isNotEmpty)
                .toList(),
          },
        );
      case MemoryEngagementType.question:
        return EngagementConfig(
          type: _type,
          payload: {'prompt': _prompt.text.trim()},
        );
      case MemoryEngagementType.slider:
        return EngagementConfig(
          type: _type,
          payload: {
            'question': _question.text.trim(),
            'emoji': _sliderEmoji,
          },
        );
      case MemoryEngagementType.quiz:
        final filled = _options
            .map((c) => c.text.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        return EngagementConfig(
          type: _type,
          payload: {
            'question': _question.text.trim(),
            'options': filled,
            'correctIndex': _correctIndex.clamp(0, filled.length - 1),
          },
        );
    }
  }

  void _onSave() {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    Navigator.of(context).pop(_build());
  }

  void _onTypeChanged(MemoryEngagementType next) {
    if (next == _type) return;
    setState(() => _type = next);
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
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: c.onSurfaceDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                'أضف عنصر تفاعلي',
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            _TypeSelector(active: _type, onChanged: _onTypeChanged),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: _formForType(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: FilledButton.icon(
                  onPressed: _onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.primary,
                    foregroundColor: c.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  icon: const Icon(TablerIcons.check),
                  label: const Text(
                    'حفظ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _formForType() {
    switch (_type) {
      case MemoryEngagementType.poll:
        return _PollOrQuizForm(
          question: _question,
          options: _options,
          onOptionAdded: _options.length < 4
              ? () => setState(() => _options.add(TextEditingController()))
              : null,
          onOptionRemoved: _options.length > 2
              ? (i) => setState(() => _options.removeAt(i).dispose())
              : null,
        );
      case MemoryEngagementType.question:
        return _QuestionForm(prompt: _prompt);
      case MemoryEngagementType.slider:
        return _SliderForm(
          question: _question,
          activeEmoji: _sliderEmoji,
          choices: _sliderEmojiChoices,
          onChanged: (e) => setState(() => _sliderEmoji = e),
        );
      case MemoryEngagementType.quiz:
        return _PollOrQuizForm(
          question: _question,
          options: _options,
          correctIndex: _correctIndex,
          onCorrectChanged: (i) => setState(() => _correctIndex = i),
          onOptionAdded: _options.length < 4
              ? () => setState(() => _options.add(TextEditingController()))
              : null,
          onOptionRemoved: _options.length > 2
              ? (i) {
                  setState(() {
                    _options.removeAt(i).dispose();
                    if (_correctIndex >= _options.length) {
                      _correctIndex = _options.length - 1;
                    }
                  });
                }
              : null,
        );
    }
  }
}

class _TypeSelector extends StatelessWidget {
  final MemoryEngagementType active;
  final ValueChanged<MemoryEngagementType> onChanged;
  const _TypeSelector({required this.active, required this.onChanged});

  static const _items = [
    (MemoryEngagementType.poll, TablerIcons.chart_bar, 'استطلاع'),
    (MemoryEngagementType.question, TablerIcons.message_circle, 'سؤال'),
    (MemoryEngagementType.slider, TablerIcons.adjustments_horizontal, 'منزلق'),
    (MemoryEngagementType.quiz, TablerIcons.help_circle, 'اختبار'),
  ];

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (type, icon, label) = _items[i];
          final selected = type == active;
          return GestureDetector(
            onTap: () => onChanged(type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: 84,
              decoration: BoxDecoration(
                color: selected ? c.primary : c.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: selected ? c.onPrimary : c.onSurface,
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? c.onPrimary : c.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PollOrQuizForm extends StatelessWidget {
  final TextEditingController question;
  final List<TextEditingController> options;
  final int? correctIndex;
  final ValueChanged<int>? onCorrectChanged;
  final VoidCallback? onOptionAdded;
  final ValueChanged<int>? onOptionRemoved;

  const _PollOrQuizForm({
    required this.question,
    required this.options,
    this.correctIndex,
    this.onCorrectChanged,
    this.onOptionAdded,
    this.onOptionRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isQuiz = correctIndex != null && onCorrectChanged != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledField(
          label: 'السؤال',
          controller: question,
          hint: isQuiz ? 'ما عاصمة فرنسا؟' : 'سؤالك هنا',
        ),
        const SizedBox(height: 12),
        Text(
          'الخيارات',
          style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
        ),
        const SizedBox(height: 6),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                if (isQuiz)
                  _CorrectAnswerMark(
                    selected: i == correctIndex,
                    onTap: () => onCorrectChanged!(i),
                  ),
                Expanded(
                  child: _Field(
                    controller: options[i],
                    hint: 'خيار ${i + 1}',
                  ),
                ),
                if (onOptionRemoved != null)
                  IconButton(
                    icon: Icon(TablerIcons.x, color: c.onSurfaceSecondary),
                    onPressed: () => onOptionRemoved!(i),
                  ),
              ],
            ),
          ),
        if (onOptionAdded != null)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: onOptionAdded,
              icon: const Icon(TablerIcons.plus, size: 16),
              label: const Text('إضافة خيار'),
              style: TextButton.styleFrom(foregroundColor: c.onSurface),
            ),
          ),
      ],
    );
  }
}

class _QuestionForm extends StatelessWidget {
  final TextEditingController prompt;
  const _QuestionForm({required this.prompt});

  @override
  Widget build(BuildContext context) {
    return _LabeledField(
      label: 'اطلب من المشاهدين',
      controller: prompt,
      hint: 'اسألني أي شيء',
      maxLines: 3,
    );
  }
}

class _SliderForm extends StatelessWidget {
  final TextEditingController question;
  final String activeEmoji;
  final List<String> choices;
  final ValueChanged<String> onChanged;

  const _SliderForm({
    required this.question,
    required this.activeEmoji,
    required this.choices,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _LabeledField(
          label: 'السؤال',
          controller: question,
          hint: 'كم تحب هذا؟',
        ),
        const SizedBox(height: 12),
        Text(
          'الإيموجي',
          style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in choices)
              GestureDetector(
                onTap: () => onChanged(e),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: e == activeEmoji
                        ? c.surfaceMuted
                        : c.surfaceMuted.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: e == activeEmoji ? c.onSurface : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LabeledField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _LabeledField({
    required this.label,
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        _Field(controller: controller, hint: hint, maxLines: maxLines),
      ],
    );
  }
}

class _CorrectAnswerMark extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  const _CorrectAnswerMark({required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: selected ? c.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? c.primary : c.onSurfaceMuted,
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: selected
              ? Icon(TablerIcons.check, color: c.onPrimary, size: 16)
              : null,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        cursorColor: c.onSurface,
        style: TextStyle(color: c.onSurface, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: c.onSurfaceMuted, fontSize: 14),
          border: InputBorder.none,
          isDense: true,
        ),
      ),
    );
  }
}
