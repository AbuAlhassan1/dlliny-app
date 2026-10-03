import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/events/controllers/public_events_bloc.dart';
import 'package:hangout/presentation/events/public_event_detail_page.dart';
import 'package:hangout/presentation/events/public_events_list_page.dart';
import 'package:hangout/presentation/events/widgets/event_card.dart';

class PublicEventsSection extends StatelessWidget {
  const PublicEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PublicEventsBloc, PublicEventsState>(
      builder: (context, state) {
        if (state is! PublicEventsLoaded || state.events.isEmpty) {
          return const SizedBox.shrink();
        }
        final c = context.c;
        final events = state.events;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 15, end: 15),
                child: Row(
                  children: [
                    Icon(TablerIcons.calendar_star, size: 22, color: c.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      context.pickBilingual(ar: 'الفعاليات', en: 'Events'),
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => PublicEventsListPage.push(
                        context,
                        bloc: context.read<PublicEventsBloc>(),
                      ),
                      child: Text(
                        context.pickBilingual(ar: 'الكل', en: 'See all'),
                        style: TextStyle(
                          color: c.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 250,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsetsDirectional.only(start: 15, end: 15),
                  itemCount: events.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final e = events[i];
                    return SizedBox(
                      width: 190,
                      child: EventCard(
                        event: e,
                        onTap: () => PublicEventDetailPage.push(context, e),
                        onToggleInterest: () => context
                            .read<PublicEventsBloc>()
                            .add(ToggleEventInterest(e.id)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
