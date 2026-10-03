import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed_widget.dart';
import 'package:hangout/presentation/home/widgets/post_skeleton.dart';
import 'package:hangout/presentation/home/widgets/post_widget.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class VenueCommunityFeed extends StatefulWidget {
  final String venueId;
  const VenueCommunityFeed({super.key, required this.venueId});

  @override
  State<VenueCommunityFeed> createState() => _VenueCommunityFeedState();
}

class _VenueCommunityFeedState extends State<VenueCommunityFeed>
    with AutomaticKeepAliveClientMixin {
  static const int _pageSize = 20;

  final ApiService _api = serviceLocator.get<ApiService>();
  late final PagingController<int, Object> _controller;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _controller = PagingController<int, Object>(
      getNextPageKey: (state) {
        if (!_hasMore) return null;
        return (state.keys?.last ?? -1) + 1;
      },
      fetchPage: _fetchPage,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<List<Object>> _fetchPage(int pageKey) async {
    final response = await _api.getVenueCommunityFeed(
      widget.venueId,
      page: pageKey,
      size: _pageSize,
    );
    if (!response.success || response.data == null) {
      throw Exception(response.error ?? 'Failed to load community feed');
    }
    _hasMore = response.data!.hasMore;
    return response.data!.parsedItems;
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final c = context.c;
    return RefreshIndicator(
      onRefresh: () async {
        _hasMore = true;
        _controller.refresh();
      },
      color: c.onSurface,
      child: PagingListener<int, Object>(
        controller: _controller,
        builder: (context, state, fetchNextPage) {
          return PagedListView<int, Object>.separated(
            state: state,
            fetchNextPage: fetchNextPage,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(vertical: 15),
            separatorBuilder: (_, _) => const SizedBox(height: 0),
            builderDelegate: PagedChildBuilderDelegate<Object>(
              itemBuilder: (context, item, index) {
                if (item is PostFeedItem) return PostWidget(item: item);
                if (item is HangoutFeedItem) {
                  return HangoutFeedWidget(item: item);
                }
                return const SizedBox.shrink();
              },
              firstPageProgressIndicatorBuilder: (_) => const PostSkeletonList(),
              newPageProgressIndicatorBuilder: (_) => const PostSkeleton(),
              firstPageErrorIndicatorBuilder: (_) => _CommunityError(
                onRetry: _controller.refresh,
              ),
              noItemsFoundIndicatorBuilder: (_) => const _CommunityEmpty(),
            ),
          );
        },
      ),
    );
  }
}

class _CommunityError extends StatelessWidget {
  final VoidCallback onRetry;
  const _CommunityError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.cloud_off, color: c.onSurfaceDisabled, size: 40),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.venue_community_error_load.tr(),
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onRetry,
            icon: Icon(TablerIcons.refresh, color: c.onSurface, size: 16),
            label: Text(
              LocaleKeys.venue_community_button_retry.tr(),
              style: TextStyle(color: c.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommunityEmpty extends StatelessWidget {
  const _CommunityEmpty();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 80, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            TablerIcons.messages,
            color: c.onSurfaceDisabled,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            LocaleKeys.venue_community_empty.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
