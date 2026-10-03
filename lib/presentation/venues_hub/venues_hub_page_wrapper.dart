import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/home/controllers/nearby_venues/nearby_venues_bloc.dart';
import 'package:hangout/presentation/hub/controllers/intents/intents_bloc.dart';
import 'package:hangout/presentation/hub/widgets/intents_section.dart';
import 'package:hangout/presentation/venues_hub/widgets/venues_hub_sections.dart';

class VenuesHubPageWrapper extends StatelessWidget {
  const VenuesHubPageWrapper({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VenuesHubPageWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => NearbyVenuesBloc()..add(LoadNearbyVenues(limit: 30)),
        ),
        BlocProvider(
          create: (_) => HubIntentsBloc()..add(LoadIntents()),
        ),
      ],
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          backgroundColor: c.background,
          foregroundColor: c.onSurface,
          elevation: 0,
          title: Text(
            context.pickBilingual(ar: 'الأماكن', en: 'Venues'),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
        body: ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(top: 4, bottom: 32),
          children: const [
            NearbyVenuesRail(),
            TrendingVenuesSection(),
            FeaturedCollectionsSection(),
            IntentsSection(),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.pickBilingual(
                    ar: 'دليلك للأماكن',
                    en: 'Your guide to places',
                  ),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'IBMPlexSansArabic',
                    shadows: [Shadow(color: Colors.black38, blurRadius: 6)],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.pickBilingual(
                    ar: 'اكتشف، قارن، وقرر وين تطلع',
                    en: 'Discover, compare, and pick where to go',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'IBMPlexSansArabic',
                    shadows: const [
                      Shadow(color: Colors.black38, blurRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: const Icon(
              TablerIcons.compass,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
