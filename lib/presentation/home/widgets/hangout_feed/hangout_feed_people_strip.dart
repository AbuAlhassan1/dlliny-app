import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/feed_response.dart';

class HangoutFeedPeopleStrip extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<HangoutAttendee> people;

  final bool dimmed;

  final ValueChanged<HangoutAttendee> onTapPerson;

  const HangoutFeedPeopleStrip({
    super.key,
    required this.label,
    required this.icon,
    required this.people,
    required this.dimmed,
    required this.onTapPerson,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 13,
              color: dimmed ? c.onSurfaceSecondary : c.onSurface,
            ),
            const SizedBox(width: 6),
            Text(
              '$label · ${people.length}',
              style: TextStyle(
                color: dimmed ? c.onSurfaceSecondary : c.onSurface,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            physics: const BouncingScrollPhysics(),
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final p = people[index];
              return _PersonTile(
                person: p,
                dimmed: dimmed,
                onTap: () => onTapPerson(p),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PersonTile extends StatelessWidget {
  final HangoutAttendee person;
  final bool dimmed;
  final VoidCallback onTap;

  const _PersonTile({
    required this.person,
    required this.dimmed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final label = person.displayName?.isNotEmpty == true
        ? person.displayName!
        : person.username;
    return SizedBox(
      width: 60,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: dimmed ? 0.65 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: Container(
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.surfaceMuted,
                    border: dimmed
                        ? Border.all(
                            color: c.onSurface.withValues(alpha: 0.25),
                            width: 1,
                          )
                        : null,
                  ),
                  child: (person.avatarUrl != null &&
                          person.avatarUrl!.isNotEmpty)
                      ? CachedNetworkImage(
                          imageUrl: person.avatarUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Icon(
                            Icons.person,
                            color: c.onSurface,
                            size: 18,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: c.onSurface,
                          size: 18,
                        ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                person.username,
                maxLines: 1,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
