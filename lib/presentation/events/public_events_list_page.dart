import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/presentation/events/controllers/public_events_bloc.dart';
import 'package:hangout/presentation/events/public_event_detail_page.dart';
import 'package:hangout/presentation/events/widgets/event_card.dart';

class PublicEventsListPage extends StatelessWidget {
  const PublicEventsListPage({super.key});

  static Future<void> push(
    BuildContext context, {
    required PublicEventsBloc bloc,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: bloc,
          child: const PublicEventsListPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(
          context.pickBilingual(ar: 'الفعاليات', en: 'Events'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
      body: BlocBuilder<PublicEventsBloc, PublicEventsState>(
        builder: (context, state) {
          if (state is PublicEventsLoading || state is PublicEventsInitial) {
            return Center(
              child: CircularProgressIndicator(color: c.primary, strokeWidth: 2),
            );
          }
          if (state is PublicEventsError) {
            return _Message(
              icon: TablerIcons.alert_triangle,
              text: context.pickBilingual(
                ar: 'تعذّر تحميل الفعاليات',
                en: 'Could not load events',
              ),
            );
          }
          final events = (state as PublicEventsLoaded).events;
          if (events.isEmpty) {
            return _Message(
              icon: TablerIcons.calendar_off,
              text: context.pickBilingual(
                ar: 'لا توجد فعاليات حالياً',
                en: 'No events right now',
              ),
            );
          }
          return RefreshIndicator(
            color: c.primary,
            onRefresh: () async =>
                context.read<PublicEventsBloc>().add(LoadPublicEvents()),
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(15),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemCount: events.length,
              itemBuilder: (context, i) {
                final e = events[i];
                return EventCard(
                  event: e,
                  onTap: () => PublicEventDetailPage.push(context, e),
                  onToggleInterest: () => context
                      .read<PublicEventsBloc>()
                      .add(ToggleEventInterest(e.id)),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Message({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.onSurfaceMuted, size: 44),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 14,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
