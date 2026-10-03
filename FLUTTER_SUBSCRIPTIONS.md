# Subscriptions — Flutter Implementation Spec

How the Flutter app reads a user's subscription state and gates UI based on what the subscription unlocks. The backend infrastructure already exists (V31 + `SubscriptionController` + admin grant flow); this doc is about the consumer side.

**Scope**: Flutter mobile app. Admin granting of subscriptions is via a separate dashboard — see `ADMIN_DASHBOARD_GUIDE.md` for the admin endpoints under `/api/v1/admin/subscriptions/...`.

---

## What a subscription is, conceptually

A subscription is a **bag of permissions** that gets merged into the user's JWT at login.

```
   User logs in
        │
        ▼
   AuthService computes effective permissions:
     - Role permissions (from user's roles)
     - Business permissions (from owned business_accounts)
     - ⭐ Subscription permissions  ◄── what this doc is about
        │
        ▼
   All merged into JWT.permissions claim
        │
        ▼
   Server endpoints check via @PreAuthorize("hasAuthority('x')")
   Client UI gates via reading these permissions
```

Each subscription tier (Free, Pro, Plus, etc.) carries a set of permission strings. When a user has an active subscription to a tier, those permission strings are added to their effective set — both server-side (gating endpoints) and client-side (gating UI affordances).

---

## DTOs already in place

Both DTOs already exist in `lib/domain/dto/response/business_response.dart` — no codegen needed.

```dart
class MySubscriptionResponse {
  final String id;          // subscription row UUID
  final String tierId;
  final String tierName;    // e.g., "Pro", "Plus"
  final String status;      // 'active' (server filters non-active)
  final List<String> permissions;  // ⭐ what this subscription unlocks
  final String startedAt;   // ISO-8601 instant
  final String expiresAt;   // ISO-8601 instant
}

class SubscriptionTierResponse {
  final String id;
  final String name;
  final String? description;
  final double price;
  final String billingPeriod;       // 'monthly' or 'yearly'
  final List<String> permissions;   // permissions a fresh grant of this tier would include
}
```

## Endpoints already in place

Both in `lib/data/api/api_service.dart`:

```dart
/// Publicly available subscription tiers — for showing a "plans" screen.
@GET('/api/v1/subscriptions/tiers')
Future<ApiResponse<List<SubscriptionTierResponse>>> getSubscriptionTiers();

/// Active subscriptions for the current user.
@GET('/api/v1/subscriptions/me')
Future<ApiResponse<List<MySubscriptionResponse>>> getMySubscriptions();
```

`getMySubscriptions()` returns **only active, non-expired** subscriptions — the server filters by `expires_at > now AND status = 'active'`. Empty list = no active subscription.

---

## How to check if a user has a subscription

```dart
final response = await api.getMySubscriptions();
final subs = response.data ?? [];

final hasSubscription = subs.isNotEmpty;
```

A user can technically have **multiple active subscriptions at once** (different tiers). The merged effective permission set is the union of all their permission lists.

---

## How subscriptions are wired end-to-end

The flow is fully server-driven; the client just reads the result.

```
1. Admin grants a subscription:
   POST /api/v1/admin/subscriptions/users/{userId}
   Body: { tierId, expiresAt }
        │
        ▼
2. Server snapshots the tier's CURRENT permissions:
   INSERT INTO user_subscriptions
   SET permissions_snapshot = (the tier's permissions at this moment)
        │
        ▼
3. Next time that user logs in (or refreshes their token):
   AuthService merges permissions_snapshot from every active sub
   into the JWT.permissions claim
        │
        ▼
4. The client receives the JWT with the merged perms.
   GET /api/v1/subscriptions/me also returns the snapshotted list
   so the client can render UI without decoding the JWT.
```

### The "snapshot" detail (important!)

When a subscription is granted, the tier's current permission set is **frozen** into the `user_subscriptions.permissions_snapshot` column. **Changing a tier's permissions later does NOT affect existing active subscriptions** until they renew.

This is intentional:
- Plan changes don't retroactively remove perks from current subscribers
- Plan upgrades don't retroactively grant new perks to people who paid for the old plan

**For Flutter**: when you display "your plan includes …", source the list from `MySubscriptionResponse.permissions` (the snapshot), NOT from `SubscriptionTierResponse.permissions` (the tier's current state). The snapshot is what's actually unlocked.

---

## What subscriptions gate (today)

Only one permission is currently subscription-gated:

| Permission string | Effect when user has it |
|---|---|
| `business:create:multiple` | User can own more than one `business_accounts` row. Without it, they can register exactly one business. Enforced by `BusinessRequestServiceImpl` — the second registration attempt returns an error. |

That's the only subscription-gated feature in the codebase right now. The infrastructure is fully wired to support adding more — any new permission string can be attached to a tier and it'll automatically gate any endpoint that checks for it.

When new subscription-gated features ship, this section should be updated to enumerate them.

---

## How to gate UI in Flutter

Three approaches, ordered by recommended-ness:

### Option 1 (recommended) — Read `getMySubscriptions()` into app state

```dart
class SubscriptionState {
  final List<MySubscriptionResponse> active;

  const SubscriptionState({this.active = const []});

  /// True iff the user has at least one active subscription.
  bool get isSubscriber => active.isNotEmpty;

  /// True iff ANY of the user's active subscriptions grants the given permission.
  bool has(String permission) =>
      active.any((s) => s.permissions.contains(permission));

  /// Highest-priced active plan, useful for "Current plan" labels in UI.
  /// Returns null when the user has no subscription.
  String? get primaryTierName {
    if (active.isEmpty) return null;
    // For now, pick the most recently started — usually matches "most recent upgrade"
    final sorted = [...active]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sorted.first.tierName;
  }
}
```

Load once at app start (or on first auth) and cache it for the session:

```dart
Future<void> loadSubscriptionState() async {
  final response = await api.getMySubscriptions();
  ref.read(subscriptionStateProvider.notifier).state =
      SubscriptionState(active: response.data ?? []);
}
```

Refresh on demand when:
- The user navigates to a subscription-related screen
- After any grant/cancel flow (in case admin granted them something)
- On app foreground if the cache is older than ~1 hour

### Option 2 — Read from the JWT `permissions` claim

The JWT body already includes the merged permission set (role perms + business perms + subscription perms — all flat in `permissions`). If you have a JWT decoder you use anyway, no extra API call is needed:

```dart
class JwtClaims {
  final List<String> permissions;
  // ... rest of your JWT decoder
}

bool hasPermission(String p) => jwtClaims.permissions.contains(p);
```

**Pros**: zero extra HTTP calls; the JWT is always loaded.
**Cons**: if the user's subscription changes mid-session, the JWT is stale until the next login/refresh. Acceptable for permissions that aren't time-critical.

### Option 3 — Optimistic + handle 403

Just let the user tap the action. If the server returns 403, show a "Subscribe to unlock" CTA.

**Pros**: simplest code.
**Cons**: the user only discovers the limit by hitting it. Bad UX for features prominently surfaced in the app.

### Mix them

Realistic apps usually do a mix:
- **Show/hide CTAs** by reading from cached subscription state (Option 1)
- **Backstop with server 403 handling** in case the cache is stale (Option 3)

---

## Concrete example: "Add another business" CTA

```dart
class SubscriptionPermissions {
  static const businessCreateMultiple = 'business:create:multiple';
  // Add new subscription permission constants here as they ship.
}

class BusinessAccountsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final subState = context.watch<SubscriptionState>();
    final canCreateMore =
        subState.has(SubscriptionPermissions.businessCreateMultiple);

    return Scaffold(
      appBar: AppBar(title: const Text('My businesses')),
      body: Column(
        children: [
          // ... list of existing businesses ...
          if (canCreateMore)
            ElevatedButton(
              onPressed: () => context.router.push('/businesses/new'),
              child: const Text('Add another business'),
            )
          else
            _UpgradeBanner(
              title: 'Upgrade to manage multiple businesses',
              ctaRoute: '/subscriptions/plans',
            ),
        ],
      ),
    );
  }
}
```

The "current plan" badge anywhere in the app:

```dart
final tierName = subState.primaryTierName ?? 'Free';
Chip(label: Text(tierName));
```

---

## Important things to know

1. **Only active subscriptions are returned by `/me`** — the server filters by `expires_at > now AND status = 'active'`. There's no user-facing endpoint for expired/cancelled history; admins can see that via `/api/v1/admin/subscriptions/users/{userId}` but Flutter mobile-side has no equivalent. If you need a "past plans" view in the mobile UI, a new endpoint would have to be added.

2. **Tier-permission updates don't propagate to existing subs** (the snapshot detail above). When the platform team adds a new perk to "Pro", existing Pro subscribers DON'T automatically get it — only new grants or renewals will. Surface the user's `MySubscriptionResponse.permissions` as the source of truth for "what your plan includes", not the tier definition.

3. **Permissions are strings, not enums** — both client and server pass them as raw strings. Typos silently fail (a misspelled permission check returns false; no compile error). **Always centralize them in a `SubscriptionPermissions` constants class** to avoid drift between Flutter and backend code.

4. **A user can have multiple active subscriptions** — the schema allows it and the server merges all permissions. For "current plan" UI, you need a pick rule (most recent, highest priced, etc.) — that's a Flutter decision; the API gives you the raw list.

5. **A free/non-subscribed user has zero subscription permissions** — including no `business:create:multiple`. So the default state is "can register one business, period." This is intentional: the absence of a subscription IS the free tier.

6. **No client-initiated "subscribe" endpoint** — currently the only path to grant a subscription is via the admin dashboard (admin manually grants for a fixed expiry). Self-service checkout / payment integration is not part of this codebase. When/if that ships, this doc should be updated with the new client-facing flow.

7. **JWT is the cache for permissions** — when the cron rolls a subscription from `active` to `expired` (via `SubscriptionMaintenanceScheduler` in `hangout-user`), the JWT issued earlier will STILL contain those permissions until the user logs in / refreshes their token. For "instant downgrade" semantics, force a token refresh. Most UIs don't need this — the next normal refresh catches up within minutes/hours.

---

## Quick checklist

To wire subscription-aware UI in Flutter:

- [ ] Call `getMySubscriptions()` at login + cache in a provider/state holder
- [ ] Refresh when entering subscription-related screens
- [ ] Centralize permission strings in a `SubscriptionPermissions` class
- [ ] Gate CTAs by checking `subState.has(permission)`
- [ ] Show "Current plan" using `MySubscriptionResponse.tierName` (source of truth for active state)
- [ ] When displaying "what your plan includes", iterate `MySubscriptionResponse.permissions` (the snapshot)
- [ ] Handle 403 gracefully on the actual action endpoint as a safety net for stale state

---

## Cross-references

- Backend admin grant flow: see `ADMIN_DASHBOARD_GUIDE.md` for the admin endpoints under `/api/v1/admin/subscriptions/...`
- Schema: `V31__create_subscriptions.sql` — creates `subscription_tiers`, `subscription_tier_permissions`, `user_subscriptions`
- Server-side wiring:
  - `SubscriptionController` (hangout-user) — public + `/me` endpoints
  - `AdminSubscriptionController` (hangout-admin) — admin CRUD + grant + cancel
  - `AuthServiceImpl.generateToken` — where subscription permissions merge into the JWT
  - `SubscriptionMaintenanceScheduler` — flips expired rows to `expired` status
  - `BusinessRequestServiceImpl:41` — example of an endpoint gated by a subscription permission (`business:create:multiple`)
