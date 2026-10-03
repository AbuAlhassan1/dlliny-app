import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/widgets/gallery/gallery_photo_image.dart';
import 'package:image/image.dart' as img;

import 'test_harness.dart';

const String kGalleryVenueId = 'venue-1';

const String kSampleThumbHash = '3OcRJYB4d3h/iIeHeEh3eIhw+j2w';

GalleryPhotoDto buildGalleryPhoto(
  String id, {
  int width = 1536,
  int height = 2048,
  List<String> tags = const [],
  String? locationId,
  bool hidden = false,
  String? hiddenReason,
  String? placeholderHash,
  int sortOrder = 0,
}) => GalleryPhotoDto(
  id: id,
  url: 'https://cdn.test/venues/$kGalleryVenueId/gallery/$id.webp',
  width: width,
  height: height,
  aspectRatio: double.parse((width / height).toStringAsFixed(4)),
  placeholderHash: placeholderHash,
  tags: tags,
  locationId: locationId,
  sortOrder: sortOrder,
  hidden: hidden,
  hiddenReason: hiddenReason,
);

VenueLocationResponse buildBranch(
  String id, {
  String? labelAr,
  String? districtNameAr,
  bool isPrimary = false,
  int sortOrder = 0,
}) => VenueLocationResponse(
  id: id,
  venueId: kGalleryVenueId,
  labelAr: labelAr,
  districtNameAr: districtNameAr,
  latitude: 33.3,
  longitude: 44.4,
  isPrimary: isPrimary,
  sortOrder: sortOrder,
);

VenueResponse buildGalleryVenue({
  List<GalleryPhotoDto> photos = const [],
  Map<String, int>? tagCounts,
  List<VenueLocationResponse> locations = const [],
  bool withGallery = true,
}) {
  final counts = <String, int>{};
  for (final p in photos) {
    for (final t in p.tags.toSet()) {
      counts[t] = (counts[t] ?? 0) + 1;
    }
  }
  return VenueResponse(
    id: kGalleryVenueId,
    nameAr: 'مقهى الشناشيل',
    nameEn: 'Shanasheel Cafe',
    avgRating: 0,
    totalRatings: 0,
    followerCount: 0,
    verified: false,
    family: false,
    hasShisha: false,
    hasParking: false,
    hasWifi: false,
    hasOutdoor: false,
    hasPrivateRoom: false,
    hours: const [],
    mediaUrls: [for (final p in photos) p.url],
    locations: locations,
    gallery: withGallery
        ? VenueGalleryDto(
            totalCount: photos.length,
            photos: photos,
            tagCounts: tagCounts ?? counts,
          )
        : null,
  );
}

AccessBloc accessWith(List<String> perms) => AccessBloc()
  ..myAccess = apiOk(
    UserAccessResponse(
      businesses: const [],
      orphanVenues: [
        VenueAccess(
          venueId: kGalleryVenueId,
          nameAr: 'مقهى',
          active: true,
          verified: false,
          venuePermissions: perms,
          effectivePermissions: perms,
        ),
      ],
    ),
  );

Uint8List solidPng(Color color, {int width = 30, int height = 40}) {
  final image = img.Image(width: width, height: height);
  img.fill(
    image,
    color: img.ColorRgb8(
      (color.r * 255).round(),
      (color.g * 255).round(),
      (color.b * 255).round(),
    ),
  );
  return Uint8List.fromList(img.encodePng(image));
}

GalleryImageProviderBuilder solidGalleryImages({
  List<Color> palette = const [
    Color(0xFF8D6E63),
    Color(0xFF546E7A),
    Color(0xFFB0875A),
    Color(0xFF6D8B74),
    Color(0xFF9E5A63),
    Color(0xFF5C6BC0),
  ],
}) {
  final cache = <String, MemoryImage>{};
  return (url, {cacheWidth}) => cache.putIfAbsent(
    url,
    () => MemoryImage(solidPng(palette[cache.length % palette.length])),
  );
}

void usePhoneSurface(WidgetTester tester) {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
}

Widget galleryHost(
  Widget child, {
  List<String> perms = const [],
  VenueBloc? venueBloc,
  TextDirection direction = TextDirection.rtl,
  bool scrollable = true,
  GalleryImageProviderBuilder? images,
}) => GalleryImageScope(
  builder: images ?? solidGalleryImages(),
  child: MultiBlocProvider(
    providers: [
      BlocProvider<AccessBloc>.value(value: accessWith(perms)),
      if (venueBloc != null) BlocProvider<VenueBloc>.value(value: venueBloc),
    ],
    child: MaterialApp(
      theme: Themes.lightTheme,
      debugShowCheckedModeBanner: false,
      builder: (context, navigator) =>
          Directionality(textDirection: direction, child: navigator!),
      home: scrollable
          ? Scaffold(body: SingleChildScrollView(child: child))
          : child,
    ),
  ),
);
