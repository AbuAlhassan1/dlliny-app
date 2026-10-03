part of 'memory_composer_bloc.dart';

enum MemoryComposerMode { photo, video, text }

enum MemoryComposerStatus {
  idle,
  uploading,
  posting,
  success,
  failure,
}

class MemoryComposerState {
  final MemoryComposerMode mode;

  final File? photoFile;

  final File? videoFile;

  final List<ComposerOverlay> overlays;

  final File? audioFile;
  final int? audioDurationSeconds;

  final EngagementConfig? engagement;

  final String? postAsVenueId;

  final String textContent;
  final String backgroundColor;
  final String textColor;

  final MemoryComposerStatus status;
  final String? errorMessage;
  final String? postedMemoryId;

  const MemoryComposerState({
    required this.mode,
    this.photoFile,
    this.videoFile,
    this.overlays = const [],
    this.audioFile,
    this.audioDurationSeconds,
    this.engagement,
    this.postAsVenueId,
    required this.textContent,
    required this.backgroundColor,
    required this.textColor,
    this.status = MemoryComposerStatus.idle,
    this.errorMessage,
    this.postedMemoryId,
  });

  bool get canPost {
    if (status == MemoryComposerStatus.uploading ||
        status == MemoryComposerStatus.posting ||
        status == MemoryComposerStatus.success) {
      return false;
    }
    switch (mode) {
      case MemoryComposerMode.photo:
        return photoFile != null;
      case MemoryComposerMode.video:
        return videoFile != null;
      case MemoryComposerMode.text:
        return textContent.trim().isNotEmpty;
    }
  }

  bool get isBusy =>
      status == MemoryComposerStatus.uploading ||
      status == MemoryComposerStatus.posting;

  MemoryComposerState copyWith({
    File? photoFile,
    File? videoFile,
    List<ComposerOverlay>? overlays,
    File? audioFile,
    int? audioDurationSeconds,
    EngagementConfig? engagement,
    String? postAsVenueId,
    String? textContent,
    String? backgroundColor,
    String? textColor,
    MemoryComposerStatus? status,
    String? errorMessage,
    String? postedMemoryId,
    bool clearError = false,
    bool clearAudio = false,
    bool clearEngagement = false,
    bool clearPostAsVenue = false,
  }) {
    return MemoryComposerState(
      mode: mode,
      photoFile: photoFile ?? this.photoFile,
      videoFile: videoFile ?? this.videoFile,
      overlays: overlays ?? this.overlays,
      audioFile: clearAudio ? null : (audioFile ?? this.audioFile),
      audioDurationSeconds: clearAudio
          ? null
          : (audioDurationSeconds ?? this.audioDurationSeconds),
      engagement:
          clearEngagement ? null : (engagement ?? this.engagement),
      postAsVenueId: clearPostAsVenue
          ? null
          : (postAsVenueId ?? this.postAsVenueId),
      textContent: textContent ?? this.textContent,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      postedMemoryId: postedMemoryId ?? this.postedMemoryId,
    );
  }
}
