import 'package:flutter/material.dart';

class SnappyPageScrollPhysics extends ScrollPhysics {
  const SnappyPageScrollPhysics({super.parent});

  @override
  SnappyPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return SnappyPageScrollPhysics(parent: buildParent(ancestor));
  }

  @override
  SpringDescription get spring {
    return const SpringDescription(
      mass: 0.8,
      stiffness: 270,
      damping: 30,
    );
  }
}