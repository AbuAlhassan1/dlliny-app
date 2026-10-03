import 'package:flutter/material.dart';

class MemoryTapZones extends StatelessWidget {
  final VoidCallback onTapLeft;
  final VoidCallback onTapRight;
  final VoidCallback onLongPressStart;
  final VoidCallback onLongPressEnd;

  const MemoryTapZones({
    super.key,
    required this.onTapLeft,
    required this.onTapRight,
    required this.onLongPressStart,
    required this.onLongPressEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapLeft,
              onLongPressStart: (_) => onLongPressStart(),
              onLongPressEnd: (_) => onLongPressEnd(),
              child: const SizedBox.expand(),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTapRight,
              onLongPressStart: (_) => onLongPressStart(),
              onLongPressEnd: (_) => onLongPressEnd(),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}
