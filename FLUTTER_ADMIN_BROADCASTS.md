# Admin Broadcasts — Flutter Implementation Spec

What needs to ship on the Flutter side for the admin-broadcast notification feature (backend V82 + V83).

**Scope of this app**: the Flutter app is for **end users + venue owners / managers / staff**. Admins compose and send broadcasts from a separate dashboard (not Flutter); the Flutter app only **receives and renders** them. Every section below is about reception.

Two categories of work:
- **A** — render incoming broadcasts (mandatory for any user)
- **B** — close a separate gap V82 introduced around user city/district (mandatory for city/district broadcasts to reach the right users)

---

## Background — who in the Flutter app receives what

Admins target broadcasts to one of four audience types. From the Flutter app's perspective, **the audience type doesn't matter** — the recipient just gets a push + in-app row tagged `type == 'admin_broadcast'`. But knowing the targeting helps you reason about who sees what:

| Server audience type | Flutter recipients in this app |
|---|---|
| `USER` | The single targeted user |
| `VENUE` | Owners + managers of one venue (NOT staff — server query filters to `owner`/`manager` roles only) |
| `CITY` | Every active user whose `city_id` matches |
| `DISTRICT` | Every active user whose `district_id` matches |

Everyone excluded server-side: ghost users, banned users, soft-deleted users, inactive users — they never receive anything regardless of audience type.

The delivery is **dual-channel**:
- A push notification (FCM) on the recipient's device
- An in-app notification row in the bell-icon list

---

## DTOs that exist (and don't need consuming)

You'll see these in `lib/domain/dto/`:

- `request/broadcast_request.dart` — `BroadcastRequest` + `BroadcastAudienceType` enum
- `response/audience_preview_response.dart` — `AudiencePreviewResponse`
- `response/admin_broadcast_response.dart` — `AdminBroadcastResponse` + `BroadcastStatus` enum

Plus four Retrofit methods in `lib/data/api/api_service.dart`:
- `adminPreviewBroadcastAudience(...)`
- `adminSendBroadcast(...)`
- `adminListBroadcasts(...)`
- `adminGetBroadcast(...)`

These exist because `api_service.dart` is the single Retrofit interface. **The mobile app should never call them** — they're for the separate admin dashboard project. If you want them gone from the mobile codebase for cleanliness, say so and I'll strip them out (currently they're harmless dead code that the Retrofit generator still compiles).

What the **mobile app DOES consume** for this feature is the existing notification surface — `NotificationResponse`, the bell-icon list, the FCM handler. No new endpoint calls.

**Mandatory first step**:

```bash
cd hangout_app
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates the `.g.dart` files for the new DTOs (even though they're dead on mobile, codegen still has to succeed or the build breaks).

---

# A. Render incoming broadcasts (MANDATORY)

When a broadcast reaches the device, two surfaces need to recognize it:
1. The **in-app notification list** (bell icon screen)
2. The **FCM push handler** (lock screen / system tray / in-app banner)

Both branch on `type == 'admin_broadcast'`.

## A1. In-app notification list rendering

Find the widget that iterates over `NotificationResponse`s in the bell-icon screen. Add a branch for `admin_broadcast`:

```dart
Widget _notificationTile(NotificationResponse n) {
  if (n.type == 'admin_broadcast') {
    return ListTile(
      leading: const _DllinyTeamBadge(),  // NEW — your "Dlliny Team" branded icon
      title: Text(_pickLang(n.titleAr, n.titleEn)),
      subtitle: Text(_pickLang(n.bodyAr, n.bodyEn)),
      trailing: n.isRead ? null : const _UnreadDot(),
      onTap: () {
        _markRead(n.id);
        if (n.deepLink != null && n.deepLink!.isNotEmpty) {
          context.router.push(n.deepLink!);
        }
        // No deepLink? Stay on the notification list — the body IS the message.
      },
    );
  }
  return _OrganicNotificationTile(n);  // your existing avatar-based UI
}
```

### Differences from organic notifications

| Concern | Organic notification | Admin broadcast |
|---|---|---|
| Leading visual | Actor's avatar | Team badge / logo (no actor exists) |
| Title format | "X liked your post" | The admin's literal `titleAr` / `titleEn` |
| Deep link | Always present (points at the entity) | Optional — many broadcasts are pure announcements with no target screen |
| Long-press menu | "Mute X", "Block X" | Should NOT offer these (no actor to mute) |
| `entityId` / `entityType` | Post UUID / "post" | Broadcast UUID / "admin_broadcast" — typically unused on mobile |

### Visual design hints (just suggestions — adapt to your design system)

- Team badge: a small filled circle with the Dlliny logo, or a stylized "D"
- Background tint: lightly different from organic rows so the broadcast stands out — but not loud
- Body: support 2-line truncation with "Read more" expansion if your design supports it (broadcasts can be up to 2000 chars)

## A2. FCM push payload handling

When a push arrives via FCM, the data payload contains:

```json
{
  "type": "admin_broadcast",
  "broadcastId": "<uuid>"
}
```

Plus the standard `deep_link` field (if the broadcast had one set).

Your existing FCM handler — usually a `FirebaseMessaging.onMessage` / `onMessageOpenedApp` listener — likely already routes by the `type` field for other notification kinds. Add an `admin_broadcast` branch:

```dart
void _handlePushTap(RemoteMessage message) {
  final type = message.data['type'];
  switch (type) {
    case 'admin_broadcast':
      final deepLink = message.data['deep_link'];
      if (deepLink != null && deepLink.isNotEmpty) {
        context.router.push(deepLink);
      } else {
        // No deep link — land on the notification list so the user can read
        // the full message.
        context.router.push('/notifications');
      }
      break;
    // ... your other types
  }
}
```

For **foreground** receives (`onMessage`), the bell-icon unread count will tick via your existing notification-refresh logic — no special handling needed. Optionally show an in-app banner with the title + body.

No new API calls — the in-app row was written server-side as part of the async fan-out, so the next `getMyNotifications` refresh picks it up.

## A3. Edge cases to handle

| Scenario | Behavior |
|---|---|
| Notification arrives while the user is on the notification list screen | List should refresh + the new row appears |
| User taps a broadcast push while app is in background | App opens → navigate per `deep_link` or to notification list |
| User taps a broadcast push while app is in killed state | App cold-starts → same routing once init completes |
| `titleEn` is in Arabic (or vice versa) because admin filled both fields with the same language | Render whatever's in the user's preferred-lang field — server doesn't enforce per-field language |
| `deep_link` points at a route that doesn't exist in the current app version | Fall back to notification list, don't crash |

## A4. Tests to add (minimum bar)

- **Render test**: notification list with one `admin_broadcast` item shows the team badge (no actor avatar)
- **Render test**: same list with a mix of organic + broadcast notifications renders both correctly
- **Tap test**: tapping a broadcast with `deepLink` routes correctly
- **Tap test**: tapping a broadcast WITHOUT `deepLink` doesn't crash (lands on notification list)
- **FCM unit test**: incoming push with `data.type=admin_broadcast` triggers correct route

---

# B. City/District FK migration (V82) — separate concern

The broadcast feature's `CITY` and `DISTRICT` audience types read `users.city_id` / `users.district_id` (FK columns added in V82). V82 backfilled these from the existing free-text `users.city` / `users.district` columns where the text matched a canonical city/district name — but some users end up with NULL FKs after the backfill (typos, deleted city rows, etc.).

**Why this matters for the Flutter app**: a user with `city_id IS NULL` will never appear in a `CITY` audience resolution, even if their free-text `city` says "Baghdad" and the admin targets Baghdad. They'll silently miss city-scoped broadcasts (and also miss city-scoped trending, weekly recommendations, and intent filters).

Two pieces of Flutter work close this gap.

## B1. Profile / onboarding writes the IDs

Wherever the app captures the user's location:
- **Onboarding city/district picker** (if it exists)
- **Profile edit screen**
- **Any other "set my city" UI**

The picker MUST source from the canonical `cities` / `districts` list — use the existing locations endpoints (likely `GET /api/v1/locations/cities` and `GET /api/v1/locations/districts?cityId=`).

The PATCH/POST payload should include the new fields:
```dart
{
  // existing fields you already send
  "city": "Baghdad",          // legacy free-text — keep sending for now
  "district": "Karrada",      // legacy free-text — keep sending for now
  // NEW
  "cityId": 1,                // SMALLINT — canonical city.id from your picker
  "districtId": 42            // INT — canonical district.id
}
```

### ⚠ Backend follow-up required

I did NOT extend the profile-update DTO on the backend to accept `cityId` / `districtId` as part of the V82/V83 work. Your existing `update_profile_request` DTO (or whichever request the profile editor sends) needs:

1. Backend `UpdateProfileRequest` DTO — add `cityId` + `districtId` fields
2. Backend `UserService.updateProfile(...)` — set `user.cityRef` + `user.districtRef` from those IDs (or null them)
3. Flutter `update_profile_request.dart` — add the same two fields

**Before shipping city/district broadcasts, confirm this backend piece is done.** If you want me to add it, ask and I'll write the full chain (backend + Flutter, ~5 files).

## B2. "Complete your location" prompt (optional, v2)

Users whose V82 backfill produced NULL FKs won't receive city/district broadcasts and won't see city-scoped trending / weekly recommendations / intent filters. Their free-text `city` likely still has a value, so they look "located" to themselves — they don't know they're missing content.

A soft nudge can close this gap:

- **Detection**: `GET /api/v1/users/me` should expose `cityId` and `districtId`. If your existing `UserResponse` doesn't include them, add them (backend + Flutter both).
- **Prompt**: a one-time banner / settings warning: "Set your city to see local recommendations." Dismissible. Routes to the profile editor.
- **Frequency**: show once per app launch until acted upon; respect a "dismissed" flag in local storage so it's not spammy.

Defer this to v2 if you want — not blocking the broadcast feature itself, but city/district broadcasts will silently miss these users until they re-set their location through B1.

---

# C. Quick checklist

For shipping the broadcast feature to production:

- [ ] **Run `flutter pub run build_runner build --delete-conflicting-outputs`** — DTOs need codegen even though the admin ones are dead on mobile
- [ ] **A1**: Notification list renders `admin_broadcast` rows with team badge + no actor avatar
- [ ] **A2**: FCM handler branches on `type == 'admin_broadcast'`, respects `deep_link` when present, falls back to notification list when absent
- [ ] **A3**: Edge cases handled (missing deep_link, killed-app cold start, list refresh on foreground receive)
- [ ] **A4**: Render + tap tests for `admin_broadcast` notifications
- [ ] **B1 (+ backend follow-up)**: Profile updates send `cityId` + `districtId` (backend DTO + service updated to accept them)
- [ ] **B2** (optional, v2): "Complete your location" prompt for users with null FKs

---

# Optional cleanup

The mobile app's `lib/data/api/api_service.dart` currently includes the admin broadcast methods (`adminPreviewBroadcastAudience`, `adminSendBroadcast`, `adminListBroadcasts`, `adminGetBroadcast`). They're dead code on mobile — the mobile app never calls them. Same applies to other admin methods previously added (intents, vibe-tag catalog, ghost users, featured collections, etc.).

Options:
- **Leave as-is** — Retrofit generates them; they take a few KB of compiled code and never run. Cheapest.
- **Strip them** — cleaner mobile codebase; clear boundary that mobile is recipient-only. Requires either splitting `api_service.dart` into mobile/admin halves or maintaining two flavors.

Ask if you want a cleanup pass and I'll do it.

---

# Cross-references

- Backend admin endpoint reference (for the separate dashboard project): `ADMIN_INTENTS_AND_VIBE_TAGS.md` — covers intents + vibe-tag catalog and demonstrates the Spring conventions the broadcast endpoints follow
- Backend service implementation: `hangout-notification/.../AdminBroadcastServiceImpl.java`
- Backend controller: `hangout-notification/.../AdminBroadcastController.java`
- Migrations: `V82__user_city_district_fk.sql`, `V83__admin_broadcasts.sql`
