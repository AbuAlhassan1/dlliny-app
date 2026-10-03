import 'package:flutter/widgets.dart';

class QuickSheetController {
  final AnimationController animation;

  double dragRange = 500;

  QuickSheetController(this.animation);

  bool get isOpen => animation.value > 0.5;

  Future<void> open() => animation.animateTo(
        1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );

  Future<void> close() => animation.animateTo(
        0,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );

  void toggle() => isOpen ? close() : open();

  void onDragUpdate(double primaryDelta) {
    if (dragRange <= 0) return;
    animation.value =
        (animation.value - primaryDelta / dragRange).clamp(0.0, 1.0);
  }

  void onDragEnd(double velocity) {
    if (velocity < -320) {
      open();
    } else if (velocity > 320) {
      close();
    } else {
      animation.value >= 0.5 ? open() : close();
    }
  }
}
