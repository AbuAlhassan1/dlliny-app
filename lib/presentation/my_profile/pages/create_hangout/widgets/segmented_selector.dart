import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class SegmentOption<T> {
  final T value;
  final String label;
  const SegmentOption({required this.value, required this.label});
}

class SegmentedSelector<T> extends StatelessWidget {
  final List<SegmentOption<T>> options;
  final T selected;
  final void Function(T value) onChanged;

  const SegmentedSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: options.map((opt) {
        final isSelected = opt.value == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(opt.value),
            child: Container(
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? c.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? c.primary : c.border,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  opt.label,
                  style: TextStyle(
                    color: isSelected ? c.onPrimary : c.onSurface,
                    fontSize: 12,
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
