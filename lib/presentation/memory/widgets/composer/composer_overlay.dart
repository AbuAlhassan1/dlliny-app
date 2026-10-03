import 'package:flutter/material.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';

sealed class ComposerOverlay {
  final String id;

  final Offset position;

  final double scale;

  final double rotation;

  const ComposerOverlay({
    required this.id,
    required this.position,
    required this.scale,
    required this.rotation,
  });

  ComposerOverlay copyWithTransform({
    Offset? position,
    double? scale,
    double? rotation,
  });
}

class TextOverlay extends ComposerOverlay {
  final String text;
  final Color color;

  const TextOverlay({
    required super.id,
    required super.position,
    required super.scale,
    required super.rotation,
    required this.text,
    required this.color,
  });

  TextOverlay copyWith({String? text, Color? color}) {
    return TextOverlay(
      id: id,
      position: position,
      scale: scale,
      rotation: rotation,
      text: text ?? this.text,
      color: color ?? this.color,
    );
  }

  @override
  TextOverlay copyWithTransform({
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return TextOverlay(
      id: id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      text: text,
      color: color,
    );
  }
}

class MentionOverlay extends ComposerOverlay {
  final MemoryMentionType type;
  final String mentionId;

  final String label;

  const MentionOverlay({
    required super.id,
    required super.position,
    required super.scale,
    required super.rotation,
    required this.type,
    required this.mentionId,
    required this.label,
  });

  @override
  MentionOverlay copyWithTransform({
    Offset? position,
    double? scale,
    double? rotation,
  }) {
    return MentionOverlay(
      id: id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      type: type,
      mentionId: mentionId,
      label: label,
    );
  }
}
