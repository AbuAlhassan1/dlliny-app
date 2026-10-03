import 'package:flutter/material.dart';

class PermissionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const PermissionChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.78),
      shape: const StadiumBorder(
        side: BorderSide(color: Colors.white24, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const StadiumBorder(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: "IBMPlexSansArabic",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
