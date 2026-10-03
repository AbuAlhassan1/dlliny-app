import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'tabs_event.dart';
part 'tabs_state.dart';

class TabsBloc extends Bloc<TabsEvent, TabsState> {
  TabsBloc() : super(TabsInitial()) {
    on<TabsEvent>((event, emit) {});

    on<SwitchTab>((event, emit) {
      animateToTab(event.index);
      emit(TabSelected());
      HapticFeedback.heavyImpact();
    });
    on<TabRetapped>((event, emit) {
      _retapTick++;
      emit(TabRetappedState(index: event.index, tick: _retapTick));
      HapticFeedback.selectionClick();
    });
    on<TabControllerListener>((event, emit) {
      emit(TabSelected());
      tabController.offset == 0 ||
              tabController.offset == 1 ||
              tabController.offset == 2
          ? HapticFeedback.heavyImpact()
          : null;
    });
  }

  late TabController tabController;
  late PageController pageController = PageController(initialPage: 1);

  int _retapTick = 0;

  void setTabController(TabController controller) {
    tabController = controller;
  }

  void animateToTab(int index) {
    tabController.animateTo(index);
  }
}
