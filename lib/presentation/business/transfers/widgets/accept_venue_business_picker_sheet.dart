import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

Future<BusinessAccess?> showAcceptVenueBusinessPickerSheet(
  BuildContext context, {
  required List<BusinessAccess> businesses,
}) {
  return showModalBottomSheet<BusinessAccess>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _AcceptVenueBusinessPickerSheet(businesses: businesses),
  );
}

class _AcceptVenueBusinessPickerSheet extends StatelessWidget {
  final List<BusinessAccess> businesses;
  const _AcceptVenueBusinessPickerSheet({required this.businesses});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final mq = MediaQuery.of(context);
    return Container(
      constraints: BoxConstraints(maxHeight: mq.size.height * 0.7),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: c.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                LocaleKeys.business_transfers_accept_picker_title.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                LocaleKeys.business_transfers_accept_picker_subtitle.tr(),
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 12),
                  itemCount: businesses.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = businesses[index];
                    return _BusinessOption(
                      business: b,
                      onTap: () => Navigator.of(context).pop(b),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BusinessOption extends StatelessWidget {
  final BusinessAccess business;
  final VoidCallback onTap;
  const _BusinessOption({required this.business, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = business.companyName ??
        LocaleKeys.business_transfers_any_business_fallback.tr();
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
              ),
              child: _LogoPlaceholder(
                business: business,
                fallback: Icon(
                  TablerIcons.briefcase,
                  color: c.onSurfaceSecondary,
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    (business.verified
                            ? LocaleKeys.business_transfers_verified_account
                            : LocaleKeys.business_transfers_any_business_label)
                        .tr(),
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              TablerIcons.chevron_left,
              color: c.onSurfaceMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  final BusinessAccess business;
  final Widget fallback;
  const _LogoPlaceholder({required this.business, required this.fallback});

  @override
  Widget build(BuildContext context) => Center(child: fallback);
}
