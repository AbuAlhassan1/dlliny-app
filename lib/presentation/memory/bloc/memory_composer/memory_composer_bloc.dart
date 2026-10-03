import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/data/repositories/memory_upload_repository.dart';
import 'package:hangout/domain/dto/request/create_memory_request.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/widgets/composer/composer_overlay.dart';

part 'memory_composer_event.dart';
part 'memory_composer_state.dart';

class MemoryComposerBloc
    extends Bloc<MemoryComposerEvent, MemoryComposerState> {
  final MemoryRepository _repo;
  final MemoryUploadRepository _uploader;

  MemoryComposerBloc({
    required MemoryRepository repository,
    required MemoryUploadRepository uploader,
    required MemoryComposerMode mode,
    File? initialPhoto,
    File? initialVideo,
  })  : _repo = repository,
        _uploader = uploader,
        super(
          MemoryComposerState(
            mode: mode,
            photoFile: initialPhoto,
            videoFile: initialVideo,
            textContent: '',
            backgroundColor: _defaultBackgroundHex,
            textColor: _defaultTextHex,
          ),
        ) {
    on<TextChanged>(_onTextChanged);
    on<BackgroundColorChanged>(_onBackgroundChanged);
    on<TextColorChanged>(_onTextColorChanged);
    on<OverlayAdded>(_onOverlayAdded);
    on<OverlayTransformed>(_onOverlayTransformed);
    on<TextOverlayEdited>(_onTextOverlayEdited);
    on<OverlayRemoved>(_onOverlayRemoved);
    on<AudioOverlayPicked>(_onAudioPicked);
    on<AudioOverlayRemoved>(_onAudioRemoved);
    on<EngagementConfigured>(_onEngagementConfigured);
    on<EngagementRemoved>(_onEngagementRemoved);
    on<PostAsChanged>(_onPostAsChanged);
    on<PostRequested>(_onPostRequested);
  }

  void _onPostAsChanged(
    PostAsChanged event,
    Emitter<MemoryComposerState> emit,
  ) {
    if (event.venueId == null) {
      emit(state.copyWith(clearPostAsVenue: true));
    } else {
      emit(state.copyWith(postAsVenueId: event.venueId));
    }
  }

  void _onTextChanged(TextChanged event, Emitter<MemoryComposerState> emit) {
    emit(state.copyWith(textContent: event.text));
  }

  void _onBackgroundChanged(
    BackgroundColorChanged event,
    Emitter<MemoryComposerState> emit,
  ) {
    emit(state.copyWith(backgroundColor: event.hex));
  }

  void _onTextColorChanged(
    TextColorChanged event,
    Emitter<MemoryComposerState> emit,
  ) {
    emit(state.copyWith(textColor: event.hex));
  }

  void _onOverlayAdded(OverlayAdded event, Emitter<MemoryComposerState> emit) {
    emit(state.copyWith(overlays: [...state.overlays, event.overlay]));
  }

  void _onOverlayTransformed(
    OverlayTransformed event,
    Emitter<MemoryComposerState> emit,
  ) {
    final next = [
      for (final o in state.overlays)
        if (o.id == event.id)
          o.copyWithTransform(
            position: event.position,
            scale: event.scale,
            rotation: event.rotation,
          )
        else
          o,
    ];
    emit(state.copyWith(overlays: next));
  }

  void _onTextOverlayEdited(
    TextOverlayEdited event,
    Emitter<MemoryComposerState> emit,
  ) {
    final next = [
      for (final o in state.overlays)
        if (o is TextOverlay && o.id == event.id)
          o.copyWith(text: event.text, color: event.color)
        else
          o,
    ];
    emit(state.copyWith(overlays: next));
  }

  void _onOverlayRemoved(
    OverlayRemoved event,
    Emitter<MemoryComposerState> emit,
  ) {
    emit(state.copyWith(
      overlays: state.overlays.where((o) => o.id != event.id).toList(),
    ));
  }

  void _onAudioPicked(
    AudioOverlayPicked event,
    Emitter<MemoryComposerState> emit,
  ) {
    emit(state.copyWith(
      audioFile: event.file,
      audioDurationSeconds: event.durationSeconds,
    ));
  }

  void _onAudioRemoved(
    AudioOverlayRemoved event,
    Emitter<MemoryComposerState> emit,
  ) {
    emit(state.copyWith(clearAudio: true));
  }

  void _onEngagementConfigured(
    EngagementConfigured event,
    Emitter<MemoryComposerState> emit,
  ) {
    emit(state.copyWith(engagement: event.config));
  }

  void _onEngagementRemoved(
    EngagementRemoved event,
    Emitter<MemoryComposerState> emit,
  ) {
    emit(state.copyWith(clearEngagement: true));
  }

  Future<void> _onPostRequested(
    PostRequested event,
    Emitter<MemoryComposerState> emit,
  ) async {
    if (!state.canPost) return;

    emit(state.copyWith(
      status: MemoryComposerStatus.posting,
      clearError: true,
    ));

    try {
      late final MemoryResponse posted;
      final venueId = state.postAsVenueId;
      switch (state.mode) {
        case MemoryComposerMode.photo:
          final photoFile = event.compositedPhoto ?? state.photoFile!;
          final mentions = _mentionsFromOverlays(
            state.overlays,
            canvasSize: event.canvasSize,
          );
          emit(state.copyWith(status: MemoryComposerStatus.uploading));
          final audio = state.audioFile;
          final results = await Future.wait([
            _uploader.upload(
              file: photoFile,
              mimeType: _mimeForFile(photoFile),
              slot: MemoryUploadSlot.image,
              venueId: venueId,
            ),
            if (audio != null)
              _uploader.upload(
                file: audio,
                mimeType: _mimeForAudioFile(audio),
                slot: MemoryUploadSlot.audio,
                venueId: venueId,
              ),
          ]);
          final imageKey = results[0];
          final audioKey = audio == null ? null : results[1];
          emit(state.copyWith(status: MemoryComposerStatus.posting));
          final request = CreateMemoryRequest.photo(
            mediaKey: imageKey,
            audioKey: audioKey,
            audioDurationSeconds: audioKey == null
                ? null
                : (state.audioDurationSeconds ?? 1).clamp(1, 60),
            mentions: mentions.isEmpty ? null : mentions,
            engagement: state.engagement,
          );
          posted = venueId == null
              ? await _repo.createMemory(request)
              : await _repo.createVenueMemory(venueId, request);
          break;
        case MemoryComposerMode.video:
          final file = state.videoFile!;
          final duration =
              (event.videoDurationSeconds ?? 1).clamp(1, 60);
          emit(state.copyWith(status: MemoryComposerStatus.uploading));
          final key = await _uploader.upload(
            file: file,
            mimeType: _mimeForVideoFile(file),
            slot: MemoryUploadSlot.video,
            venueId: venueId,
          );
          emit(state.copyWith(status: MemoryComposerStatus.posting));
          final request = CreateMemoryRequest.video(
            mediaKey: key,
            durationSeconds: duration,
          );
          posted = venueId == null
              ? await _repo.createMemory(request)
              : await _repo.createVenueMemory(venueId, request);
          break;
        case MemoryComposerMode.text:
          final request = CreateMemoryRequest.text(
            textContent: state.textContent.trim(),
            backgroundColor: state.backgroundColor,
            textColor: state.textColor,
          );
          posted = venueId == null
              ? await _repo.createMemory(request)
              : await _repo.createVenueMemory(venueId, request);
          break;
      }
      emit(state.copyWith(
        status: MemoryComposerStatus.success,
        postedMemoryId: posted.id,
        clearError: true,
      ));
    } on MemoryException catch (e) {
      emit(state.copyWith(
        status: MemoryComposerStatus.failure,
        errorMessage: e.message,
      ));
    }
  }
}

const String _defaultBackgroundHex = '#1F1F1F';
const String _defaultTextHex = '#FFFFFF';

List<MemoryMentionInput> _mentionsFromOverlays(
  List<ComposerOverlay> overlays, {
  Size? canvasSize,
}) {
  final out = <MemoryMentionInput>[];
  for (final overlay in overlays) {
    if (overlay is! MentionOverlay) continue;
    Map<String, dynamic>? positionPayload;
    if (canvasSize != null && canvasSize.width > 0 && canvasSize.height > 0) {
      positionPayload = {
        'x': overlay.position.dx / canvasSize.width,
        'y': overlay.position.dy / canvasSize.height,
        'scale': overlay.scale,
        'rotation': overlay.rotation * 180 / math.pi,
      };
    }
    out.add(
      MemoryMentionInput(
        type: overlay.type,
        id: overlay.mentionId,
        position: positionPayload,
      ),
    );
  }
  return out;
}

String _mimeForFile(File file) {
  final path = file.path.toLowerCase();
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.webp')) return 'image/webp';
  return 'image/jpeg';
}

String _mimeForVideoFile(File file) {
  final path = file.path.toLowerCase();
  if (path.endsWith('.mov') || path.endsWith('.qt')) return 'video/quicktime';
  if (path.endsWith('.webm')) return 'video/webm';
  return 'video/mp4';
}

String _mimeForAudioFile(File file) {
  final path = file.path.toLowerCase();
  if (path.endsWith('.m4a')) return 'audio/m4a';
  if (path.endsWith('.aac')) return 'audio/aac';
  if (path.endsWith('.mp3')) return 'audio/mpeg';
  if (path.endsWith('.webm')) return 'audio/webm';
  if (path.endsWith('.ogg') || path.endsWith('.oga')) return 'audio/ogg';
  return 'audio/mp4';
}
