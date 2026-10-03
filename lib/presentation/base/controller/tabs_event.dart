part of 'tabs_bloc.dart';

@immutable
sealed class TabsEvent {}

class SwitchTab extends TabsEvent {
  final int index;

  SwitchTab(this.index);
}

class TabRetapped extends TabsEvent {
  final int index;

  TabRetapped(this.index);
}

class TabControllerListener extends TabsEvent {}
