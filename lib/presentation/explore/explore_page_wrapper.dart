import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/base/controller/tabs_bloc.dart';
import 'package:hangout/presentation/explore/utils/reel_item.dart';
import 'package:hangout/presentation/explore/widgets/hangout_reel_card.dart';
import 'package:hangout/presentation/explore/widgets/reel_card.dart';
import 'package:hangout/presentation/shared/widgets/scroll_snapy_physics.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class ExplorePageWrapper extends StatefulWidget {
  const ExplorePageWrapper({super.key});

  @override
  State<ExplorePageWrapper> createState() => _ExplorePageWrapperState();
}

class _ExplorePageWrapperState extends State<ExplorePageWrapper>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 10;
  static const int _prefetchAhead = 2;

  final ApiService _api = serviceLocator.get<ApiService>();
  late final PagingController<int, ReelItem> _controller;
  final PageController _pageController = PageController();

  bool _hasMore = true;
  int _currentIndex = 0;

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.fetchNextPage();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<List<ReelItem>> _fetchPage(int pageKey) async {
    final response = await _api.getReels(page: pageKey, size: _pageSize);
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Failed to load reels');
    }
    final items = response.data!.parsedItems
        .map(ReelItem.from)
        .whereType<ReelItem>()
        .toList(growable: false);
    _hasMore = items.isNotEmpty && response.data!.hasMore;
    return items;
  }

  void _onExploreRetapped() {
    if (!_pageController.hasClients) return;
    if (_currentIndex > 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    } else {
      _hasMore = true;
      _controller.refresh();
    }
  }

  void _onPageChanged(int index, int loadedCount, VoidCallback fetchNextPage) {
    setState(() => _currentIndex = index);
    if (_hasMore && index >= loadedCount - _prefetchAhead) {
      fetchNextPage();
    }
  }

  Widget _buildReel(ReelItem item, bool isActive) {
    return switch (item) {
      PostReel(:final post) => ReelCard(
          key: ValueKey('reel-${item.id}'),
          post: post,
          isActive: isActive,
        ),
      HangoutReel(:final hangout) => HangoutReelCard(
          key: ValueKey('reel-${item.id}'),
          item: hangout,
          isActive: isActive,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.c;
    const exploreTabIndex = 4;
    return Scaffold(
      backgroundColor: c.mediaSurface,
      body: BlocListener<TabsBloc, TabsState>(
        listenWhen: (_, curr) =>
            curr is TabRetappedState && curr.index == exploreTabIndex,
        listener: (_, _) => _onExploreRetapped(),
        child: PagingListener<int, ReelItem>(
          controller: _controller,
          builder: (context, state, fetchNextPage) {
            final items = state.items ?? const <ReelItem>[];
            if (state.error != null && items.isEmpty) {
              return _ReelsError(
                message: state.error.toString(),
                onRetry: _controller.refresh,
              );
            }
            if (items.isEmpty && !state.hasNextPage) {
              return const _ReelsEmpty();
            }
            if (items.isEmpty) {
              return Center(
                child: CircularProgressIndicator(
                  color: c.onMediaSurface,
                  strokeWidth: 1.5,
                ),
              );
            }

            final showTailLoader = _hasMore && state.hasNextPage;
            final itemCount = items.length + (showTailLoader ? 1 : 0);
            return PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              physics: const SnappyPageScrollPhysics(),
              allowImplicitScrolling: true,
              itemCount: itemCount,
              onPageChanged: (i) =>
                  _onPageChanged(i, items.length, fetchNextPage),
              itemBuilder: (context, index) {
                if (index >= items.length) {
                  return _TailLoader();
                }
                return _buildReel(items[index], index == _currentIndex);
              },
            );
          },
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _TailLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ColoredBox(
      color: c.mediaSurface,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: c.onMediaSurface,
          ),
        ),
      ),
    );
  }
}

class _ReelsError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ReelsError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              TablerIcons.cloud_off,
              color: c.onMediaSurface.withValues(alpha: 0.38),
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              LocaleKeys.explore_error_load_reels.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onMediaSurface,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onMediaSurface.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 14),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(
                TablerIcons.refresh,
                color: c.onMediaSurface,
                size: 18,
              ),
              label: Text(
                LocaleKeys.common_retry.tr(),
                style: TextStyle(color: c.onMediaSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReelsEmpty extends StatelessWidget {
  const _ReelsEmpty();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TablerIcons.video_off,
            color: c.onMediaSurface.withValues(alpha: 0.38),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.explore_empty_reels.tr(),
            style: TextStyle(
              color: c.onMediaSurface.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
