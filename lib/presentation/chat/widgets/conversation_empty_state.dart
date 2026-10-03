import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class ConversationEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const ConversationEmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c.onSurfaceDisabled, size: 56),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: c.onSurfaceSecondary),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(color: c.onSurface),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
