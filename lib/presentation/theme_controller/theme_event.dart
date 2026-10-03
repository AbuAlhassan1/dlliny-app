part of 'theme_bloc.dart';

@immutable
sealed class ThemeEvent {}

class ThemeModeChanged extends ThemeEvent {
  final ThemeMode mode;
  ThemeModeChanged(this.mode);
}

class ThemeSwitchEvent extends ThemeEvent {}
