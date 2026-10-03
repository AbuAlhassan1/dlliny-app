import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_moving_background/flutter_moving_background.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/challenge_list_item_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/challenges/controllers/challenges_list/challenges_list_bloc.dart';
import 'package:hangout/presentation/challenges/pages/challenge_detail_page_wrapper.dart';
import 'package:hangout/presentation/challenges/pages/challenges_page_wrapper.dart';
import 'package:hangout/presentation/challenges/widgets/challenge_card.dart';

class ChallengesIsland extends StatelessWidget {
  static const double _height = 200;

  const ChallengesIsland({super.key});

  Future<void> _openChallenges(BuildContext context) async {
    final bloc = context.read<ChallengesListBloc>();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChallengesPageWrapper()));
    bloc.add(const LoadChallenges());
  }

  Future<void> _openDetail(BuildContext context, String challengeId) async {
    final bloc = context.read<ChallengesListBloc>();
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChallengeDetailPageWrapper(challengeId: challengeId),
      ),
    );
    bloc.add(const LoadChallenges());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChallengesListBloc, ChallengesListState>(
      builder: (context, state) {
        final c = context.c;
        final items =
            state.byCadence[null] ?? const <ChallengeListItemResponse>[];
        if (items.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: RepaintBoundary(
            child: SizedBox(
              height: _height,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        const Positioned.fill(
                          child: MovingBackground(
                            backgroundColor: Colors.transparent,
                            animationType: AnimationType.moveAndFade,
                            duration: Duration(milliseconds: 4000),
                            circles: [
                              MovingCircle(
                                color: Colors.orangeAccent,
                                radius: 150,
                              ),
                              MovingCircle(color: Colors.white, radius: 150),
                              MovingCircle(color: Colors.yellow, radius: 150),
                              MovingCircle(color: Colors.pink, radius: 150),
                              MovingCircle(color: Colors.red, radius: 150),
                            ],
                          ),
                        ),
                        Positioned.fill(
                          child: _ExpandedPanel(
                            items: items,
                            onSeeAll: () => _openChallenges(context),
                            onCardTap: (id) => _openDetail(context, id),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: c.divider),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ExpandedPanel extends StatelessWidget {
  final List<ChallengeListItemResponse> items;
  final VoidCallback onSeeAll;
  final ValueChanged<String> onCardTap;

  const _ExpandedPanel({
    required this.items,
    required this.onSeeAll,
    required this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(18, 8, 8, 0),
          child: Row(
            children: [
              Icon(TablerIcons.trophy, size: 18, color: c.onSurface),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.challenges_hub_section_title.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: onSeeAll,
                child: Text(
                  LocaleKeys.challenges_hub_section_see_all.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        Expanded(
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsetsDirectional.only(start: 14, end: 14),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              return SizedBox(
                width: 210,
                child: ChallengeCard(
                  item: item,
                  onTap: () => onCardTap(item.id),
                ),
              );
            },
          ),
        ),

        SizedBox(height: 15),
      ],
    );
  }
}
