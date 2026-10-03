import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';

Future<void> showMemoryMetricsSheet(
  BuildContext context, {
  required String venueId,
  required String memoryId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MetricsSheet(venueId: venueId, memoryId: memoryId),
  );
}

class _MetricsSheet extends StatefulWidget {
  final String venueId;
  final String memoryId;
  const _MetricsSheet({required this.venueId, required this.memoryId});

  @override
  State<_MetricsSheet> createState() => _MetricsSheetState();
}

class _MetricsSheetState extends State<_MetricsSheet> {
  late final MemoryRepository _repo = serviceLocator.get<MemoryRepository>();

  MemoryMetricsResponse? _metrics;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final metrics =
          await _repo.getVenueMetrics(widget.venueId, widget.memoryId);
      if (!mounted) return;
      setState(() {
        _metrics = metrics;
        _loading = false;
      });
    } on MemoryException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: c.onSurfaceDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'إحصائيات القصة',
              style: TextStyle(
                color: c.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 14),
            _body(),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    final c = context.c;
    if (_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.onSurface),
        ),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          _error!,
          style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }
    final m = _metrics!;
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _StatTile(
          icon: TablerIcons.eye,
          value: m.impressions,
          label: 'مشاهدات',
        ),
        _StatTile(
          icon: TablerIcons.users,
          value: m.uniqueViewers,
          label: 'مشاهدون فريدون',
        ),
        _StatTile(
          icon: TablerIcons.heart,
          value: m.reactions,
          label: 'تفاعلات',
        ),
        _StatTile(
          icon: TablerIcons.chart_bar,
          value: m.engagementResponses,
          label: 'ردود',
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final int value;
  final String label;
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: c.onSurface.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: c.onSurfaceSecondary, size: 22),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatCount(value),
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                label,
                style: TextStyle(color: c.onSurfaceSecondary, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCount(int v) {
    if (v < 1000) return '$v';
    if (v < 1_000_000) return '${(v / 1000).toStringAsFixed(1)}k';
    return '${(v / 1_000_000).toStringAsFixed(1)}m';
  }
}
