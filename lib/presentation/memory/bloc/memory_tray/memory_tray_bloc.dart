import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';

part 'memory_tray_event.dart';
part 'memory_tray_state.dart';

class MemoryTrayBloc extends Bloc<MemoryTrayEvent, MemoryTrayState> {
  final MemoryRepository _repo;

  final Set<String> _watchedKeys = {};

  MemoryTrayBloc(this._repo) : super(const MemoryTrayState()) {
    on<TrayRequested>(_onRequested);
    on<TrayRefreshed>(_onRefreshed);
    on<BucketWatchedLocally>(_onBucketWatchedLocally);
    on<TrayBucketRemoved>(_onBucketRemoved);
  }

  String _keyFor(MemoryOwnerType type, String id) => '${type.name}-$id';

  List<MemoryTrayBucket> _applyOverrides(List<MemoryTrayBucket> buckets) {
    if (_watchedKeys.isEmpty) return buckets;
    return [
      for (final b in buckets)
        if (b.hasUnwatched &&
            _watchedKeys.contains(_keyFor(b.owner.type, b.owner.id)))
          MemoryTrayBucket(
            owner: b.owner,
            memories: b.memories,
            hasUnwatched: false,
          )
        else
          b,
    ];
  }

  Future<void> _onRequested(
    TrayRequested event,
    Emitter<MemoryTrayState> emit,
  ) async {
    if (state.status == MemoryTrayStatus.loading) return;
    emit(state.copyWith(status: MemoryTrayStatus.loading, clearError: true));
    try {
      final buckets = await _repo.getTray();
      emit(
        state.copyWith(
          buckets: _applyOverrides(buckets),
          status: MemoryTrayStatus.success,
          clearError: true,
        ),
      );
    } on MemoryException catch (e) {
      emit(
        state.copyWith(
          status: MemoryTrayStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  Future<void> _onRefreshed(
    TrayRefreshed event,
    Emitter<MemoryTrayState> emit,
  ) async {
    emit(state.copyWith(status: MemoryTrayStatus.refreshing, clearError: true));
    try {
      final buckets = await _repo.getTray();
      emit(
        state.copyWith(
          buckets: _applyOverrides(buckets),
          status: MemoryTrayStatus.success,
          clearError: true,
        ),
      );
    } on MemoryException catch (e) {
      emit(
        state.copyWith(
          status: MemoryTrayStatus.failure,
          errorMessage: e.message,
        ),
      );
    }
  }

  void _onBucketWatchedLocally(
    BucketWatchedLocally event,
    Emitter<MemoryTrayState> emit,
  ) {
    _watchedKeys.add(_keyFor(event.ownerType, event.ownerId));
    final updated = state.buckets.map((b) {
      if (b.owner.type == event.ownerType && b.owner.id == event.ownerId) {
        return MemoryTrayBucket(
          owner: b.owner,
          memories: b.memories,
          hasUnwatched: false,
        );
      }
      return b;
    }).toList(growable: false);
    emit(state.copyWith(buckets: updated));
  }

  void _onBucketRemoved(
    TrayBucketRemoved event,
    Emitter<MemoryTrayState> emit,
  ) {
    _watchedKeys.remove(_keyFor(event.ownerType, event.ownerId));
    final filtered = state.buckets
        .where(
          (b) => !(b.owner.type == event.ownerType && b.owner.id == event.ownerId),
        )
        .toList(growable: false);
    emit(state.copyWith(buckets: filtered));
  }
}
