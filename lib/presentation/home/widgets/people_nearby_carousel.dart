import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/domain/dto/response/follow_action_response.dart';
import 'package:hangout/domain/dto/response/nearby_suggestion_response.dart';
import 'package:hangout/presentation/home/controllers/people_nearby/people_nearby_bloc.dart';
import 'package:hangout/presentation/home/widgets/people_nearby/people_nearby_card.dart';
import 'package:hangout/presentation/home/widgets/people_nearby/people_nearby_enable_card.dart';
import 'package:hangout/presentation/home/widgets/people_nearby/people_nearby_section_header.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';

class PeopleNearbyCarousel extends StatelessWidget {
  const PeopleNearbyCarousel({super.key});

  @override
  Widget build(BuildContext context) => const _PeopleNearbyView();
}

class _PeopleNearbyView extends StatelessWidget {
  const _PeopleNearbyView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeopleNearbyBloc, PeopleNearbyState>(
      builder: (context, state) {
        if (state is PeopleNearbyInitial ||
            state is PeopleNearbyLoading ||
            state is PeopleNearbyEmpty ||
            state is PeopleNearbyError) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PeopleNearbySectionHeader(),
              const SizedBox(height: 10),
              switch (state) {
                PeopleNearbyNeedsOptIn() => const _EnableSlot(busy: false),
                PeopleNearbyEnabling() => const _EnableSlot(busy: true),
                PeopleNearbyLoaded(:final people, :final followed) =>
                  _LoadedRow(people: people, followed: followed),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        );
      },
    );
  }
}

class _EnableSlot extends StatelessWidget {
  final bool busy;
  const _EnableSlot({required this.busy});

  @override
  Widget build(BuildContext context) {
    return PeopleNearbyEnableCard(
      busy: busy,
      onEnable: () =>
          context.read<PeopleNearbyBloc>().add(EnableNearbyDiscovery()),
    );
  }
}

class _LoadedRow extends StatelessWidget {
  final List<NearbySuggestionResponse> people;

  final Map<String, FollowStatus> followed;

  const _LoadedRow({required this.people, required this.followed});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PeopleNearbyBloc>();
    return SizedBox(
      height: PeopleNearbyCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: people.length,
        clipBehavior: Clip.none,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final person = people[index];
          return PeopleNearbyCard(
            key: ValueKey(person.userId),
            person: person,
            followStatus: followed[person.userId],
            onFollow: () => bloc.add(FollowPerson(person.userId)),
            onDismiss: () => bloc.add(DismissPerson(person.userId)),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProfilePageWrapper(username: person.username),
              ),
            ),
          );
        },
      ),
    );
  }
}
