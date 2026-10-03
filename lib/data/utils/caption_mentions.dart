import 'package:flutter/material.dart' show TextDirection;
import 'package:hangout/domain/dto/response/post_response.dart';

final RegExp _mentionPattern = RegExp(
  r'@([A-Za-z0-9_.]{3,30})',
);

sealed class CaptionSegment {
  const CaptionSegment();
}

class PlainSegment extends CaptionSegment {
  final String text;
  const PlainSegment(this.text);
}

class MentionSegment extends CaptionSegment {
  final String text;

  final String handle;

  final UserMention? resolved;

  const MentionSegment({
    required this.text,
    required this.handle,
    this.resolved,
  });
}

List<CaptionSegment> parseCaptionSegments(
  String? caption,
  List<UserMention>? userMentions,
) {
  if (caption == null || caption.isEmpty) return const [];

  final byHandle = (userMentions == null || userMentions.isEmpty)
      ? <String, UserMention>{}
      : {for (final m in userMentions) m.username.toLowerCase(): m};
  final lenient = byHandle.isEmpty;

  final out = <CaptionSegment>[];
  int cursor = 0;
  for (final match in _mentionPattern.allMatches(caption)) {
    final handle = match.group(1)!.toLowerCase();
    final resolved = byHandle[handle];
    if (!lenient && resolved == null) {
      continue;
    }
    if (match.start > cursor) {
      out.add(PlainSegment(caption.substring(cursor, match.start)));
    }
    out.add(MentionSegment(
      text: match.group(0)!,
      handle: handle,
      resolved: resolved,
    ));
    cursor = match.end;
  }
  if (cursor < caption.length) {
    out.add(PlainSegment(caption.substring(cursor)));
  }
  return out.isEmpty ? [PlainSegment(caption)] : out;
}

List<String> pruneMentionedUserIds({
  required String? caption,
  required List<String> mentionedUserIds,
  required List<UserMention> resolvedMentions,
}) {
  if (caption == null || caption.isEmpty) return const [];
  if (mentionedUserIds.isEmpty) return const [];

  final stillReferenced = <String>{
    for (final match in _mentionPattern.allMatches(caption))
      match.group(1)!.toLowerCase(),
  };

  final idToHandle = <String, String>{
    for (final m in resolvedMentions) m.id: m.username.toLowerCase(),
  };

  return mentionedUserIds.where((id) {
    final handle = idToHandle[id];
    return handle != null && stillReferenced.contains(handle);
  }).toList(growable: false);
}

TextDirection detectCaptionDirection(String? caption) {
  if (caption == null || caption.isEmpty) return TextDirection.ltr;
  int arabic = 0;
  int latin = 0;
  for (final code in caption.runes) {
    if ((code >= 0x0600 && code <= 0x06FF) ||
        (code >= 0x0750 && code <= 0x077F) ||
        (code >= 0x08A0 && code <= 0x08FF) ||
        (code >= 0xFB50 && code <= 0xFDFF) ||
        (code >= 0xFE70 && code <= 0xFEFF)) {
      arabic++;
    } else if ((code >= 0x0041 && code <= 0x005A) ||
        (code >= 0x0061 && code <= 0x007A)) {
      latin++;
    }
  }
  return arabic > latin ? TextDirection.rtl : TextDirection.ltr;
}

