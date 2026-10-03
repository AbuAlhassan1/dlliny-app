import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/user_summary_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/controller/followers_following/followers_following_bloc.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';

Future<void> showFollowersFollowingSheet({
  required BuildContext context,
  required FollowKind kind,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => FollowersFollowingBloc(kind)..add(GetFollowList()),
      child: _FollowersFollowingSheet(kind: kind),
    ),
  );
}

class _FollowersFollowingSheet extends StatefulWidget {
  final FollowKind kind;
  const _FollowersFollowingSheet({required this.kind});

  @override
  State<_FollowersFollowingSheet> createState() =>
      _FollowersFollowingSheetState();
}

class _FollowersFollowingSheetState extends State<_FollowersFollowingSheet> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final next = _searchController.text.trim().toLowerCase();
      if (next != _query) setState(() => _query = next);
    });
    _scrollController.addListener(_maybeFetchMore);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeFetchMore() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<FollowersFollowingBloc>().add(GetMoreFollowList());
    }
  }

  String get _title => switch (widget.kind) {
        FollowKind.followers =>
          LocaleKeys.profile_my_followers_sheet_title_followers.tr(),
        FollowKind.following =>
          LocaleKeys.profile_my_followers_sheet_title_following.tr(),
      };

  List<UserSummaryResponse> _filter(List<UserSummaryResponse> users) {
    if (_query.isEmpty) return users;
    return users.where((u) {
      final username = (u.username ?? '').toLowerCase();
      final display = (u.displayName ?? '').toLowerCase();
      return username.contains(_query) || display.contains(_query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sheetController) {
        return Container(
          decoration: BoxDecoration(
            color: c.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: c.onSurfaceDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _title,
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Divider(height: 16, color: c.divider),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: c.onSurface),
                  cursorColor: c.onSurface,
                  decoration: InputDecoration(
                    hintText: LocaleKeys.common_search_hint.tr(),
                    hintStyle: TextStyle(color: c.onSurfaceMuted),
                    prefixIcon: Icon(TablerIcons.search,
                        color: c.onSurfaceMuted, size: 18),
                    suffixIcon: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, _) {
                        if (value.text.isEmpty) return const SizedBox.shrink();
                        return IconButton(
                          icon: Icon(TablerIcons.x,
                              color: c.onSurfaceMuted, size: 16),
                          onPressed: () => _searchController.clear(),
                        );
                      },
                    ),
                    filled: true,
                    fillColor: c.border,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              Expanded(
                child:
                    BlocBuilder<FollowersFollowingBloc, FollowersFollowingState>(
                  builder: (context, state) {
                    final bloc = context.read<FollowersFollowingBloc>();
                    if (state is FollowersFollowingLoading &&
                        bloc.users.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: c.onSurface,
                          strokeWidth: 1,
                        ),
                      );
                    }
                    if (state is FollowersFollowingError && bloc.users.isEmpty) {
                      return Center(
                        child: Text(
                          state.message,
                          style: TextStyle(color: c.onSurfaceSecondary),
                        ),
                      );
                    }
                    final filtered = _filter(bloc.users);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          _query.isEmpty
                              ? LocaleKeys
                                    .profile_my_followers_sheet_empty_no_followers
                                    .tr()
                              : LocaleKeys.common_no_results.tr(),
                          style: TextStyle(color: c.onSurfaceSecondary),
                        ),
                      );
                    }
                    return ListView.separated(
                      controller: _scrollController,
                      padding: EdgeInsets.zero,
                      itemCount: filtered.length +
                          (state is FollowersFollowingMoreLoading ? 1 : 0),
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: c.border,
                      ),
                      itemBuilder: (context, i) {
                        if (i == filtered.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: c.onSurface,
                                  strokeWidth: 1.5,
                                ),
                              ),
                            ),
                          );
                        }
                        return _UserTile(user: filtered[i]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UserTile extends StatelessWidget {
  final UserSummaryResponse user;
  const _UserTile({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: () {
        final username = user.username;
        if (username == null) return;
        final navigator = Navigator.of(context);
        navigator.pop();
        navigator.push(
          MaterialPageRoute(
            builder: (_) => ProfilePageWrapper(username: username),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: c.surfaceMuted,
              backgroundImage: user.avatarUrl != null
                  ? CachedNetworkImageProvider(user.avatarUrl!)
                  : null,
              child: user.avatarUrl == null
                  ? Icon(Icons.person, color: c.onSurface, size: 20)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName ?? user.username ?? '',
                          style: TextStyle(
                            color: c.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (user.verified)
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(TablerIcons.rosette_discount_check_filled,
                              color: Colors.blue, size: 16),
                        ),
                    ],
                  ),
                  if (user.username != null)
                    Text(
                      '@${user.username}',
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
