import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/controller/hangouts/my_hangouts_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/hangout_thumbnail.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class HangoutsGrid extends StatelessWidget {
  const HangoutsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MyHangoutsBloc, MyHangoutsState>(
      builder: (context, state) {
        final bloc = context.read<MyHangoutsBloc>();
        final hangouts = bloc.myHangouts;

        if (state is MyHangoutsLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: c.onSurface,
              strokeWidth: 1,
            ),
          );
        }

        if (state is MyHangoutsError) {
          return Center(child: Text(state.message));
        }

        if (hangouts.isEmpty) {
          return Center(child: Text(LocaleKeys.profile_empty_hangouts.tr()));
        }

        return PagedGridView<int, HangoutResponse>(
          padding: EdgeInsets.zero,
          builderDelegate: PagedChildBuilderDelegate(
            itemBuilder: (context, item, index) => HangoutThumbnail(hangout: item),
            newPageProgressIndicatorBuilder: (_) => Center(
              child: CircularProgressIndicator(
                color: c.onSurface,
                strokeWidth: 1,
              ),
            ),
            newPageErrorIndicatorBuilder: (_) => Center(
              child: Text(
                state is MyHangoutsMoreError
                    ? state.message
                    : 'Error loading more hangouts',
              ),
            ),
          ),
          state: PagingState(
            pages: [hangouts],
            keys: [0],
            isLoading: state is MyHangoutsMoreLoading,
            hasNextPage: false,
            error: state is MyHangoutsMoreError ? state.message : null,
          ),
          fetchNextPage: () {
            if (state is! MyHangoutsMoreLoading) {
              context.read<MyHangoutsBloc>().add(GetMoreHangouts());
            }
          },
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 2,
            crossAxisSpacing: 2,
            childAspectRatio: 4/6
          ),
        );
      },
    );
  }
}
