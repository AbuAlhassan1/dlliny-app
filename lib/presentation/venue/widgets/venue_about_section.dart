import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/widgets/gallery/venue_gallery_preview.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_hours_card.dart';

class VenueAboutSection extends StatelessWidget {
  final VoidCallback? onShowBranches;

  const VenueAboutSection({super.key, this.onShowBranches});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VenueBloc, VenueState>(
      builder: (context, state) {
        if (state is! GetVenueDetailsLoaded) return const SizedBox.shrink();
        final venue = state.venue;
        return ColoredBox(
          color: context.c.background,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              VenueHoursCard(venue: venue, onShowBranches: onShowBranches),
              VenueGalleryPreview(venue: venue),
            ],
          ),
        );
      },
    );
  }
}
