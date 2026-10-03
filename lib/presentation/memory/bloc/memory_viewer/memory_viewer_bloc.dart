import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/bloc/memory_tray/memory_tray_bloc.dart';

part 'memory_viewer_event.dart';
part 'memory_viewer_state.dart';

class MemoryViewerBloc extends Bloc<MemoryViewerEvent, MemoryViewerState> {
  static const Duration _viewRecordingDelay = Duration(milliseconds: 500);

  final MemoryRepository _repo;
  final MemoryTrayBloc _tray;

  final Set<String> _recordedMemoryIds = {};

  Timer? _viewDebounce;

  MemoryViewerBloc({
    required MemoryRepository repository,
    required MemoryTrayBloc trayBloc,
    required List<MemoryTrayBucket> buckets,
    required int initialBucketIndex,
  })  : _repo = repository,
        _tray = trayBloc,
        super(
          MemoryViewerState(
            buckets: buckets,
            bucketIndex: initialBucketIndex.clamp(0, buckets.length - 1),
            memoryIndex: 0,
          ),
        ) {
    on<ViewerOpened>(_onOpened);
    on<NextMemory>(_onNext);
    on<PreviousMemory>(_onPrevious);
    on<BucketSwiped>(_onBucketSwiped);
    on<PausedToggled>(_onPausedToggled);
    on<ViewRecorded>(_onViewRecorded);
    on<MemoryDeletedLocally>(_onMemoryDeletedLocally);
    on<ReactionOverrideSet>(_onReactionOverrideSet);
    on<ViewerClosed>(_onClosed);
  }

  void _onReactionOverrideSet(
    ReactionOverrideSet event,
    Emitter<MemoryViewerState> emit,
  ) {
    final next = {...state.reactionOverrides, event.memoryId: event.emoji};
    emit(state.copyWith(reactionOverrides: next));
  }

  @override
  Future<void> close() {
    _viewDebounce?.cancel();
    return super.close();
  }

  void _onOpened(ViewerOpened event, Emitter<MemoryViewerState> emit) {
    _scheduleViewRecord(state.currentMemory.id);
  }

  void _onNext(NextMemory event, Emitter<MemoryViewerState> emit) {
    final s = state;
    if (s.memoryIndex < s.currentBucket.memories.length - 1) {
      emit(s.copyWith(memoryIndex: s.memoryIndex + 1));
      _scheduleViewRecord(state.currentMemory.id);
      return;
    }
    if (s.bucketIndex < s.buckets.length - 1) {
      _tray.add(
        BucketWatchedLocally(
          ownerType: s.currentBucket.owner.type,
          ownerId: s.currentBucket.owner.id,
        ),
      );
      emit(s.copyWith(bucketIndex: s.bucketIndex + 1, memoryIndex: 0));
      _scheduleViewRecord(state.currentMemory.id);
    } else {
      _tray.add(
        BucketWatchedLocally(
          ownerType: s.currentBucket.owner.type,
          ownerId: s.currentBucket.owner.id,
        ),
      );
      emit(s.copyWith(status: MemoryViewerStatus.shouldClose));
    }
  }

  void _onPrevious(PreviousMemory event, Emitter<MemoryViewerState> emit) {
    final s = state;
    if (s.memoryIndex > 0) {
      emit(s.copyWith(memoryIndex: s.memoryIndex - 1));
      _scheduleViewRecord(state.currentMemory.id);
      return;
    }
    if (s.bucketIndex > 0) {
      final prevBucketIndex = s.bucketIndex - 1;
      final prevBucket = s.buckets[prevBucketIndex];
      emit(
        s.copyWith(
          bucketIndex: prevBucketIndex,
          memoryIndex: prevBucket.memories.length - 1,
        ),
      );
      _scheduleViewRecord(state.currentMemory.id);
    }
  }

  void _onBucketSwiped(BucketSwiped event, Emitter<MemoryViewerState> emit) {
    if (event.bucketIndex == state.bucketIndex) return;
    _tray.add(
      BucketWatchedLocally(
        ownerType: state.currentBucket.owner.type,
        ownerId: state.currentBucket.owner.id,
      ),
    );
    emit(state.copyWith(bucketIndex: event.bucketIndex, memoryIndex: 0));
    _scheduleViewRecord(state.currentMemory.id);
  }

  void _onPausedToggled(PausedToggled event, Emitter<MemoryViewerState> emit) {
    if (event.paused == state.isPaused) return;
    emit(state.copyWith(isPaused: event.paused));
  }

  Future<void> _onViewRecorded(
    ViewRecorded event,
    Emitter<MemoryViewerState> emit,
  ) async {
    if (_recordedMemoryIds.contains(event.memoryId)) return;
    _recordedMemoryIds.add(event.memoryId);
    try {
      await _repo.recordView(event.memoryId);
    } on MemoryExpiredException {
      add(MemoryDeletedLocally(event.memoryId));
    } on MemoryException catch (e) {
      log('memory: recordView failed for ${event.memoryId}: ${e.message}');
    }
  }

  void _onMemoryDeletedLocally(
    MemoryDeletedLocally event,
    Emitter<MemoryViewerState> emit,
  ) {
    final s = state;
    final currentBucket = s.currentBucket;
    final filteredMemories = currentBucket.memories
        .where((m) => m.id != event.memoryId)
        .toList(growable: false);

    if (filteredMemories.isEmpty) {
      _tray.add(
        TrayBucketRemoved(
          ownerType: currentBucket.owner.type,
          ownerId: currentBucket.owner.id,
        ),
      );
      final filteredBuckets = [...s.buckets]..removeAt(s.bucketIndex);
      if (filteredBuckets.isEmpty) {
        emit(s.copyWith(status: MemoryViewerStatus.shouldClose));
        return;
      }
      final newBucketIndex = s.bucketIndex.clamp(0, filteredBuckets.length - 1);
      emit(
        s.copyWith(
          buckets: filteredBuckets,
          bucketIndex: newBucketIndex,
          memoryIndex: 0,
        ),
      );
      _scheduleViewRecord(state.currentMemory.id);
      return;
    }

    final updatedBucket = MemoryTrayBucket(
      owner: currentBucket.owner,
      memories: filteredMemories,
      hasUnwatched: currentBucket.hasUnwatched,
    );
    final updatedBuckets = [...s.buckets];
    updatedBuckets[s.bucketIndex] = updatedBucket;
    final newMemoryIndex = s.memoryIndex.clamp(0, filteredMemories.length - 1);
    emit(
      s.copyWith(
        buckets: updatedBuckets,
        memoryIndex: newMemoryIndex,
      ),
    );
  }

  void _onClosed(ViewerClosed event, Emitter<MemoryViewerState> emit) {
    _viewDebounce?.cancel();
    if (_recordedMemoryIds.isNotEmpty) {
      _tray.add(
        BucketWatchedLocally(
          ownerType: state.currentBucket.owner.type,
          ownerId: state.currentBucket.owner.id,
        ),
      );
    }
    emit(state.copyWith(status: MemoryViewerStatus.closed));
  }

  void _scheduleViewRecord(String memoryId) {
    _viewDebounce?.cancel();
    _viewDebounce = Timer(_viewRecordingDelay, () {
      add(ViewRecorded(memoryId));
    });
  }
}
