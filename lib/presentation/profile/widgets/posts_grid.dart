import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/profile/controllers/posts/user_posts_bloc.dart';
import 'package:hangout/presentation/profile/widgets/post_thumbnail.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class PostsGrid extends StatelessWidget {
  final String userId;
  const PostsGrid({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<UserPostsBloc, UserPostsState>(
      builder: (context, state) {
        final bloc = context.read<UserPostsBloc>();
        final posts = bloc.userPosts?.content ?? [];

        if (state is UserPostsLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: c.onSurface,
              strokeWidth: 1,
            ),
          );
        }

        if (state is UserPostsError) {
          return Center(child: Text(state.message));
        }

        if (posts.isEmpty) {
          return Center(
            child: Text(
              LocaleKeys.profile_empty_posts.tr(),
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          );
        }

        return PagedGridView<int, PostResponse>(
          padding: EdgeInsets.zero,
          clipBehavior: Clip.none,
          builderDelegate: PagedChildBuilderDelegate(
            itemBuilder: (context, item, index) =>
                PostThumbnail(post: item, index: index),
            newPageProgressIndicatorBuilder: (_) => Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1,
              ),
            ),
            newPageErrorIndicatorBuilder: (_) => Center(
              child: Text(
                state is UserPostsMoreError
                    ? state.message
                    : 'Error loading more posts',
              ),
            ),
          ),
          state: PagingState(
            pages: [posts],
            keys: [0],
            isLoading: state is UserPostsMoreLoading,
            hasNextPage: !(bloc.userPosts?.last ?? true),
            error: state is UserPostsMoreError ? state.message : null,
          ),
          fetchNextPage: () {
            if (state is! UserPostsMoreLoading) {
              context.read<UserPostsBloc>().add(GetMoreUserPosts(userId));
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
