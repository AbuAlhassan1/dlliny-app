import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/errors/chat_exceptions.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/repositories/chat_repository.dart';
import 'package:hangout/domain/dto/request/create_conversation_request.dart';
import 'package:hangout/domain/dto/request/send_message_request.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/presentation/chat/bloc/chat_inbox/chat_inbox_bloc.dart';
import 'package:hangout/presentation/chat/widgets/share_target.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';

class ShareTargetSheet extends StatefulWidget {
  final SharedResourceType resourceType;
  final String resourceId;
  final String? headlineLabel;

  const ShareTargetSheet({
    super.key,
    required this.resourceType,
    required this.resourceId,
    this.headlineLabel,
  });

  @override
  State<ShareTargetSheet> createState() => _ShareTargetSheetState();
}

class _ShareTargetSheetState extends State<ShareTargetSheet> {
  static const int _listPageSize = 50;
  static const int _searchLimit = 30;
  static const Duration _searchDebounce = Duration(milliseconds: 300);

  late final ChatRepository _repo = serviceLocator.get<ChatRepository>();
  late final ChatInboxBloc _inbox = serviceLocator.get<ChatInboxBloc>();
  late final ApiService _api = serviceLocator.get<ApiService>();

  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _captionCtrl = TextEditingController();

  final Map<String, ShareTarget> _selected = {};

  List<UserTarget> _following = const [];
  List<UserTarget> _followers = const [];
  List<VenueTarget> _venues = const [];
  bool _loadingSections = true;

  String _query = '';
  Timer? _searchDebounceTimer;
  bool _searchInFlight = false;
  List<ShareTarget> _searchResults = const [];

  bool _sending = false;
  String? _progressLabel;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onQueryChanged);
    _bootstrapSections();
  }

  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchCtrl.dispose();
    _captionCtrl.dispose();
    super.dispose();
  }

  String? get _viewerId => context.read<MyProfileBloc>().user?.id;

  Future<void> _bootstrapSections() async {
    final followingFuture =
        _api.getMyFollowing(page: 0, size: _listPageSize);
    final followersFuture =
        _api.getMyFollowers(page: 0, size: _listPageSize);
    final venuesFuture = _api.getFollowedVenues();

    final followingRes = await followingFuture;
    final followersRes = await followersFuture;
    final venuesRes = await venuesFuture;
    if (!mounted) return;

    setState(() {
      _following = (followingRes.success && followingRes.data != null)
          ? followingRes.data!.content
              .map(UserTarget.fromSummary)
              .toList(growable: false)
          : const [];
      _followers = (followersRes.success && followersRes.data != null)
          ? followersRes.data!.content
              .map(UserTarget.fromSummary)
              .toList(growable: false)
          : const [];
      _venues = (venuesRes.success && venuesRes.data != null)
          ? venuesRes.data!
              .map(VenueTarget.fromSummary)
              .toList(growable: false)
          : const [];
      _loadingSections = false;
    });
  }

  List<ConversationTarget> _recentChatsFromInbox(ChatInboxState s) {
    final viewerId = _viewerId;
    return s.conversations
        .where((c) => c.viewerRequestState == ChatRequestState.accepted)
        .map((c) {
          String? peerUserId;
          String? peerVenueId;
          if (c.type == ConversationType.direct) {
            for (final m in c.members) {
              if (m.memberId == viewerId) continue;
              if (m.memberType == ChatMemberType.venue) {
                peerVenueId = m.memberId;
              } else {
                peerUserId = m.memberId;
              }
              break;
            }
          }
          return ConversationTarget(
            conversation: c,
            peerUserId: peerUserId,
            peerVenueId: peerVenueId,
          );
        })
        .toList(growable: false);
  }

  ({Set<String> userIds, Set<String> venueIds}) _existingChatPeers(
    List<ConversationTarget> chats,
  ) {
    final userIds = <String>{};
    final venueIds = <String>{};
    for (final c in chats) {
      if (c.peerUserId != null) userIds.add(c.peerUserId!);
      if (c.peerVenueId != null) venueIds.add(c.peerVenueId!);
    }
    return (userIds: userIds, venueIds: venueIds);
  }

  void _onQueryChanged() {
    final raw = _searchCtrl.text.trim();
    if (raw == _query) return;
    setState(() => _query = raw);
    _searchDebounceTimer?.cancel();
    if (raw.length < 2) {
      setState(() {
        _searchResults = const [];
        _searchInFlight = false;
      });
      return;
    }
    _searchDebounceTimer = Timer(_searchDebounce, () => _runSearch(raw));
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    setState(() => _searchInFlight = true);
    try {
      final res = await _api.search(query, limit: _searchLimit);
      if (!mounted || _query != query) return;
      final data = res.data;
      if (!res.success || data == null) {
        setState(() {
          _searchResults = const [];
          _searchInFlight = false;
        });
        return;
      }
      final viewerId = _viewerId;
      final hits = <ShareTarget>[
        for (final u in data.users)
          if (u.id != viewerId) UserTarget.fromSearch(u),
        for (final v in data.venues) VenueTarget.fromSearch(v),
      ];
      setState(() {
        _searchResults = hits;
        _searchInFlight = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchResults = const [];
        _searchInFlight = false;
      });
    }
  }

  void _toggle(ShareTarget t) {
    setState(() {
      if (_selected.containsKey(t.stableKey)) {
        _selected.remove(t.stableKey);
      } else {
        _selected[t.stableKey] = t;
      }
    });
  }

  bool _isPicked(ShareTarget t) => _selected.containsKey(t.stableKey);

  Future<void> _send() async {
    if (_selected.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _progressLabel = LocaleKeys.chat_share_sheet_progress_sending.tr();
    });

    final caption = _captionCtrl.text.trim();
    final targets = _selected.values.toList(growable: false);
    int sent = 0;
    int failed = 0;

    for (var i = 0; i < targets.length; i++) {
      if (!mounted) return;
      setState(() => _progressLabel = LocaleKeys.chat_share_sheet_progress_step.tr(
            namedArgs: {'i': '${i + 1}', 'total': '${targets.length}'},
          ));
      try {
        final conversation = await _resolveConversation(targets[i]);
        if (conversation == null) {
          failed++;
          continue;
        }
        final server = await _repo.sendMessage(
          conversation.id,
          SendMessageRequest.share(
            resourceType: widget.resourceType,
            resourceId: widget.resourceId,
            caption: caption.isEmpty ? null : caption,
          ),
        );
        sent++;
        _bumpInbox(conversation, server);
      } on ChatException {
        failed++;
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    if (failed == 0) {
      appToast.success(LocaleKeys.chat_share_sheet_sent_count.plural(sent));
    } else {
      appToast.error(LocaleKeys.chat_share_sheet_sent_partial.tr(
        namedArgs: {'sent': '$sent', 'total': '${targets.length}'},
      ));
    }
  }

  Future<ConversationResponse?> _resolveConversation(ShareTarget t) async {
    switch (t) {
      case ConversationTarget c:
        return c.conversation;
      case UserTarget u:
        return _repo.createConversation(
          CreateConversationRequest(
            type: ConversationType.direct,
            participants: [
              Participant(type: ChatMemberType.user, id: u.id),
            ],
          ),
        );
      case VenueTarget v:
        return _repo.createConversation(
          CreateConversationRequest(
            type: ConversationType.direct,
            participants: [
              Participant(type: ChatMemberType.venue, id: v.id),
            ],
          ),
        );
    }
  }

  void _bumpInbox(ConversationResponse base, MessageResponse server) {
    final patched = ConversationResponse(
      id: base.id,
      type: base.type,
      title: base.title,
      avatarUrl: base.avatarUrl,
      members: base.members,
      lastMessage: server,
      unreadCount: 0,
      viewerRequestState: base.viewerRequestState,
      muted: base.muted,
      retentionDays: base.retentionDays,
      createdAt: base.createdAt,
      updatedAt: server.createdAt,
    );
    _inbox.add(InboxConversationUpdated(patched));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.c;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          color: t.surfaceElevated,
          height: MediaQuery.of(context).size.height * 0.85,
          child: Column(
            children: [
              _header(t),
              Divider(
                height: 1,
                color: t.border,
              ),
              Expanded(child: _body()),
              if (_selected.isNotEmpty) _footer(t),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(AppColors t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.onSurfaceDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(TablerIcons.send, color: t.onSurface, size: 18),
              const SizedBox(width: 8),
              Text(
                widget.headlineLabel ??
                    LocaleKeys.chat_share_sheet_default_headline.tr(),
                style: TextStyle(
                  color: t.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (_selected.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: t.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selected.length}',
                    style: TextStyle(
                      color: t.onPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchCtrl,
            style: TextStyle(color: t.onSurface),
            cursorColor: t.onSurface,
            decoration: InputDecoration(
              hintText: LocaleKeys.chat_share_sheet_people_search_hint.tr(),
              hintStyle: TextStyle(color: t.onSurfaceMuted),
              prefixIcon: Icon(
                TablerIcons.search,
                color: t.onSurfaceSecondary,
                size: 18,
              ),
              suffixIcon: _searchInFlight
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: t.onSurfaceSecondary,
                          strokeWidth: 1.5,
                        ),
                      ),
                    )
                  : (_query.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            TablerIcons.x,
                            color: t.onSurfaceSecondary,
                            size: 18,
                          ),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null),
              filled: true,
              fillColor: t.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 0,
                horizontal: 8,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    return BlocBuilder<ChatInboxBloc, ChatInboxState>(
      bloc: _inbox,
      builder: (context, inboxState) {
        if (_query.length >= 2) {
          return _SearchResultsList(
            isLoading: _searchInFlight,
            results: _searchResults,
            isPicked: _isPicked,
            onTap: _toggle,
            query: _query,
          );
        }

        final chats = _recentChatsFromInbox(inboxState);
        final existing = _existingChatPeers(chats);
        final filteredFollowing = _following
            .where((u) => !existing.userIds.contains(u.id))
            .toList(growable: false);
        final filteredFollowers = _followers
            .where((u) => !existing.userIds.contains(u.id))
            .toList(growable: false);
        final filteredVenues = _venues
            .where((v) => !existing.venueIds.contains(v.id))
            .toList(growable: false);

        return _SectionsList(
          recent: chats,
          following: filteredFollowing,
          followers: filteredFollowers,
          venues: filteredVenues,
          loadingSections: _loadingSections,
          isPicked: _isPicked,
          onTap: _toggle,
        );
      },
    );
  }

  Widget _footer(AppColors t) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: t.surfaceMuted,
          border: Border(
            top: BorderSide(
              color: t.border,
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_sending && _progressLabel != null) ...[
              Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: t.onSurface,
                      strokeWidth: 1.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _progressLabel!,
                    style: TextStyle(
                      color: t.onSurface,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _captionCtrl,
                    enabled: !_sending,
                    cursorColor: t.onSurface,
                    style: TextStyle(color: t.onSurface),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      hintText: LocaleKeys.chat_share_sheet_comment_hint.tr(),
                      hintStyle: TextStyle(color: t.onSurfaceMuted),
                      isDense: true,
                      border: InputBorder.none,
                    ),
                  ),
                ),
                Material(
                  color: t.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sending ? null : _send,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        TablerIcons.send,
                        color: t.onPrimary,
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionsList extends StatelessWidget {
  final List<ConversationTarget> recent;
  final List<UserTarget> following;
  final List<UserTarget> followers;
  final List<VenueTarget> venues;
  final bool loadingSections;
  final bool Function(ShareTarget) isPicked;
  final void Function(ShareTarget) onTap;

  const _SectionsList({
    required this.recent,
    required this.following,
    required this.followers,
    required this.venues,
    required this.loadingSections,
    required this.isPicked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sections = <_Section>[];
    if (recent.isNotEmpty) {
      sections.add(_Section(LocaleKeys.chat_share_sheet_section_recent.tr(), recent));
    }
    if (following.isNotEmpty) {
      sections.add(_Section(LocaleKeys.chat_share_sheet_section_following.tr(), following));
    }
    if (followers.isNotEmpty) {
      sections.add(_Section(LocaleKeys.chat_share_sheet_section_followers.tr(), followers));
    }
    if (venues.isNotEmpty) {
      sections.add(_Section(LocaleKeys.chat_share_sheet_section_venues.tr(), venues));
    }

    if (sections.isEmpty) {
      final t = context.c;
      return Center(
        child: loadingSections
            ? SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: t.onSurface,
                  strokeWidth: 1.5,
                ),
              )
            : Text(
                LocaleKeys.chat_share_sheet_empty_targets.tr(),
                style: TextStyle(color: t.onSurfaceSecondary),
              ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final s = sections[i];
        return _SectionBlock(
          title: s.title,
          targets: s.targets,
          isPicked: isPicked,
          onTap: onTap,
        );
      },
    );
  }
}

class _Section {
  final String title;
  final List<ShareTarget> targets;
  _Section(this.title, this.targets);
}

class _SectionBlock extends StatelessWidget {
  final String title;
  final List<ShareTarget> targets;
  final bool Function(ShareTarget) isPicked;
  final void Function(ShareTarget) onTap;

  const _SectionBlock({
    required this.title,
    required this.targets,
    required this.isPicked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(
            title,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
        ),
        for (final t in targets)
          _TargetRow(
            target: t,
            selected: isPicked(t),
            onTap: () => onTap(t),
          ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _SearchResultsList extends StatelessWidget {
  final bool isLoading;
  final List<ShareTarget> results;
  final bool Function(ShareTarget) isPicked;
  final void Function(ShareTarget) onTap;
  final String query;

  const _SearchResultsList({
    required this.isLoading,
    required this.results,
    required this.isPicked,
    required this.onTap,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (isLoading && results.isEmpty) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: c.onSurface,
            strokeWidth: 1.5,
          ),
        ),
      );
    }
    if (results.isEmpty) {
      return Center(
        child: Text(
          LocaleKeys.chat_share_sheet_no_results_for.tr(
            namedArgs: {'query': query},
          ),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
      );
    }
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: results.length,
      itemBuilder: (context, i) {
        return _TargetRow(
          target: results[i],
          selected: isPicked(results[i]),
          onTap: () => onTap(results[i]),
        );
      },
    );
  }
}

class _TargetRow extends StatelessWidget {
  final ShareTarget target;
  final bool selected;
  final VoidCallback onTap;

  const _TargetRow({
    required this.target,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            _Avatar(
              url: target.avatarUrl,
              isGroup: target.isGroup,
              isVenue: target is VenueTarget,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          target.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (_isVerified(target)) ...[
                        const SizedBox(width: 4),
                        Icon(
                          TablerIcons.rosette_discount_check_filled,
                          color: c.success,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                  if (target.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      target.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            _Checkbox(checked: selected),
          ],
        ),
      ),
    );
  }

  bool _isVerified(ShareTarget t) {
    if (t is UserTarget) return t.verified;
    if (t is VenueTarget) return t.verified;
    return false;
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final bool isGroup;
  final bool isVenue;
  const _Avatar({
    required this.url,
    required this.isGroup,
    required this.isVenue,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fallback = isGroup
        ? TablerIcons.users
        : (isVenue ? TablerIcons.map_pin : TablerIcons.user);
    return Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.divider,
        shape: BoxShape.circle,
      ),
      child: (url != null && url!.isNotEmpty)
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              memCacheWidth: 132,
              errorWidget: (_, _, _) => Icon(
                fallback,
                color: c.onSurfaceSecondary,
                size: 20,
              ),
            )
          : Icon(fallback, color: c.onSurfaceSecondary, size: 20),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  const _Checkbox({required this.checked});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: checked ? c.primary : Colors.transparent,
        border: Border.all(
          color: checked ? c.primary : c.onSurfaceSecondary,
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: checked
          ? Icon(TablerIcons.check, color: c.onPrimary, size: 14)
          : null,
    );
  }
}
