import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/domain/dto/response/trending_venue_response.dart';
import 'package:hangout/presentation/base/controller/tabs_bloc.dart';
import 'package:hangout/presentation/discover/discover_post_viewer.dart';
import 'package:hangout/presentation/discover/widgets/discover_grid_tile.dart';
import 'package:hangout/presentation/discover/widgets/discover_search_results.dart';
import 'package:hangout/presentation/explore/utils/reel_item.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class DiscoverPageWrapper extends StatefulWidget {
  const DiscoverPageWrapper({super.key});

  static const int tabIndex = 5;

  @override
  State<DiscoverPageWrapper> createState() => _DiscoverPageWrapperState();
}

class _DiscoverPageWrapperState extends State<DiscoverPageWrapper>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 18;

  final ApiService _api = serviceLocator.get<ApiService>();
  late final PagingController<int, ReelItem> _controller;
  bool _hasMore = true;

  final TextEditingController _searchInput = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  Timer? _debounce;
  bool _searchActive = false;
  String _query = '';
  bool _searchLoading = false;
  SearchResultResponse? _searchResults;
  List<TrendingVenueResponse> _trending = const [];

  @override
  void initState() {
    super.initState();
    _controller = PagingController<int, ReelItem>(
      getNextPageKey: (state) {
        if (!_hasMore) return null;
        return (state.keys?.last ?? -1) + 1;
      },
      fetchPage: _fetchPage,
    );
    _searchFocus.addListener(_onFocusChanged);
    _loadTrending();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchInput.dispose();
    _searchFocus.removeListener(_onFocusChanged);
    _searchFocus.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<List<ReelItem>> _fetchPage(int pageKey) async {
    final res = await _api.getExplore(page: pageKey, size: _pageSize);
    if (!res.success || res.data == null) {
      throw Exception(res.error ?? 'Failed to load');
    }
    final items = res.data!.parsedItems
        .map(ReelItem.from)
        .whereType<ReelItem>()
        .toList(growable: false);
    _hasMore = items.isNotEmpty && res.data!.hasMore;
    return items;
  }

  Future<void> _loadTrending() async {
    try {
      final res = await _api.getTrendingVenues(limit: 12);
      if (!mounted || !res.success || res.data == null) return;
      setState(() => _trending = res.data!);
    } catch (_) {
    }
  }

  void _onFocusChanged() {
    if (_searchFocus.hasFocus && !_searchActive) {
      setState(() => _searchActive = true);
    }
  }

  void _onQueryChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _searchResults = null;
        _searchLoading = false;
      });
      return;
    }
    setState(() => _searchLoading = true);
    _debounce = Timer(const Duration(milliseconds: 350), () => _runSearch(q));
  }

  Future<void> _runSearch(String q) async {
    try {
      final res = await _api.search(q, limit: 20);
      if (!mounted) return;
      if (_query.trim() != q) return;
      setState(() {
        _searchResults = res.success ? res.data : const SearchResultResponse(
          venues: [],
          users: [],
        );
        _searchLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = const SearchResultResponse(venues: [], users: []);
        _searchLoading = false;
      });
    }
  }

  void _exitSearch() {
    _debounce?.cancel();
    _searchInput.clear();
    _searchFocus.unfocus();
    setState(() {
      _searchActive = false;
      _query = '';
      _searchResults = null;
      _searchLoading = false;
    });
  }

  void _onRetapped() {
    if (_searchActive) {
      _exitSearch();
    } else {
      _hasMore = true;
      _controller.refresh();
    }
  }

  void _openViewer(List<ReelItem> items, int index) {
    if (items.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiscoverPostViewer(items: items, initialIndex: index),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.c;

    return Scaffold(
      backgroundColor: c.background,
      body: BlocListener<TabsBloc, TabsState>(
        listenWhen: (_, curr) =>
            curr is TabRetappedState &&
            curr.index == DiscoverPageWrapper.tabIndex,
        listener: (_, _) => _onRetapped(),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _SearchField(
                controller: _searchInput,
                focusNode: _searchFocus,
                active: _searchActive,
                onChanged: _onQueryChanged,
                onCancel: _exitSearch,
              ),
              Expanded(
                child: _searchActive
                    ? DiscoverSearchResults(
                        query: _query,
                        loading: _searchLoading,
                        results: _searchResults,
                        trending: _trending,
                      )
                    : _buildGrid(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    final c = context.c;
    return PagingListener<int, ReelItem>(
      controller: _controller,
      builder: (context, state, fetchNextPage) {
        return RefreshIndicator(
          color: c.primary,
          onRefresh: () async {
            _hasMore = true;
            _controller.refresh();
          },
          child: PagedGridView<int, ReelItem>(
            state: state,
            fetchNextPage: fetchNextPage,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 2, bottom: 120),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
              childAspectRatio: 1,
            ),
            builderDelegate: PagedChildBuilderDelegate<ReelItem>(
              itemBuilder: (context, item, index) => DiscoverGridTile(
                item: item,
                onTap: () => _openViewer(state.items ?? const [], index),
              ),
              firstPageProgressIndicatorBuilder: (_) => Center(
                child: CircularProgressIndicator(
                  color: c.primary,
                  strokeWidth: 2,
                ),
              ),
              newPageProgressIndicatorBuilder: (_) => Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: c.primary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              ),
              noItemsFoundIndicatorBuilder: (_) => _GridEmpty(),
              firstPageErrorIndicatorBuilder: (_) => _GridError(
                onRetry: () {
                  _hasMore = true;
                  _controller.refresh();
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool active;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancel;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.active,
    required this.onChanged,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border, width: 1),
              ),
              child: Row(
                children: [
                  Icon(TablerIcons.search, size: 20, color: c.onSurfaceMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      onChanged: onChanged,
                      textInputAction: TextInputAction.search,
                      cursorColor: c.primary,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 15,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                      decoration: InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: context.pickBilingual(
                          ar: 'ابحث',
                          en: 'Search',
                        ),
                        hintStyle: TextStyle(
                          color: c.onSurfaceMuted,
                          fontSize: 15,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        controller.clear();
                        onChanged('');
                      },
                      child: Icon(
                        TablerIcons.circle_x_filled,
                        size: 18,
                        color: c.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (active)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onCancel,
              child: Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  context.pickBilingual(ar: 'إلغاء', en: 'Cancel'),
                  style: TextStyle(
                    color: c.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GridEmpty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.compass, color: c.onSurfaceMuted, size: 44),
            const SizedBox(height: 12),
            Text(
              context.pickBilingual(
                ar: 'لا يوجد محتوى لاكتشافه بعد',
                en: 'Nothing to discover yet',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 14,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridError extends StatelessWidget {
  final VoidCallback onRetry;
  const _GridError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.alert_triangle, color: c.danger, size: 40),
            const SizedBox(height: 12),
            Text(
              context.pickBilingual(
                ar: 'تعذّر تحميل المحتوى',
                en: 'Could not load content',
              ),
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 14,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: Text(
                context.pickBilingual(ar: 'إعادة المحاولة', en: 'Retry'),
                style: TextStyle(
                  color: c.primary,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
