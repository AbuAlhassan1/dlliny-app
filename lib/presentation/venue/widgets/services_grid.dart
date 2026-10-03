import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/services_controller/services_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/edit_services_page_wrapper.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ServicesGrid extends StatelessWidget {
  const ServicesGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<ServicesBloc, ServicesState>(
      builder: (context, state) {
        if (state is ServicesLoading || state is ServicesInitial) {
          return SizedBox.expand(
            child: Shimmer(
              enabled: true,
              child: Container(
                color: c.onSurface.withValues(alpha: 0.08),
              ),
            ),
          );
        }

        if (state is ServicesError) {
          return Center(
            child: Text(
              "Failed to load services",
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final services = (state as ServicesLoaded).response;

        return Column(
          children: [
            BlocBuilder<VenueBloc, VenueState>(
              buildWhen: (_, curr) => curr is GetVenueDetailsLoaded,
              builder: (context, vState) {
                if (vState is! GetVenueDetailsLoaded) {
                  return const SizedBox.shrink();
                }
                if (!userHasOnVenue(
                  context,
                  VenuePerm.servicesManage,
                  vState.venue.id,
                )) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.fromLTRB(15, 14, 15, 4),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => EditServicesPageWrapper.push(
                        context,
                        vState.venue.id,
                      ),
                      icon: Icon(TablerIcons.pencil, color: c.onSurface, size: 16),
                      label: Text(
                        LocaleKeys.venue_services_grid_edit_services.tr(),
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: c.border),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2 / 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: services.length,
          itemBuilder: (context, index) => Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: CachedNetworkImage(
                      imageUrl: services[index].imageUrl.toString(),
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      placeholder: (context, url) => Container(
                        color: c.surfaceMuted,
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: c.surfaceMuted,
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: c.onSurfaceDisabled,
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Row(
                          children: [
                            Text(
                              services[index].nameAr.toString(),
                              style: TextStyle(
                                color: c.onSurface,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              services[index].nameEn.toString(),
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "${services[index].price} IQD",
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
              ),
            ),
          ],
        );
      },
    );
  }
}
