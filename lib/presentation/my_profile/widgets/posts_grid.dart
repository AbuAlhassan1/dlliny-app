import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/presentation/my_profile/controller/posts/my_posts_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/post_thumbnail.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class PostsGrid extends StatelessWidget {
  const PostsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MyPostsBloc, MyPostsState>(
      builder: (context, state) {
        final bloc = context.read<MyPostsBloc>();
        final posts = bloc.myPosts?.content ?? [];

        if (state is MyPostsLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: c.onSurface,
              strokeWidth: 1,
            ),
          );
        }

        if (state is MyPostsError) {
          return Center(child: Text(state.message));
        }

        if (posts.isEmpty) {
          return const Center(child: Text('No posts yet'));
        }

        return PagedGridView<int, PostResponse>(
          padding: EdgeInsets.zero,
          builderDelegate: PagedChildBuilderDelegate(
            itemBuilder: (context, item, index) => PostThumbnail(post: item, index: index),
            newPageProgressIndicatorBuilder: (_) => Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1,
              ),
            ),
            newPageErrorIndicatorBuilder: (_) => Center(
              child: Text(
                state is MyPostsMoreError
                    ? state.message
                    : 'Error loading more posts',
              ),
            ),
          ),
          state: PagingState(
            pages: [posts],
            keys: [0],
            isLoading: state is MyPostsMoreLoading,
            hasNextPage: !(bloc.myPosts?.last ?? true),
            error: state is MyPostsMoreError ? state.message : null,
          ),
          fetchNextPage: () {
            if (state is! MyPostsMoreLoading) {
              context.read<MyPostsBloc>().add(GetMorePosts());
            }
          },
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
          ),
        );
      },
    );
  }
}
