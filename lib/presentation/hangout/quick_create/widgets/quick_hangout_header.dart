import 'package:flutter/material.dart';

class QuickHangoutHeader extends StatelessWidget {
  final VoidCallback onClose;

  const QuickHangoutHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onClose,
      child: Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
