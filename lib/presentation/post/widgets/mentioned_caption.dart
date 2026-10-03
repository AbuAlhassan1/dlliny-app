import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:hangout/data/utils/caption_mentions.dart';
import 'package:hangout/domain/dto/response/post_response.dart';

class MentionedCaption extends StatefulWidget {
  final String? caption;
  final List<UserMention>? userMentions;
  final TextStyle? baseStyle;
  final TextStyle? mentionStyle;
  final void Function(String handle, UserMention? resolved)? onMentionTap;

  final int? maxLines;
  final TextOverflow overflow;
  final TextDirection? textDirection;

  const MentionedCaption({
    super.key,
    required this.caption,
    this.userMentions,
    this.baseStyle,
    this.mentionStyle,
    this.onMentionTap,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.textDirection,
  });

  @override
  State<MentionedCaption> createState() => _MentionedCaptionState();
}

class _MentionedCaptionState extends State<MentionedCaption> {
  final List<TapGestureRecognizer> _recognizers = [];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  void _resetRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _resetRecognizers();

    final segments =
        parseCaptionSegments(widget.caption, widget.userMentions);
    if (segments.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final baseStyle = widget.baseStyle ?? theme.textTheme.bodyMedium;
    final mentionStyle = widget.mentionStyle ??
        baseStyle?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        );

    final spans = segments.map<InlineSpan>((seg) {
      if (seg is PlainSegment) {
        return TextSpan(text: seg.text);
      }
      final mention = seg as MentionSegment;
      final recognizer = TapGestureRecognizer()
        ..onTap = () =>
            widget.onMentionTap?.call(mention.handle, mention.resolved);
      _recognizers.add(recognizer);
      return TextSpan(
        text: mention.text,
        style: mentionStyle,
        recognizer: recognizer,
      );
    }).toList();

    final direction =
        widget.textDirection ?? detectCaptionDirection(widget.caption);

    return Text.rich(
      TextSpan(style: baseStyle, children: spans),
      maxLines: widget.maxLines,
      overflow: widget.overflow,
      textDirection: direction,
    );
  }
}
