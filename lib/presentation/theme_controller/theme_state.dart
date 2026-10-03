part of 'theme_bloc.dart';

@immutable
sealed class ThemeState {}

final class ThemeInitial extends ThemeState {}

final class ThemeModeReady extends ThemeState {
  final ThemeMode themeMode;
  ThemeModeReady({required this.themeMode});
}
