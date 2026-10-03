// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/helper/image_cropper.dart';
import 'package:hangout/helper/image_picker.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_logo/update_logo_bloc.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';

class VenueAvatar extends StatelessWidget {
  final String? logoUrl;
  final String venueId;
  const VenueAvatar({
    super.key,
    required this.logoUrl,
    required this.venueId,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocProvider(
      create: (context) => UpdateLogoBloc(),
      child: BlocListener<UpdateLogoBloc, UpdateLogoState>(
        listenWhen: (_, s) => s is UpdateLogoLoaded,
        listener: (context, _) {
          context.read<VenueBloc>().add(GetVenueDetails(venueId));
        },
        child: SizedBox(
          height: 65,
          width: 65,
          child: Stack(
            children: [
              Container(
                height: 65,
                width: 65,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: .circular(100)),
                child: CachedNetworkImage(
                  imageUrl: logoUrl ?? "",
                  errorWidget: (context, url, error) => Container(
                    color: c.onMediaSurface.withValues(alpha: 0.24),
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: c.onMediaSurface,
                    ),
                  ),
                  placeholder: (context, url) => Container(
                    color: c.onMediaSurface.withValues(alpha: 0.4),
                  ),
                ),
              ),

              if (userHasOnVenue(context, VenuePerm.mediaUpload, venueId))
                Builder(
                  builder: (context) {
                    return Align(
                      alignment: Alignment.bottomRight,
                      child: Material(
                        color: c.onMediaSurface,
                        borderRadius: .circular(100),
                        child: InkWell(
                          onTap: () async {
                            File? file = await pickImage();
                            if (file == null) return;
                            final File? croppedLogo =
                                await cropImageWithUi(file, 1);

                            if (croppedLogo != null) {
                              context.read<UpdateLogoBloc>().add(
                                    UpdateVenueLogo(
                                      venueId: venueId,
                                      logo: croppedLogo,
                                    ),
                                  );
                            }
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            padding: const EdgeInsets.all(5.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: c.mediaSurface.withValues(alpha: 0.48),
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Icon(
                              Icons.edit,
                              color: c.mediaSurface,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
