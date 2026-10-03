part of 'memory_viewer_bloc.dart';

enum MemoryViewerStatus {
  ready,

  shouldClose,

  closed,
}

class MemoryViewerState {
  final List<MemoryTrayBucket> buckets;
  final int bucketIndex;
  final int memoryIndex;
  final bool isPaused;
  final MemoryViewerStatus status;

  final Map<String, String?> reactionOverrides;

  const MemoryViewerState({
    required this.buckets,
    required this.bucketIndex,
    required this.memoryIndex,
    this.isPaused = false,
    this.status = MemoryViewerStatus.ready,
    this.reactionOverrides = const {},
  });

  MemoryTrayBucket get currentBucket => buckets[bucketIndex];
  MemoryResponse get currentMemory => currentBucket.memories[memoryIndex];

  bool get isLastMemoryInBucket =>
      memoryIndex >= currentBucket.memories.length - 1;
  bool get isFirstMemoryInBucket => memoryIndex == 0;

  String? effectiveMyEmojiFor(MemoryResponse memory) {
    if (reactionOverrides.containsKey(memory.id)) {
      return reactionOverrides[memory.id];
    }
    return memory.reactions.myEmoji;
  }

  MemoryViewerState copyWith({
    List<MemoryTrayBucket>? buckets,
    int? bucketIndex,
    int? memoryIndex,
    bool? isPaused,
    MemoryViewerStatus? status,
    Map<String, String?>? reactionOverrides,
  }) {
    return MemoryViewerState(
      buckets: buckets ?? this.buckets,
      bucketIndex: bucketIndex ?? this.bucketIndex,
      memoryIndex: memoryIndex ?? this.memoryIndex,
      isPaused: isPaused ?? this.isPaused,
      status: status ?? this.status,
      reactionOverrides: reactionOverrides ?? this.reactionOverrides,
    );
  }
}
