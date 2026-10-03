part of 'memory_tray_bloc.dart';

enum MemoryTrayStatus {
  initial,
  loading,
  refreshing,
  success,
  failure,
}

class MemoryTrayState {
  final List<MemoryTrayBucket> buckets;
  final MemoryTrayStatus status;
  final String? errorMessage;

  const MemoryTrayState({
    this.buckets = const [],
    this.status = MemoryTrayStatus.initial,
    this.errorMessage,
  });

  bool get isLoading => status == MemoryTrayStatus.loading;
  bool get isRefreshing => status == MemoryTrayStatus.refreshing;
  bool get hasFailed => status == MemoryTrayStatus.failure;

  bool get isFirstLoad => status == MemoryTrayStatus.loading && buckets.isEmpty;

  MemoryTrayState copyWith({
    List<MemoryTrayBucket>? buckets,
    MemoryTrayStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return MemoryTrayState(
      buckets: buckets ?? this.buckets,
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
