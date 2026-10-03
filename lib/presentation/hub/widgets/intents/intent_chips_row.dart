import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/intent_response.dart';
import 'package:hangout/presentation/hub/widgets/intents/intent_chip.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class IntentChipsRow extends StatelessWidget {
  final List<IntentResponse> intents;

  final String? selectedCode;
  final ValueChanged<String> onSelect;

  const IntentChipsRow({
    super.key,
    required this.intents,
    required this.selectedCode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        child: Wrap(
          runSpacing: 0,
          spacing: 0,
          children: List.generate(
            intents.length,
            (i) {
              final intent = intents[i];
              return IntentChip(
                intent: intent,
                selected: intent.code == selectedCode,
                onTap: () => onSelect(intent.code),
              );
            },
          ),
        ),
      )
    );
  }
}

class IntentChipsLoadingRow extends StatelessWidget {
  const IntentChipsLoadingRow({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: 5,
        clipBehavior: Clip.none,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, _) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Shimmer(
              duration: const Duration(milliseconds: 1400),
              color: c.onSurface.withValues(alpha: 0.06),
              colorOpacity: 0.5,
              child: Container(
                width: 80,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: c.border, width: 1),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
