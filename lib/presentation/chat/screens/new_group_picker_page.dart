import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/user_summary_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/screens/new_group_title_page.dart';

class NewGroupPickerPage extends StatefulWidget {
  const NewGroupPickerPage({super.key});

  static const int maxSelectable = 249;

  @override
  State<NewGroupPickerPage> createState() => _NewGroupPickerPageState();
}

class _NewGroupPickerPageState extends State<NewGroupPickerPage> {
  static const int _pageSize = 20;

  final ApiService _api = serviceLocator.get<ApiService>();
  final ScrollController _scroll = ScrollController();

  final List<UserSummaryResponse> _users = [];
  final Map<String, UserSummaryResponse> _selected = {};

  int _currentPage = 0;
  bool _hasReachedEnd = false;
  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_maybeLoadMore);
    _loadInitial();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getMyFollowing(page: 0, size: _pageSize);
      if (!mounted) return;
      if (!res.success || res.data == null) {
        setState(() {
          _loading = false;
          _error = res.error ?? 'Failed to load';
        });
        return;
      }
      setState(() {
        _users
          ..clear()
          ..addAll(res.data!.content);
        _currentPage = 0;
        _hasReachedEnd = res.data!.last;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _maybeLoadMore() async {
    if (_loadingMore || _hasReachedEnd || _loading) return;
    if (_scroll.position.pixels < _scroll.position.maxScrollExtent - 200) {
      return;
    }
    setState(() => _loadingMore = true);
    try {
      final nextPage = _currentPage + 1;
      final ApiResponse<PagedResponse<UserSummaryResponse>> res =
          await _api.getMyFollowing(page: nextPage, size: _pageSize);
      if (!mounted) return;
      if (!res.success || res.data == null) {
        setState(() => _loadingMore = false);
        return;
      }
      setState(() {
        _users.addAll(res.data!.content);
        _currentPage = nextPage;
        _hasReachedEnd = res.data!.last;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _toggle(UserSummaryResponse u) {
    setState(() {
      if (_selected.containsKey(u.id)) {
        _selected.remove(u.id);
      } else {
        if (_selected.length >= NewGroupPickerPage.maxSelectable) {
          appToast.info(
            LocaleKeys.chat_new_group_max_members.tr(
              namedArgs: {'n': '${NewGroupPickerPage.maxSelectable}'},
            ),
          );
          return;
        }
        _selected[u.id] = u;
      }
    });
  }

  void _proceed() {
    if (_selected.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewGroupTitlePage(
          members: _selected.values.toList(growable: false),
        ),
      ),
    );
  }

  List<UserSummaryResponse> get _filteredUsers {
    if (_query.isEmpty) return _users;
    final q = _query.toLowerCase();
    return _users
        .where((u) =>
            (u.displayName ?? '').toLowerCase().contains(q) ||
            (u.username ?? '').toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        title: Text(
          LocaleKeys.chat_new_group_title_picker.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: _selected.isEmpty ? null : _proceed,
            child: Text(
              LocaleKeys.chat_new_group_next.tr(),
              style: TextStyle(
                color: _selected.isEmpty ? c.onSurfaceDisabled : c.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_selected.isNotEmpty) _selectedStrip(),
          _searchField(),
          Expanded(child: _list()),
        ],
      ),
    );
  }

  Widget _selectedStrip() {
    final c = context.c;
    final entries = _selected.values.toList(growable: false);
    return SizedBox(
      height: 78,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: entries.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final u = entries[i];
          return SizedBox(
            width: 56,
            child: Column(
              children: [
                Stack(
                  children: [
                    _Avatar(url: u.avatarUrl, size: 46),
                    Positioned(
                      right: -2,
                      top: -2,
                      child: GestureDetector(
                        onTap: () => _toggle(u),
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: c.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            TablerIcons.x,
                            size: 12,
                            color: c.onPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  u.displayName ?? u.username ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _searchField() {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: TextField(
        onChanged: (v) => setState(() => _query = v.trim()),
        style: TextStyle(color: c.onSurface),
        cursorColor: c.onSurface,
        decoration: InputDecoration(
          hintText: LocaleKeys.chat_new_group_search_followers_hint.tr(),
          hintStyle: TextStyle(color: c.onSurfaceMuted),
          prefixIcon:
              Icon(TablerIcons.search, color: c.onSurfaceSecondary, size: 18),
          filled: true,
          fillColor: c.surfaceMuted,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          isDense: true,
        ),
      ),
    );
  }

  Widget _list() {
    final c = context.c;
    if (_loading && _users.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          color: c.onSurface,
          strokeWidth: 1.5,
        ),
      );
    }
    if (_error != null && _users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.cloud_off, color: c.onSurfaceDisabled, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              style: TextStyle(color: c.onSurfaceSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadInitial,
              child: Text(
                LocaleKeys.common_retry.tr(),
                style: TextStyle(color: c.onSurface),
              ),
            ),
          ],
        ),
      );
    }
    final visible = _filteredUsers;
    if (visible.isEmpty) {
      return Center(
        child: Text(
          LocaleKeys.common_no_results.tr(),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
      );
    }
    return ListView.separated(
      controller: _scroll,
      itemCount: visible.length + (_loadingMore ? 1 : 0),
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: c.border,
      ),
      itemBuilder: (context, i) {
        if (i >= visible.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: c.onSurface,
                  strokeWidth: 1.5,
                ),
              ),
            ),
          );
        }
        final u = visible[i];
        final picked = _selected.containsKey(u.id);
        return InkWell(
          onTap: () => _toggle(u),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                _Avatar(url: u.avatarUrl, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        u.displayName ?? u.username ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (u.username != null && u.username!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '@${u.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _PickCheck(checked: picked),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final double size;
  const _Avatar({required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: c.divider,
      ),
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              memCacheWidth: (size * 3).round(),
              errorWidget: (_, _, _) => Icon(
                TablerIcons.user,
                color: c.onSurfaceSecondary,
                size: 18,
              ),
            )
          : Icon(
              TablerIcons.user,
              color: c.onSurfaceSecondary,
              size: 20,
            ),
    );
  }
}

class _PickCheck extends StatelessWidget {
  final bool checked;
  const _PickCheck({required this.checked});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? c.primary : Colors.transparent,
        border: Border.all(
          color: checked ? c.primary : c.onSurfaceSecondary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: checked
          ? Icon(TablerIcons.check, color: c.onPrimary, size: 14)
          : null,
    );
  }
}
