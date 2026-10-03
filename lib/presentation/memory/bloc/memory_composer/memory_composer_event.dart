part of 'memory_composer_bloc.dart';

sealed class MemoryComposerEvent {}

class TextChanged extends MemoryComposerEvent {
  final String text;
  TextChanged(this.text);
}

class BackgroundColorChanged extends MemoryComposerEvent {
  final String hex;
  BackgroundColorChanged(this.hex);
}

class TextColorChanged extends MemoryComposerEvent {
  final String hex;
  TextColorChanged(this.hex);
}

class OverlayAdded extends MemoryComposerEvent {
  final ComposerOverlay overlay;
  OverlayAdded(this.overlay);
}

class OverlayTransformed extends MemoryComposerEvent {
  final String id;
  final Offset position;
  final double scale;
  final double rotation;
  OverlayTransformed({
    required this.id,
    required this.position,
    required this.scale,
    required this.rotation,
  });
}

class TextOverlayEdited extends MemoryComposerEvent {
  final String id;
  final String text;
  final Color color;
  TextOverlayEdited({
    required this.id,
    required this.text,
    required this.color,
  });
}

class OverlayRemoved extends MemoryComposerEvent {
  final String id;
  OverlayRemoved(this.id);
}

class AudioOverlayPicked extends MemoryComposerEvent {
  final File file;
  final int durationSeconds;
  AudioOverlayPicked({required this.file, required this.durationSeconds});
}

class AudioOverlayRemoved extends MemoryComposerEvent {}

class EngagementConfigured extends MemoryComposerEvent {
  final EngagementConfig config;
  EngagementConfigured(this.config);
}

class EngagementRemoved extends MemoryComposerEvent {}

class PostAsChanged extends MemoryComposerEvent {
  final String? venueId;
  PostAsChanged(this.venueId);
}

class PostRequested extends MemoryComposerEvent {
  final File? compositedPhoto;
  final Size? canvasSize;
  final int? videoDurationSeconds;
  PostRequested({
    this.compositedPhoto,
    this.canvasSize,
    this.videoDurationSeconds,
  });
}
