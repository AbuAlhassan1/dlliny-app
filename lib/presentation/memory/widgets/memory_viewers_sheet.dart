import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';

Future<void> showMemoryViewersSheet(
  BuildContext context, {
  required String memoryId,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: _ViewersBody(memoryId: memoryId),
    ),
  );
}

class _ViewersBody extends StatefulWidget {
  final String memoryId;
  const _ViewersBody({required this.memoryId});

  @override
  State<_ViewersBody> createState() => _ViewersBodyState();
}

class _ViewersBodyState extends State<_ViewersBody> {
  static const int _pageSize = 50;
  static const double _loadMoreThreshold = 200;

  final ScrollController _scroll = ScrollController();
  late final MemoryRepository _repo = serviceLocator.get<MemoryRepository>();

  final List<MemoryViewerEntry> _viewers = [];
  int _nextPage = 0;
  bool _reachedEnd = false;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  int _total = 0;
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
    if (_reachedEnd || _loadingMore) return;
    final position = _scroll.position;
    if (position.pixels >= position.maxScrollExtent - _loadMoreThreshold) {
      _loadNext();
    }
  }

  Future<void> _loadNext() async {
    if (_loadingMore || _reachedEnd) return;
    final isFirst = _viewers.isEmpty;
    setState(() {
      if (isFirst) _loadingFirst = true;
      _loadingMore = true;
    });
    try {
      final PagedResponse<MemoryViewerEntry> page = await _repo.getMemoryViewers(
        widget.memoryId,
        page: _nextPage,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _viewers.addAll(page.content);
        _total = page.totalElements;
        _reachedEnd = page.last;
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                Icon(TablerIcons.eye, color: c.onSurface, size: 18),
                const SizedBox(width: 8),
                Text(
                  'المشاهدون ($_total)',
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
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
          ),
        ),
      );
    }
    if (_viewers.isEmpty) {
      return Center(
        child: Text(
          'لم يشاهد أحد بعد',
          style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
        ),
      );
    }
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: _viewers.length + (_reachedEnd ? 0 : 1),
      itemBuilder: (context, i) {
        if (i >= _viewers.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: c.onSurfaceSecondary,
                ),
              ),
            ),
          );
        }
        return _ViewerTile(viewer: _viewers[i]);
      },
    );
  }
}

class _ViewerTile extends StatelessWidget {
  final MemoryViewerEntry viewer;
  const _ViewerTile({required this.viewer});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: ClipOval(
              child: (viewer.avatarUrl != null && viewer.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: viewer.avatarUrl!,
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        viewer.displayName ?? viewer.username ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (viewer.verified)
                      Padding(
                        padding: const EdgeInsetsDirectional.only(start: 4),
                        child: Icon(
                          TablerIcons.rosette_discount_check,
                          color: c.success,
                          size: 14,
                        ),
                      ),
                  ],
                ),
                if (viewer.username != null && viewer.username!.isNotEmpty)
                  Text(
                    '@${viewer.username}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (viewer.viewCount > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: c.onSurface.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '×${viewer.viewCount}',
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  const _AvatarFallback();
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ColoredBox(
      color: c.divider,
      child: Icon(
        TablerIcons.user,
        color: c.onSurfaceSecondary,
        size: 18,
      ),
    );
  }
}
