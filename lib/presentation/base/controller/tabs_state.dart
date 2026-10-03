part of 'tabs_bloc.dart';

@immutable
sealed class TabsState {}

final class TabsInitial extends TabsState {}
final class TabSelected extends TabsState {}

final class TabRetappedState extends TabsState {
  final int index;
  final int tick;
  TabRetappedState({required this.index, required this.tick});
}
