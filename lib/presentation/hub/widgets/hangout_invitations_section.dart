import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';
import 'package:hangout/presentation/hub/controllers/my_invitations/my_invitations_bloc.dart';

class HangoutInvitationsSection extends StatelessWidget {
  const HangoutInvitationsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MyInvitationsBloc, MyInvitationsState>(
      builder: (context, state) {
        if (state is! MyInvitationsLoaded || state.items.isEmpty) {
          return const SizedBox.shrink();
        }
        final c = context.c;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 15, end: 15),
                child: Row(
                  children: [
                    Icon(TablerIcons.mail_opened, size: 22, color: c.onSurface),
                    const SizedBox(width: 6),
                    Text(
                      context.pickBilingual(
                        ar: 'دعواتك للطلعات',
                        en: 'Your invitations',
                      ),
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        '${state.items.length}',
                        style: TextStyle(
                          color: c.onPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              for (final invite in state.items)
                _InvitationCard(
                  invite: invite,
                  responding: state.responding.contains(invite.id),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _InvitationCard extends StatelessWidget {
  final InvitationResponse invite;
  final bool responding;
  const _InvitationCard({required this.invite, required this.responding});

  void _open(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HangoutDetailsPageWrapper(hangoutId: invite.hangoutId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final venueName =
        context.pickBilingual(ar: invite.venueNameAr, en: invite.venueNameEn);
    final dt = DateTime.tryParse(invite.hangoutScheduledAt)?.toLocal();
    final started = dt != null && dt.isBefore(DateTime.now());
    final whenLabel = dt == null
        ? null
        : DateFormat('EEEE d MMM • h:mm a', context.locale.toString())
            .format(dt);

    return Container(
      margin: const EdgeInsets.fromLTRB(15, 0, 15, 12),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.border, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => _open(context),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.surfaceMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(TablerIcons.calendar_event,
                        color: c.primary, size: 22),
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
                                venueName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: c.onSurface,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'IBMPlexSansArabic',
                                ),
                              ),
                            ),
                            if (started) ...[
                              const SizedBox(width: 6),
                              _Badge(
                                text: context.pickBilingual(
                                    ar: 'جارية', en: 'Live'),
                                color: c.success,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.pickBilingual(
                            ar: 'دعاك @${invite.invitedByUsername}',
                            en: 'Invited by @${invite.invitedByUsername}',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                        if (whenLabel != null) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(TablerIcons.clock,
                                  size: 13, color: c.onSurfaceMuted),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  whenLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.onSurfaceMuted,
                                    fontSize: 12,
                                    fontFamily: 'IBMPlexSansArabic',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (invite.message != null &&
                            invite.message!.trim().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            invite.message!.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: c.onSurface,
                              fontSize: 13,
                              height: 1.35,
                              fontFamily: 'IBMPlexSansArabic',
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: responding
                        ? null
                        : () => context
                            .read<MyInvitationsBloc>()
                            .add(RespondMyInvitation(invite.id, accept: true)),
                    style: FilledButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: responding
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: c.onPrimary),
                          )
                        : Text(
                            context.pickBilingual(ar: 'انضم', en: 'Join'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'IBMPlexSansArabic',
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: responding
                        ? null
                        : () => context
                            .read<MyInvitationsBloc>()
                            .add(RespondMyInvitation(invite.id, accept: false)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: c.onSurfaceSecondary,
                      side: BorderSide(color: c.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: Text(
                      context.pickBilingual(ar: 'رفض', en: 'Reject'),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}
