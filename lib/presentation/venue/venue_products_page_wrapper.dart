import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/pages/post_details/post_details_page_wrapper.dart';
import 'package:hangout/presentation/venue/controllers/venue_products/venue_products_bloc.dart';

class VenueProductsPageWrapper extends StatelessWidget {
  final String venueId;
  final String? venueName;
  const VenueProductsPageWrapper({
    super.key,
    required this.venueId,
    this.venueName,
  });

  static Future<void> push(
    BuildContext context, {
    required String venueId,
    String? venueName,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VenueProductsPageWrapper(
          venueId: venueId,
          venueName: venueName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocProvider(
      create: (_) => VenueProductsBloc(venueId: venueId)
        ..add(const LoadVenueProducts()),
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          elevation: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                LocaleKeys.venue_products_page_title.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              if (venueName != null && venueName!.isNotEmpty)
                Text(
                  venueName!,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
            ],
          ),
        ),
        body: const _VenueProductsBody(),
      ),
    );
  }
}

class _VenueProductsBody extends StatefulWidget {
  const _VenueProductsBody();
  @override
  State<_VenueProductsBody> createState() => _VenueProductsBodyState();
}

class _VenueProductsBodyState extends State<_VenueProductsBody> {
  final ScrollController _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 400) {
      context.read<VenueProductsBloc>().add(const LoadNextVenueProductsPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<VenueProductsBloc, VenueProductsState>(
      builder: (context, state) {
        return switch (state) {
          VenueProductsInitial() ||
          VenueProductsLoading() => Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1.5,
              ),
            ),
          VenueProductsError(:final message) => Center(
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
                          .read<VenueProductsBloc>()
                          .add(const LoadVenueProducts()),
                      child: Text(LocaleKeys.venue_products_button_retry.tr()),
                    ),
                  ],
                ),
              ),
            ),
          VenueProductsLoaded(:final items, :final hasMore) =>
            items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TablerIcons.shopping_bag,
                            color: c.onSurfaceDisabled,
                            size: 32,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            LocaleKeys.venue_products_empty.tr(),
                            style: TextStyle(
                              color: c.onSurfaceSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async => context
                        .read<VenueProductsBloc>()
                        .add(const LoadVenueProducts()),
                    child: GridView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.all(12),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.62,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: items.length + (hasMore ? 2 : 0),
                      itemBuilder: (context, index) {
                        if (index >= items.length) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: c.onSurface,
                              strokeWidth: 1.5,
                            ),
                          );
                        }
                        return _ProductTile(post: items[index]);
                      },
                    ),
                  ),
        };
      },
    );
  }
}

class _ProductTile extends StatelessWidget {
  final PostResponse post;
  const _ProductTile({required this.post});

  String? get _coverUrl =>
      post.media.isNotEmpty ? post.media.first.url : null;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PostDetailsPageWrapper(post: post),
        ),
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: c.surface,
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: _coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: _coverUrl!,
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      errorWidget: (_, _, _) => Container(
                        color: c.surfaceMuted,
                        child: Icon(
                          TablerIcons.photo_off,
                          color: c.onSurfaceDisabled,
                        ),
                      ),
                    )
                  : Container(
                      color: c.surfaceMuted,
                      child: Icon(
                        TablerIcons.shopping_bag,
                        color: c.onSurfaceDisabled,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (post.caption?.isNotEmpty == true)
                    Text(
                      post.caption!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      LocaleKeys.venue_products_label_product.tr(),
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        post.price?.toStringAsFixed(0) ?? '—',
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 1),
                        child: Text(
                          post.priceCurrency ?? 'IQD',
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
