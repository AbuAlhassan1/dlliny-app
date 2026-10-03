import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/presentation/explore/widgets/memory_card.dart';
import 'package:hangout/presentation/memory/bloc/memory_tray/memory_tray_bloc.dart';
import 'package:hangout/presentation/memory/screens/photo_memory_composer_page.dart';
import 'package:hangout/presentation/memory/screens/text_card_composer_page.dart';
import 'package:hangout/presentation/memory/screens/video_memory_composer_page.dart';
import 'package:hangout/presentation/memory/widgets/memory_source_picker_sheet.dart';

class MemoriesSection extends StatelessWidget {
  const MemoriesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: serviceLocator.get<MemoryTrayBloc>(),
      child: const _MemoriesTray(),
    );
  }
}

class _MemoriesTray extends StatelessWidget {
  const _MemoriesTray();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: BlocBuilder<MemoryTrayBloc, MemoryTrayState>(
        builder: (context, state) {
          final buckets = state.buckets;
          final itemCount = state.isFirstLoad
              ? 1 + 3
              : 1 + buckets.length;

          return ListView.builder(
            padding: const EdgeInsetsDirectional.only(start: 15),
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              if (index == 0) return const _CreateMemoryTile();
              if (state.isFirstLoad) return const _PlaceholderTile();
              final bucket = buckets[index - 1];
              return MemoryCard(bucket: bucket);
            },
          );
        },
      ),
    );
  }
}

class _CreateMemoryTile extends StatelessWidget {
  const _CreateMemoryTile();

  Future<void> _openComposer(BuildContext context) async {
    final choice = await showMemorySourcePicker(context);
    if (choice == null || !context.mounted) return;
    final navigator = Navigator.of(context);
    switch (choice) {
      case MemorySourcePhoto(:final file):
        navigator.push(
          MaterialPageRoute(
            builder: (_) => PhotoMemoryComposerPage(photo: file),
          ),
        );
      case MemorySourceVideo(:final file):
        navigator.push(
          MaterialPageRoute(
            builder: (_) => VideoMemoryComposerPage(video: file),
          ),
        );
      case MemorySourceTextCard():
        navigator.push(
          MaterialPageRoute(
            builder: (_) => const TextCardComposerPage(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).appBarTheme.foregroundColor!;
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 15),
      child: DottedBorder(
        options: RoundedRectDottedBorderOptions(
          color: color,
          radius: const Radius.circular(13),
          strokeWidth: 1,
          dashPattern: const [10, 5],
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: InkWell(
            onTap: () => _openComposer(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 72,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withAlpha(100), width: 1),
              ),
              child: Center(
                child: Icon(Icons.add, color: color, size: 18),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 15),
      width: 72,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
