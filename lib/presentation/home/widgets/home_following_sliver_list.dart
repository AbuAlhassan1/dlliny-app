import 'package:flutter/material.dart';
import 'package:hangout/domain/dto/dto.dart';
import 'package:hangout/presentation/home/widgets/hangout_feed_widget.dart';
import 'package:hangout/presentation/home/widgets/post_skeleton.dart';
import 'package:hangout/presentation/home/widgets/post_widget.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class HomeFollowingSliverList extends StatelessWidget {
  final PagingController<int, Object> controller;

  const HomeFollowingSliverList({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PagingState<int, Object>>(
      valueListenable: controller,
      builder: (context, state, child) => PagedSliverList.separated(
        state: state,
        fetchNextPage: controller.fetchNextPage,
        builderDelegate: PagedChildBuilderDelegate<Object>(
          itemBuilder: (context, item, index) {
            if (item is PostFeedItem) return PostWidget(item: item);
            if (item is HangoutFeedItem) return HangoutFeedWidget(item: item);
            return const SizedBox.shrink();
          },
          firstPageProgressIndicatorBuilder: (_) => const PostSkeletonList(),
          newPageProgressIndicatorBuilder: (_) => const PostSkeleton(),
        ),
        separatorBuilder: (context, index) => const SizedBox(height: 0),
      ),
    );
  }
}
