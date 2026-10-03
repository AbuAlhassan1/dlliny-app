import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

part 'theme_event.dart';
part 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  static const _prefKey = 'theme_mode';
  static const _storage = FlutterSecureStorage();

  ThemeMode themeMode = ThemeMode.system;

  ThemeBloc() : super(ThemeInitial()) {
    on<ThemeModeChanged>(_onThemeModeChanged);
    on<ThemeSwitchEvent>(_onThemeSwitchEvent);
    _restorePersistedMode();
  }

  Future<void> _onThemeModeChanged(
    ThemeModeChanged event,
    Emitter<ThemeState> emit,
  ) async {
    if (event.mode == themeMode && state is ThemeModeReady) return;
    themeMode = event.mode;
    emit(ThemeModeReady(themeMode: themeMode));
    try {
      await _storage.write(key: _prefKey, value: event.mode.name);
    } catch (e) {
      dev.log('ThemeBloc: failed to persist theme mode: $e');
    }
  }

  Future<void> _onThemeSwitchEvent(
    ThemeSwitchEvent event,
    Emitter<ThemeState> emit,
  ) async {
    final next = themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    add(ThemeModeChanged(next));
  }

  Future<void> _restorePersistedMode() async {
    String? stored;
    try {
      stored = await _storage.read(key: _prefKey);
    } catch (e) {
      dev.log('ThemeBloc: failed to read persisted theme mode: $e');
      return;
    }
    if (stored == null) return;
    final mode =
        ThemeMode.values.where((m) => m.name == stored).firstOrNull;
    if (mode == null || mode == themeMode) return;
    add(ThemeModeChanged(mode));
  }
}
