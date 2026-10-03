import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/request/engagement_response_request.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/bloc/memory_viewer/memory_viewer_bloc.dart';
import 'package:hangout/presentation/memory/widgets/engagement/engagement_results_sheet.dart';

class MemoryEngagementWidget extends StatefulWidget {
  final MemoryResponse memory;

  const MemoryEngagementWidget({super.key, required this.memory});

  @override
  State<MemoryEngagementWidget> createState() => _MemoryEngagementWidgetState();
}

class _MemoryEngagementWidgetState extends State<MemoryEngagementWidget> {
  Offset? _position;

  Map<String, dynamic>? _localResponse;
  bool _hasLocalResponse = false;

  bool _submitting = false;

  late final MemoryRepository _repo = serviceLocator.get<MemoryRepository>();

  EngagementInfo get _engagement => widget.memory.engagement!;

  Map<String, dynamic>? get _myResponse =>
      _hasLocalResponse ? _localResponse : _engagement.myResponse;

  bool get _hasAnswered => _myResponse != null;
  bool get _isOwner => widget.memory.mine;

  Future<void> _submit(Map<String, dynamic> response) async {
    if (_submitting || _isOwner) return;
    HapticFeedback.selectionClick();
    final previous = _myResponse;
    setState(() {
      _localResponse = response;
      _hasLocalResponse = true;
      _submitting = true;
    });
    try {
      await _repo.respondToEngagement(
        widget.memory.id,
        EngagementResponseRequest(response: response),
      );
    } on MemoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _localResponse = previous;
        _hasLocalResponse = previous != null;
        _submitting = false;
      });
      appToast.error(e.message);
      if (e is MemoryExpiredException) {
        context
            .read<MemoryViewerBloc>()
            .add(MemoryDeletedLocally(widget.memory.id));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _submitting = false);
  }

  void _openResults() {
    final raw = _engagement.payload['options'];
    final options = raw is List ? raw : const [];
    showEngagementResultsSheet(
      context,
      memoryId: widget.memory.id,
      originalOptions: options,
    );
  }

  void _onPanStart(_) {
    HapticFeedback.selectionClick();
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() {
      final p = _position ?? Offset.zero;
      _position = p + d.delta;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_position == null) {
          const cardWidth = 280.0;
          const cardHeight = 160.0;
          _position = Offset(
            (constraints.maxWidth - cardWidth) / 2,
            constraints.maxHeight * 0.55 - cardHeight / 2,
          );
        }
        return Stack(
          children: [
            Positioned(
              left: _position!.dx,
              top: _position!.dy,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                child: _EngagementCard(
                  engagement: _engagement,
                  myResponse: _myResponse,
                  isOwner: _isOwner,
                  submitting: _submitting,
                  onSubmit: _submit,
                  hasAnswered: _hasAnswered,
                  onShowResults: _openResults,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EngagementCard extends StatelessWidget {
  final EngagementInfo engagement;
  final Map<String, dynamic>? myResponse;
  final bool isOwner;
  final bool submitting;
  final bool hasAnswered;
  final Future<void> Function(Map<String, dynamic>) onSubmit;
  final VoidCallback onShowResults;

  const _EngagementCard({
    required this.engagement,
    required this.myResponse,
    required this.isOwner,
    required this.submitting,
    required this.hasAnswered,
    required this.onSubmit,
    required this.onShowResults,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: c.scrim,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.onMediaSurface.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _body(),
          if (isOwner) ...[
            const SizedBox(height: 10),
            _OwnerResultsButton(onTap: onShowResults),
          ],
        ],
      ),
    );
  }

  Widget _body() {
    switch (engagement.type) {
      case MemoryEngagementType.poll:
        return _PollBody(
          engagement: engagement,
          myResponse: myResponse,
          isOwner: isOwner,
          submitting: submitting,
          onSubmit: onSubmit,
        );
      case MemoryEngagementType.question:
        return _QuestionBody(
          engagement: engagement,
          myResponse: myResponse,
          isOwner: isOwner,
          submitting: submitting,
          hasAnswered: hasAnswered,
          onSubmit: onSubmit,
        );
      case MemoryEngagementType.slider:
        return _SliderBody(
          engagement: engagement,
          myResponse: myResponse,
          isOwner: isOwner,
          submitting: submitting,
          onSubmit: onSubmit,
        );
      case MemoryEngagementType.quiz:
        return _QuizBody(
          engagement: engagement,
          myResponse: myResponse,
          isOwner: isOwner,
          submitting: submitting,
          onSubmit: onSubmit,
        );
    }
  }
}

class _OwnerResultsButton extends StatelessWidget {
  final VoidCallback onTap;
  const _OwnerResultsButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: c.onMediaSurface.withValues(alpha: 0.54)),
          foregroundColor: c.onMediaSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        icon: const Icon(TablerIcons.chart_bar, size: 14),
        label: const Text('عرض النتائج', style: TextStyle(fontSize: 12)),
      ),
    );
  }
}

class _PollBody extends StatelessWidget {
  final EngagementInfo engagement;
  final Map<String, dynamic>? myResponse;
  final bool isOwner;
  final bool submitting;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _PollBody({
    required this.engagement,
    required this.myResponse,
    required this.isOwner,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final question = engagement.payload['question'] as String? ?? '';
    final options =
        (engagement.payload['options'] as List?)?.cast<dynamic>() ?? const [];
    final picked = (myResponse?['optionIndex'] as num?)?.toInt();
    final locked = isOwner || submitting || picked != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Question(question),
        const SizedBox(height: 8),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _OptionTile(
              label: options[i]?.toString() ?? '',
              selected: i == picked,
              dimmed: picked != null && i != picked,
              onTap: locked ? null : () => onSubmit({'optionIndex': i}),
            ),
          ),
      ],
    );
  }
}

class _QuestionBody extends StatefulWidget {
  final EngagementInfo engagement;
  final Map<String, dynamic>? myResponse;
  final bool isOwner;
  final bool submitting;
  final bool hasAnswered;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _QuestionBody({
    required this.engagement,
    required this.myResponse,
    required this.isOwner,
    required this.submitting,
    required this.hasAnswered,
    required this.onSubmit,
  });

  @override
  State<_QuestionBody> createState() => _QuestionBodyState();
}

class _QuestionBodyState extends State<_QuestionBody> {
  late final TextEditingController _controller = TextEditingController();
  late final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocusChanged);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!mounted) return;
    context.read<MemoryViewerBloc>().add(
          PausedToggled(paused: _focus.hasFocus),
        );
  }

  void _onSubmit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _focus.unfocus();
    widget.onSubmit({'text': text});
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final prompt = widget.engagement.payload['prompt'] as String? ?? '';
    final myText = widget.myResponse?['text'] as String?;

    if (widget.hasAnswered) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Question(prompt),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: c.onMediaSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              myText ?? '',
              style: TextStyle(color: c.onMediaSurface, fontSize: 13),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'تم إرسال إجابتك',
            style: TextStyle(
              color: c.onMediaSurface.withValues(alpha: 0.60),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Question(prompt),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: c.onMediaSurface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  enabled: !widget.isOwner && !widget.submitting,
                  cursorColor: c.onMediaSurface,
                  style: TextStyle(color: c.onMediaSurface, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'اكتب إجابتك…',
                    hintStyle: TextStyle(
                      color: c.onMediaSurface.withValues(alpha: 0.38),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _onSubmit(),
                ),
              ),
              IconButton(
                icon: widget.submitting
                    ? SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onMediaSurface,
                        ),
                      )
                    : Icon(TablerIcons.send, color: c.onMediaSurface, size: 18),
                onPressed: widget.isOwner || widget.submitting
                    ? null
                    : _onSubmit,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SliderBody extends StatefulWidget {
  final EngagementInfo engagement;
  final Map<String, dynamic>? myResponse;
  final bool isOwner;
  final bool submitting;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _SliderBody({
    required this.engagement,
    required this.myResponse,
    required this.isOwner,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  State<_SliderBody> createState() => _SliderBodyState();
}

class _SliderBodyState extends State<_SliderBody> {
  double _value = 50;

  @override
  void initState() {
    super.initState();
    final mine = (widget.myResponse?['value'] as num?)?.toDouble();
    if (mine != null) _value = mine.clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final question = widget.engagement.payload['question'] as String? ?? '';
    final emoji = widget.engagement.payload['emoji'] as String? ?? '🔥';
    final locked = widget.isOwner ||
        widget.submitting ||
        widget.myResponse != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Question(question),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            thumbShape: _EmojiThumbShape(emoji: emoji),
            overlayShape: SliderComponentShape.noOverlay,
            activeTrackColor: c.onMediaSurface,
            inactiveTrackColor: c.onMediaSurface.withValues(alpha: 0.24),
          ),
          child: Slider(
            value: _value,
            min: 0,
            max: 100,
            onChanged: locked
                ? null
                : (v) => setState(() => _value = v),
            onChangeEnd: locked
                ? null
                : (v) =>
                    widget.onSubmit({'value': v.round().clamp(0, 100)}),
          ),
        ),
        if (widget.myResponse != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'تم إرسال صوتك',
              style: TextStyle(
                color: c.onMediaSurface.withValues(alpha: 0.60),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }
}

class _EmojiThumbShape extends SliderComponentShape {
  final String emoji;
  _EmojiThumbShape({required this.emoji});

  static const double _size = 28;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(_size, _size);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextDirection textDirection,
    required double textScaleFactor,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Size sizeWithOverflow,
    required double value,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: emoji, style: const TextStyle(fontSize: 22)),
      textDirection: TextDirection.ltr,
    )..layout();
    final offset = center.translate(-tp.width / 2, -tp.height / 2);
    tp.paint(context.canvas, offset);
  }
}

class _QuizBody extends StatelessWidget {
  final EngagementInfo engagement;
  final Map<String, dynamic>? myResponse;
  final bool isOwner;
  final bool submitting;
  final Future<void> Function(Map<String, dynamic>) onSubmit;

  const _QuizBody({
    required this.engagement,
    required this.myResponse,
    required this.isOwner,
    required this.submitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final question = engagement.payload['question'] as String? ?? '';
    final options =
        (engagement.payload['options'] as List?)?.cast<dynamic>() ?? const [];
    final picked = (myResponse?['optionIndex'] as num?)?.toInt();
    final correctIndex = (engagement.payload['correctIndex'] as num?)?.toInt();
    final locked = isOwner || submitting || picked != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _Question(question),
        const SizedBox(height: 8),
        for (var i = 0; i < options.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _QuizOptionTile(
              label: options[i]?.toString() ?? '',
              isPicked: i == picked,
              isCorrect: correctIndex != null && i == correctIndex,
              isAnswered: picked != null,
              onTap: locked ? null : () => onSubmit({'optionIndex': i}),
            ),
          ),
      ],
    );
  }
}

class _Question extends StatelessWidget {
  final String text;
  const _Question(this.text);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(
      text,
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: c.onMediaSurface,
        fontSize: 14,
        fontWeight: FontWeight.w700,
        height: 1.25,
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final String label;
  final bool selected;
  final bool dimmed;
  final VoidCallback? onTap;

  const _OptionTile({
    required this.label,
    required this.selected,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? c.onMediaSurface
              : c.onMediaSurface.withValues(alpha: dimmed ? 0.06 : 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? c.mediaSurface : c.onMediaSurface,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  final String label;
  final bool isPicked;
  final bool isCorrect;
  final bool isAnswered;
  final VoidCallback? onTap;

  const _QuizOptionTile({
    required this.label,
    required this.isPicked,
    required this.isCorrect,
    required this.isAnswered,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    Color bg;
    Color fg;
    if (!isAnswered) {
      bg = c.onMediaSurface.withValues(alpha: 0.12);
      fg = c.onMediaSurface;
    } else if (isCorrect) {
      bg = const Color(0xFF34C759);
      fg = Colors.black;
    } else if (isPicked) {
      bg = const Color(0xFFFF3B30);
      fg = c.onMediaSurface;
    } else {
      bg = c.onMediaSurface.withValues(alpha: 0.06);
      fg = c.onMediaSurface.withValues(alpha: 0.70);
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: fg,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
