import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/errors/memory_exceptions.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/memory_page.dart';

class MentionsInboxTab extends StatefulWidget {
  const MentionsInboxTab({super.key});

  @override
  State<MentionsInboxTab> createState() => _MentionsInboxTabState();
}

class _MentionsInboxTabState extends State<MentionsInboxTab>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 20;
  static const double _loadMoreThreshold = 200;

  final ScrollController _scroll = ScrollController();
  late final MemoryRepository _repo = serviceLocator.get<MemoryRepository>();

  final List<MemoryResponse> _memories = [];
  int _nextPage = 0;
  bool _reachedEnd = false;
  bool _loadingFirst = true;
  bool _loadingMore = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

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

  Future<void> _refresh() async {
    setState(() {
      _memories.clear();
      _nextPage = 0;
      _reachedEnd = false;
      _loadingFirst = true;
      _loadingMore = false;
      _error = null;
    });
    await _loadNext();
  }

  Future<void> _loadNext() async {
    if (_loadingMore || _reachedEnd) return;
    setState(() => _loadingMore = true);
    try {
      final PagedResponse<MemoryResponse> page = await _repo.getMyMemoryMentions(
        page: _nextPage,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _memories.addAll(page.content);
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

  void _open(MemoryResponse memory) {
    final bucket = MemoryTrayBucket(
      owner: memory.owner,
      memories: [memory],
      hasUnwatched: !memory.viewedByMe,
    );
    context.pushTransparentRoute(
      MemoryPage(buckets: [bucket], initialBucketIndex: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.c;
    return RefreshIndicator(
      onRefresh: _refresh,
      color: c.onSurface,
      child: _body(),
    );
  }

  Widget _body() {
    final c = context.c;
    if (_loadingFirst) {
      return Center(
        child: CircularProgressIndicator(
          color: c.onSurface,
          strokeWidth: 1,
        ),
      );
    }
    if (_error != null && _memories.isEmpty) {
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
    if (_memories.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 200),
          Center(
            child: Text(
              'لم يُذكر اسمك في أي قصة بعد',
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      controller: _scroll,
      padding: EdgeInsets.zero,
      itemCount: _memories.length + (_reachedEnd ? 0 : 1),
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: c.border,
      ),
      itemBuilder: (context, i) {
        if (i >= _memories.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
        return _MentionRow(memory: _memories[i], onTap: _open);
      },
    );
  }
}

class _MentionRow extends StatelessWidget {
  final MemoryResponse memory;
  final void Function(MemoryResponse) onTap;

  const _MentionRow({required this.memory, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: () => onTap(memory),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _Thumbnail(memory: memory),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      _OwnerAvatar(url: memory.owner.avatarUrl),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          memory.owner.displayName ?? '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'ذكرك في قصة · ${_relative(memory.createdAt)}',
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
            Icon(
              TablerIcons.chevron_left,
              color: c.onSurfaceDisabled,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final MemoryResponse memory;
  const _Thumbnail({required this.memory});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 64,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    switch (memory.contentType) {
      case MemoryContentType.photo:
        final url = memory.mediaThumbnailUrl ?? memory.mediaUrl;
        if (url == null || url.isEmpty) return const _BlankCover();
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          memCacheWidth: 160,
          errorWidget: (_, _, _) => const _BlankCover(),
        );
      case MemoryContentType.video:
        final poster = memory.mediaThumbnailUrl;
        if (poster == null || poster.isEmpty) return const _BlankCover();
        return CachedNetworkImage(
          imageUrl: poster,
          fit: BoxFit.cover,
          memCacheWidth: 160,
          errorWidget: (_, _, _) => const _BlankCover(),
        );
      case MemoryContentType.text:
        final c = context.c;
        final bg = _parseHex(memory.backgroundColor, c.mediaSurface);
        final fg = _parseHex(memory.textColor, c.onMediaSurface);
        return Container(
          color: bg,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(4),
          child: Text(
            memory.textContent ?? '',
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: fg,
              fontSize: 9,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
        );
    }
  }
}

class _BlankCover extends StatelessWidget {
  const _BlankCover();
  @override
  Widget build(BuildContext context) => ColoredBox(color: context.c.divider);
}

class _OwnerAvatar extends StatelessWidget {
  final String? url;
  const _OwnerAvatar({required this.url});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: ClipOval(
        child: (url != null && url!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: 64,
                errorWidget: (_, _, _) => const _AvatarFallback(),
              )
            : const _AvatarFallback(),
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
        size: 12,
      ),
    );
  }
}

Color _parseHex(String? hex, Color fallback) {
  if (hex == null) return fallback;
  final cleaned = hex.replaceFirst('#', '');
  final value = int.tryParse(cleaned, radix: 16);
  if (value == null) return fallback;
  return Color(cleaned.length == 6 ? (0xFF000000 | value) : value);
}

String _relative(String? iso) {
  if (iso == null) return '';
  final created = DateTime.tryParse(iso);
  if (created == null) return '';
  final delta = DateTime.now().toUtc().difference(created.toUtc());
  if (delta.inMinutes < 1) return 'الآن';
  if (delta.inMinutes < 60) return '${delta.inMinutes}د';
  return '${delta.inHours}س';
}
