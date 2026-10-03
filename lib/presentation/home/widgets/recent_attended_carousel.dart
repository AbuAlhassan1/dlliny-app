import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/presentation/home/controllers/recent_attended/recent_attended_bloc.dart';
import 'package:hangout/presentation/home/widgets/recent_attended/recent_attended_card.dart';
import 'package:hangout/presentation/home/widgets/recent_attended/recent_attended_loading_row.dart';
import 'package:hangout/presentation/home/widgets/recent_attended/recent_attended_section_header.dart';

class RecentAttendedCarousel extends StatelessWidget {
  const RecentAttendedCarousel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecentAttendedBloc, RecentAttendedState>(
      builder: (context, state) {
        if (state is RecentAttendedInitial ||
            state is RecentAttendedEmpty ||
            state is RecentAttendedError) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const RecentAttendedSectionHeader(),
              const SizedBox(height: 10),
              switch (state) {
                RecentAttendedLoading() => const RecentAttendedLoadingRow(),
                RecentAttendedLoaded(:final items) => _LoadedRow(items: items),
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        );
      },
    );
  }
}

class _LoadedRow extends StatelessWidget {
  final List<HangoutResponse> items;
  const _LoadedRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: RecentAttendedCard.height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
        itemCount: items.length,
        clipBehavior: Clip.none,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) =>
            RecentAttendedCard(hangout: items[index]),
      ),
    );
  }
}
