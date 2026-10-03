part of 'memory_viewer_bloc.dart';

sealed class MemoryViewerEvent {}

class ViewerOpened extends MemoryViewerEvent {}

class NextMemory extends MemoryViewerEvent {}

class PreviousMemory extends MemoryViewerEvent {}

class BucketSwiped extends MemoryViewerEvent {
  final int bucketIndex;
  BucketSwiped(this.bucketIndex);
}

class PausedToggled extends MemoryViewerEvent {
  final bool paused;
  PausedToggled({required this.paused});
}

class ViewRecorded extends MemoryViewerEvent {
  final String memoryId;
  ViewRecorded(this.memoryId);
}

class MemoryDeletedLocally extends MemoryViewerEvent {
  final String memoryId;
  MemoryDeletedLocally(this.memoryId);
}

class ViewerClosed extends MemoryViewerEvent {}

class ReactionOverrideSet extends MemoryViewerEvent {
  final String memoryId;
  final String? emoji;
  ReactionOverrideSet({required this.memoryId, required this.emoji});
}
