import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/profile/widgets/post_thumbnail.dart';
import 'package:hangout/presentation/venue/controllers/venue_posts/venue_posts_bloc.dart';

class VenuePostsGrid extends StatelessWidget {
  final String venueId;
  const VenuePostsGrid({super.key, required this.venueId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          VenuePostsBloc(venueId: venueId)..add(const LoadVenuePosts()),
      child: const _VenuePostsBody(),
    );
  }
}

class _VenuePostsBody extends StatelessWidget {
  const _VenuePostsBody();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<VenuePostsBloc, VenuePostsState>(
      builder: (context, state) {
        return switch (state) {
          VenuePostsInitial() ||
          VenuePostsLoading() => Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1.5,
              ),
            ),
          VenuePostsError(:final message) => SingleChildScrollView(
            child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        TablerIcons.alert_triangle,
                        color: c.onSurfaceDisabled,
                        size: 32,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: c.onSurfaceSecondary),
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton(
                        onPressed: () => context
                            .read<VenuePostsBloc>()
                            .add(const LoadVenuePosts()),
                        child: Text(LocaleKeys.venue_posts_grid_button_retry.tr()),
                      ),
                    ],
                  ),
                ),
              ),
          ),
          VenuePostsLoaded(:final items, :final hasMore) =>
            items.isEmpty
                ? SingleChildScrollView(
                  child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              TablerIcons.photo,
                              color: c.onSurfaceDisabled,
                              size: 32,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              LocaleKeys.venue_posts_grid_empty.tr(),
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                )
                : RefreshIndicator(
                    onRefresh: () async => context
                        .read<VenuePostsBloc>()
                        .add(const LoadVenuePosts()),
                    color: c.onSurface,
                    strokeWidth: 2,
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (hasMore &&
                            notification.metrics.axis == Axis.vertical &&
                            notification.metrics.pixels >=
                                notification.metrics.maxScrollExtent - 400) {
                          context
                              .read<VenuePostsBloc>()
                              .add(const LoadNextVenuePostsPage());
                        }
                        return false;
                      },
                      child: GridView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: items.length + (hasMore ? 3 : 0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 2,
                          crossAxisSpacing: 2,
                        ),
                        itemBuilder: (context, index) {
                          if (index >= items.length) {
                            if (index == items.length + 1) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: c.onSurface,
                                  strokeWidth: 1.5,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }
                          return PostThumbnail(
                            post: items[index],
                            index: index,
                          );
                        },
                      ),
                    ),
                  ),
        };
      },
    );
  }
}
