import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/response/engagement_results_response.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';

Future<void> showEngagementResultsSheet(
  BuildContext context, {
  required String memoryId,
  required List<dynamic> originalOptions,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.9,
      child: _ResultsBody(
        memoryId: memoryId,
        originalOptions: originalOptions,
      ),
    ),
  );
}

class _ResultsBody extends StatefulWidget {
  final String memoryId;
  final List<dynamic> originalOptions;

  const _ResultsBody({
    required this.memoryId,
    required this.originalOptions,
  });

  @override
  State<_ResultsBody> createState() => _ResultsBodyState();
}

class _ResultsBodyState extends State<_ResultsBody> {
  static const int _pageSize = 50;
  static const double _loadMoreThreshold = 200;

  final ScrollController _scroll = ScrollController();
  late final MemoryRepository _repo = serviceLocator.get<MemoryRepository>();

  EngagementResultsResponse? _firstPage;
  final List<EngagementRespondent> _allResponses = [];
  int _nextPage = 0;
  bool _reachedEnd = false;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _loadNext();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_reachedEnd || _loadingMore || _loadingFirst) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _loadNext();
    }
  }

  Future<void> _loadNext() async {
    if (_loadingMore || _reachedEnd) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _repo.getEngagementResults(
        widget.memoryId,
        page: _nextPage,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _firstPage ??= page;
        _allResponses.addAll(page.responses.content);
        _reachedEnd = page.responses.last;
        _nextPage += 1;
        _loadingFirst = false;
        _loadingMore = false;
      });
    } on MemoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loadingFirst = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: c.onSurfaceDisabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                Icon(TablerIcons.chart_bar, color: c.onSurface, size: 18),
                const SizedBox(width: 8),
                Text(
                  _headerLabel(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  String _headerLabel() {
    final total = _firstPage?.totalResponses;
    if (total == null) return 'النتائج';
    return 'النتائج ($total)';
  }

  Widget _body() {
    final c = context.c;
    if (_loadingFirst) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.onSurface),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.onSurfaceMuted, fontSize: 13),
          ),
        ),
      );
    }
    final first = _firstPage!;
    if (first.totalResponses == 0) {
      return Center(
        child: Text(
          'لا توجد ردود بعد',
          style: TextStyle(color: c.onSurfaceMuted, fontSize: 13),
        ),
      );
    }
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _AggregateSection(
          aggregate: first,
          originalOptions: widget.originalOptions,
        ),
        if (_allResponses.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Text(
              'الردود',
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final r in _allResponses)
            _RespondentTile(
              respondent: r,
              type: first.type,
              originalOptions: widget.originalOptions,
            ),
          if (!_reachedEnd)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: c.onSurfaceMuted,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _AggregateSection extends StatelessWidget {
  final EngagementResultsResponse aggregate;
  final List<dynamic> originalOptions;

  const _AggregateSection({
    required this.aggregate,
    required this.originalOptions,
  });

  @override
  Widget build(BuildContext context) {
    switch (aggregate.type) {
      case MemoryEngagementType.poll:
        return _PollOrQuizAggregate(
          aggregate: aggregate,
          originalOptions: originalOptions,
          showCorrect: false,
        );
      case MemoryEngagementType.quiz:
        return _PollOrQuizAggregate(
          aggregate: aggregate,
          originalOptions: originalOptions,
          showCorrect: true,
        );
      case MemoryEngagementType.slider:
        return _SliderAggregate(aggregate: aggregate);
      case MemoryEngagementType.question:
        return const SizedBox.shrink();
    }
  }
}

class _PollOrQuizAggregate extends StatelessWidget {
  final EngagementResultsResponse aggregate;
  final List<dynamic> originalOptions;
  final bool showCorrect;

  const _PollOrQuizAggregate({
    required this.aggregate,
    required this.originalOptions,
    required this.showCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final counts = aggregate.optionCounts;
    if (counts == null || counts.isEmpty) return const SizedBox.shrink();
    final sorted = [...counts]
      ..sort((a, b) => b.percentage.compareTo(a.percentage));
    final correctIndex = aggregate.correctOptionIndex;

    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showCorrect && correctIndex != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${aggregate.correctCount ?? 0} من ${aggregate.totalResponses}'
                ' أجابوا بشكل صحيح',
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          for (final bucket in sorted)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _OptionBar(
                label: _labelFor(bucket.optionIndex),
                percentage: bucket.percentage,
                count: bucket.count,
                isCorrect: showCorrect && bucket.optionIndex == correctIndex,
              ),
            ),
        ],
      ),
    );
  }

  String _labelFor(int index) {
    if (index < 0 || index >= originalOptions.length) {
      return 'خيار ${index + 1}';
    }
    return originalOptions[index]?.toString() ?? 'خيار ${index + 1}';
  }
}

class _OptionBar extends StatelessWidget {
  final String label;
  final double percentage;
  final int count;
  final bool isCorrect;

  const _OptionBar({
    required this.label,
    required this.percentage,
    required this.count,
    required this.isCorrect,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return LayoutBuilder(
      builder: (context, constraints) {
        final pct = (percentage / 100).clamp(0.0, 1.0);
        return Stack(
          alignment: Alignment.centerLeft,
          children: [
            Container(
              height: 36,
              decoration: BoxDecoration(
                color: c.border,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: isCorrect
                      ? const Color(0xFF34C759)
                      : c.onSurface.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCorrect ? Colors.black : c.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${percentage.toStringAsFixed(0)}% · $count',
                    style: TextStyle(
                      color:
                          isCorrect ? Colors.black87 : c.onSurfaceSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SliderAggregate extends StatelessWidget {
  final EngagementResultsResponse aggregate;
  const _SliderAggregate({required this.aggregate});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final avg = aggregate.sliderAverage;
    final dist = aggregate.sliderDistribution;
    if (avg == null || dist == null) return const SizedBox.shrink();
    final maxBucket = dist.fold<int>(0, (m, v) => v > m ? v : m);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'المتوسط: ${avg.toStringAsFixed(1)}%',
              style: TextStyle(
                color: c.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < dist.length; i++) ...[
                  Expanded(
                    child: _HistogramBucket(
                      count: dist[i],
                      maxCount: maxBucket,
                    ),
                  ),
                  if (i < dist.length - 1) const SizedBox(width: 3),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text('0%',
                  style: TextStyle(color: c.onSurfaceMuted, fontSize: 10)),
              const Spacer(),
              Text('100%',
                  style: TextStyle(color: c.onSurfaceMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistogramBucket extends StatelessWidget {
  final int count;
  final int maxCount;
  const _HistogramBucket({required this.count, required this.maxCount});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final ratio = maxCount == 0 ? 0.0 : count / maxCount;
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: c.border,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        FractionallySizedBox(
          heightFactor: ratio,
          child: Container(
            decoration: BoxDecoration(
              color: c.onSurface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ],
    );
  }
}

class _RespondentTile extends StatelessWidget {
  final EngagementRespondent respondent;
  final MemoryEngagementType type;
  final List<dynamic> originalOptions;

  const _RespondentTile({
    required this.respondent,
    required this.type,
    required this.originalOptions,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: ClipOval(
              child: (respondent.avatarUrl != null &&
                      respondent.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: respondent.avatarUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 96,
                      errorWidget: (_, _, _) => const _AvatarFallback(),
                    )
                  : const _AvatarFallback(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  respondent.displayName ?? respondent.username ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _responseSummary(),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _responseSummary() {
    final r = respondent.response;
    switch (type) {
      case MemoryEngagementType.poll:
      case MemoryEngagementType.quiz:
        final idx = (r['optionIndex'] as num?)?.toInt() ?? -1;
        if (idx < 0 || idx >= originalOptions.length) return 'خيار $idx';
        return originalOptions[idx]?.toString() ?? 'خيار $idx';
      case MemoryEngagementType.slider:
        final v = (r['value'] as num?)?.toInt() ?? 0;
        return '$v%';
      case MemoryEngagementType.question:
        return (r['text'] as String?) ?? '';
    }
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ColoredBox(
      color: c.surfaceMuted,
      child: Icon(TablerIcons.user, color: c.onSurfaceSecondary, size: 18),
    );
  }
}
