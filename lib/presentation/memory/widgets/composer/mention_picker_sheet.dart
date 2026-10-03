import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/search_response.dart';

class MentionPickResult {
  final MemoryMentionType type;
  final String id;
  final String label;
  final String? avatarUrl;

  const MentionPickResult({
    required this.type,
    required this.id,
    required this.label,
    this.avatarUrl,
  });
}

Future<MentionPickResult?> showMentionPicker(BuildContext context) {
  return showModalBottomSheet<MentionPickResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.85,
      child: _MentionPickerBody(),
    ),
  );
}

class _MentionPickerBody extends StatefulWidget {
  const _MentionPickerBody();

  @override
  State<_MentionPickerBody> createState() => _MentionPickerBodyState();
}

class _MentionPickerBodyState extends State<_MentionPickerBody> {
  static const Duration _debounce = Duration(milliseconds: 300);

  final TextEditingController _controller = TextEditingController();
  late final ApiService _api = serviceLocator.get<ApiService>();

  Timer? _debounceTimer;

  int _requestSeq = 0;

  SearchResultResponse? _results;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.removeListener(_onQueryChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounceTimer?.cancel();
    final q = _controller.text.trim();
    if (q.length < 2) {
      setState(() {
        _results = null;
        _loading = false;
      });
      return;
    }
    _debounceTimer = Timer(_debounce, () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    final seq = ++_requestSeq;
    setState(() => _loading = true);
    try {
      final response = await _api.search(q, limit: 20);
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _results = response.data;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || seq != _requestSeq) return;
      setState(() {
        _results = const SearchResultResponse(venues: [], users: []);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
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
              child: _SearchField(controller: _controller),
            ),
            Expanded(child: _ResultsList(results: _results, loading: _loading)),
          ],
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  const _SearchField({required this.controller});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.search, color: c.onSurfaceSecondary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: true,
              cursorColor: c.onSurface,
              style: TextStyle(color: c.onSurface, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'ابحث عن مستخدم أو مكان…',
                hintStyle: TextStyle(color: c.onSurfaceMuted, fontSize: 14),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultsList extends StatelessWidget {
  final SearchResultResponse? results;
  final bool loading;
  const _ResultsList({required this.results, required this.loading});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (loading && results == null) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: c.onSurface),
        ),
      );
    }
    final r = results;
    if (r == null) {
      return Center(
        child: Text(
          'اكتب حرفين على الأقل للبحث',
          style: TextStyle(color: c.onSurfaceMuted, fontSize: 13),
        ),
      );
    }
    if (r.users.isEmpty && r.venues.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج',
          style: TextStyle(color: c.onSurfaceMuted, fontSize: 13),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        for (final u in r.users)
          _UserTile(user: u),
        for (final v in r.venues)
          _VenueTile(venue: v),
      ],
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserSearchResultDto user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return _Tile(
      avatar: user.avatarUrl,
      fallbackIcon: TablerIcons.user,
      title: user.displayName ?? user.username,
      subtitle: '@${user.username}',
      onTap: () => Navigator.of(context).pop(
        MentionPickResult(
          type: MemoryMentionType.user,
          id: user.id,
          label: '@${user.username}',
          avatarUrl: user.avatarUrl,
        ),
      ),
    );
  }
}

class _VenueTile extends StatelessWidget {
  final VenueSearchResultDto venue;
  const _VenueTile({required this.venue});

  @override
  Widget build(BuildContext context) {
    final name = venue.nameAr.isNotEmpty ? venue.nameAr : venue.nameEn;
    return _Tile(
      avatar: null,
      fallbackIcon: TablerIcons.map_pin,
      title: name,
      subtitle: venue.district,
      onTap: () => Navigator.of(context).pop(
        MentionPickResult(
          type: MemoryMentionType.venue,
          id: venue.id,
          label: '@$name',
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String? avatar;
  final IconData fallbackIcon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _Tile({
    required this.avatar,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: ClipOval(
                  child: avatar != null && avatar!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: avatar!,
                          fit: BoxFit.cover,
                          memCacheWidth: 100,
                          errorWidget: (_, _, _) => _IconFallback(
                            icon: fallbackIcon,
                          ),
                        )
                      : _IconFallback(icon: fallbackIcon),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.c.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.c.onSurfaceSecondary,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconFallback extends StatelessWidget {
  final IconData icon;
  const _IconFallback({required this.icon});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ColoredBox(
      color: c.divider,
      child: Icon(icon, color: c.onSurfaceSecondary, size: 20),
    );
  }
}
