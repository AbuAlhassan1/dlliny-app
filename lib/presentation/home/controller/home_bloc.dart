import 'dart:developer' as dev;

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'home_event.dart';
part 'home_state.dart';

enum HomeFeedType { following, forYou }

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  static const _prefKey = 'home_feed_type';
  static const _storage = FlutterSecureStorage();

  HomeFeedType currentFeedType = HomeFeedType.forYou;

  HomeBloc() : super(HomeInitial()) {
    on<HomeFeedTypeChanged>(_onFeedTypeChanged);
    _restorePersistedFeedType();
  }

  Future<void> _onFeedTypeChanged(
    HomeFeedTypeChanged event,
    Emitter<HomeState> emit,
  ) async {
    if (event.feedType == currentFeedType &&
        state is HomeFeedTypeReady) {
      return;
    }
    currentFeedType = event.feedType;
    emit(HomeFeedTypeReady(event.feedType));
    try {
      await _storage.write(key: _prefKey, value: event.feedType.name);
    } catch (e) {
      dev.log('HomeBloc: failed to persist feed type: $e');
    }
  }

  Future<void> _restorePersistedFeedType() async {
    String? stored;
    try {
      stored = await _storage.read(key: _prefKey);
    } catch (e) {
      dev.log('HomeBloc: failed to read persisted feed type: $e');
      return;
    }
    if (stored == null) return;
    final type = HomeFeedType.values
        .where((t) => t.name == stored)
        .firstOrNull;
    if (type == null || type == currentFeedType) return;
    add(HomeFeedTypeChanged(type));
  }
}
