import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/bloc/memory_viewer/memory_viewer_bloc.dart';
import 'package:hangout/presentation/memory/widgets/memory_metrics_sheet.dart';
import 'package:hangout/presentation/memory/widgets/memory_viewers_sheet.dart';

Future<void> showMemoryOptionsSheet(
  BuildContext context, {
  required MemoryResponse memory,
}) {
  final viewerBloc = context.read<MemoryViewerBloc>();
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => _OptionsBody(
      memory: memory,
      viewerBloc: viewerBloc,
    ),
  );
}

class _OptionsBody extends StatelessWidget {
  final MemoryResponse memory;
  final MemoryViewerBloc viewerBloc;

  const _OptionsBody({required this.memory, required this.viewerBloc});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: c.onSurfaceDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (memory.mine) ..._ownTiles(context) else ..._otherTiles(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _ownTiles(BuildContext context) {
    final isVenue = memory.owner.type == MemoryOwnerType.venue;
    return [
      _OptionTile(
        icon: TablerIcons.users,
        label: 'المشاهدون',
        onTap: () {
          Navigator.of(context).pop();
          showMemoryViewersSheet(
            context,
            memoryId: memory.id,
          );
        },
      ),
      if (isVenue)
        _OptionTile(
          icon: TablerIcons.chart_bar,
          label: 'الإحصائيات',
          onTap: () {
            Navigator.of(context).pop();
            showMemoryMetricsSheet(
              context,
              venueId: memory.owner.id,
              memoryId: memory.id,
            );
          },
        ),
      _OptionTile(
        icon: TablerIcons.download,
        label: 'حفظ في المعرض',
        onTap: () {
          Navigator.of(context).pop();
          appToast.info('قريباً', body: 'حفظ القصة قيد التطوير');
        },
      ),
      Divider(color: context.c.divider, height: 16),
      _OptionTile(
        icon: TablerIcons.trash,
        label: 'حذف',
        destructive: true,
        onTap: () async {
          final navigator = Navigator.of(context);
          final confirmed = await _confirmDelete(context);
          if (confirmed != true) return;
          navigator.pop();
          await _runDelete();
        },
      ),
    ];
  }

  List<Widget> _otherTiles(BuildContext context) {
    return [
      _OptionTile(
        icon: TablerIcons.volume_off,
        label: 'كتم',
        onTap: () {
          Navigator.of(context).pop();
          appToast.info('قريباً', body: 'كتم المستخدمين قيد التطوير');
        },
      ),
      _OptionTile(
        icon: TablerIcons.flag,
        label: 'إبلاغ',
        onTap: () {
          Navigator.of(context).pop();
          appToast.info('قريباً', body: 'الإبلاغ سيُدمج لاحقاً');
        },
      ),
      _OptionTile(
        icon: TablerIcons.download,
        label: 'حفظ في المعرض',
        onTap: () {
          Navigator.of(context).pop();
          appToast.info('قريباً', body: 'حفظ القصة قيد التطوير');
        },
      ),
    ];
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final c = dialogContext.c;
        return AlertDialog(
          backgroundColor: c.surfaceElevated,
          title: Text(
            'حذف القصة؟',
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'لا يمكن التراجع عن هذا الإجراء.',
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(
                'إلغاء',
                style: TextStyle(color: c.onSurfaceSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: c.danger),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _runDelete() async {
    final repo = serviceLocator.get<MemoryRepository>();
    try {
      if (memory.owner.type == MemoryOwnerType.venue) {
        await repo.deleteVenueMemory(memory.owner.id, memory.id);
      } else {
        await repo.deleteMemory(memory.id);
      }
    } on MemoryException catch (e) {
      appToast.error(e.message);
      return;
    }
    viewerBloc.add(MemoryDeletedLocally(memory.id));
    appToast.success('تم حذف القصة');
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = destructive ? c.danger : c.onSurface;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
