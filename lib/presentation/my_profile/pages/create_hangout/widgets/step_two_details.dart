import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/branch_picker_field.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/create_hangout_textfield.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/invitee_picker_field.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/section_label.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/segmented_selector.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/selected_venue_card.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/venue_search_field.dart';

class StepTwoDetails extends StatelessWidget {
  final String postVisibility;
  final ValueChanged<String> onPostVisibilityChanged;

  final TextEditingController descriptionController;

  final VenueSearchResultDto? selectedVenue;
  final VenueResponse? selectedVenueDetails;
  final bool venueDetailsLoading;
  final ValueChanged<VenueSearchResultDto> onVenuePicked;
  final VoidCallback onVenueCleared;

  final VenueLocationResponse? selectedBranch;
  final ValueChanged<VenueLocationResponse> onBranchPicked;

  final DateTime? scheduledAt;
  final VoidCallback onPickDateTime;

  final String joinPolicy;
  final ValueChanged<String> onJoinPolicyChanged;

  final List<UserSearchResultDto> invitees;
  final ValueChanged<List<UserSearchResultDto>> onInviteesChanged;
  final TextEditingController inviteMessageController;

  const StepTwoDetails({
    super.key,
    required this.postVisibility,
    required this.onPostVisibilityChanged,
    required this.descriptionController,
    required this.selectedVenue,
    required this.selectedVenueDetails,
    required this.venueDetailsLoading,
    required this.onVenuePicked,
    required this.onVenueCleared,
    required this.selectedBranch,
    required this.onBranchPicked,
    required this.scheduledAt,
    required this.onPickDateTime,
    required this.joinPolicy,
    required this.onJoinPolicyChanged,
    required this.invitees,
    required this.onInviteesChanged,
    required this.inviteMessageController,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionLabel(label: LocaleKeys.hangout_create_section_audience.tr()),
            const SizedBox(height: 6),
            SegmentedSelector<String>(
              options: [
                SegmentOption(value: 'PUBLIC', label: LocaleKeys.hangout_create_audience_public.tr()),
                SegmentOption(value: 'FOLLOWERS', label: LocaleKeys.hangout_create_audience_followers.tr()),
                SegmentOption(value: 'INVITEES', label: LocaleKeys.hangout_create_audience_invitees.tr()),
              ],
              selected: postVisibility,
              onChanged: onPostVisibilityChanged,
            ),

            const SizedBox(height: 12),

            CreateHangoutTextfield(
              controller: descriptionController,
              hint: LocaleKeys.hangout_create_description_hint.tr(),
              label: LocaleKeys.hangout_create_description_label.tr(),
              maxLines: 3,
            ),

            const SizedBox(height: 12),

            if (selectedVenue != null) ...[
              SelectedVenueCard(
                fallbackNameAr: selectedVenue!.nameAr,
                fallbackNameEn: selectedVenue!.nameEn,
                details: selectedVenueDetails,
                loading: venueDetailsLoading,
                onClear: onVenueCleared,
              ),
              const SizedBox(height: 12),
            ],

            if (_showsBranchPicker(selectedVenueDetails)) ...[
              SectionLabel(label: LocaleKeys.hangout_create_branch_label.tr()),
              const SizedBox(height: 6),
              BranchPickerField(
                branches: selectedVenueDetails!.locations,
                selected: selectedBranch,
                onChanged: onBranchPicked,
              ),
              const SizedBox(height: 12),
            ],

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: VenueSearchField(
                    selectedVenue: selectedVenue,
                    onVenueSelected: onVenuePicked,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _DatePickerField(
                    scheduledAt: scheduledAt,
                    onTap: onPickDateTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            SectionLabel(label: LocaleKeys.hangout_create_section_join.tr()),
            const SizedBox(height: 6),
            SegmentedSelector<String>(
              options: [
                SegmentOption(value: 'OPEN', label: LocaleKeys.hangout_create_policy_open.tr()),
                SegmentOption(value: 'INVITE_ONLY', label: LocaleKeys.hangout_create_policy_invite_only.tr()),
              ],
              selected: joinPolicy,
              onChanged: onJoinPolicyChanged,
            ),

            const SizedBox(height: 12),

            InviteePickerField(
              selected: invitees,
              onChanged: onInviteesChanged,
            ),

            if (invitees.isNotEmpty) ...[
              const SizedBox(height: 12),
              CreateHangoutTextfield(
                controller: inviteMessageController,
                hint: LocaleKeys.hangout_create_invite_message_hint.tr(),
                label: LocaleKeys.hangout_create_invite_message_label.tr(),
                maxLines: 2,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

bool _showsBranchPicker(VenueResponse? details) {
  if (details == null) return false;
  return details.locations.length >= 2;
}

class _DatePickerField extends StatelessWidget {
  final DateTime? scheduledAt;
  final VoidCallback onTap;
  const _DatePickerField({required this.scheduledAt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: c.borderStrong,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(TablerIcons.calendar, size: 18, color: c.onSurfaceSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                scheduledAt == null
                    ? LocaleKeys.hangout_create_datetime_placeholder.tr()
                    : '${scheduledAt!.day}/${scheduledAt!.month} ${scheduledAt!.hour.toString().padLeft(2, '0')}:${scheduledAt!.minute.toString().padLeft(2, '0')}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: scheduledAt == null
                      ? c.onSurfaceMuted
                      : c.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
