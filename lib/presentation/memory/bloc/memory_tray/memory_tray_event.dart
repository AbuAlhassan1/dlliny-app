part of 'memory_tray_bloc.dart';

sealed class MemoryTrayEvent {}

class TrayRequested extends MemoryTrayEvent {}

class TrayRefreshed extends MemoryTrayEvent {}

class BucketWatchedLocally extends MemoryTrayEvent {
  final MemoryOwnerType ownerType;
  final String ownerId;
  BucketWatchedLocally({required this.ownerType, required this.ownerId});
}

class TrayBucketRemoved extends MemoryTrayEvent {
  final MemoryOwnerType ownerType;
  final String ownerId;
  TrayBucketRemoved({required this.ownerType, required this.ownerId});
}
