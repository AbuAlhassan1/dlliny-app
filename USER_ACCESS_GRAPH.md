# User Access Graph — Venue Permissions

How to discover which businesses + venues a logged-in user can act on, and what they're allowed to do at each one.

## The endpoint

```
GET /api/v1/users/me/access
Auth: hasRole('USER')
```

Returns `UserAccessResponse` — the full access graph: every business + venue the caller can act on, with role names and effective permissions resolved per venue.

Flutter call: `apiService.getMyAccess()` (already wired).

## The response shape

```json
{
  "success": true,
  "data": {
    "businesses": [
      {
        "businessId": "...",
        "companyName": "Karrada Cafés Group",
        "active": true,
        "verified": true,
        "createdAt": "...",
        "businessRoleName": null,             // null = user has no biz-level role
        "businessPermissions": [],
        "venues": [
          {
            "venueId": "...",
            "nameAr": "كافيه شارع المتنبي",
            "nameEn": "Mutanabbi St Café",
            "logoUrl": "...",
            "active": true,
            "verified": true,
            "venueRoleName": "manager",       // ← this user's role on THIS venue
            "venuePermissions": [             // perms from the venue-scope role
              "venue:read",
              "venue:update",
              "venue:media:upload",
              "venue:media:delete",
              "venue:verify:submit",
              "venue:reviews:reply",
              "venue:campaigns:create",
              "venue:campaigns:read",
              "venue:services:manage"
            ],
            "effectivePermissions": [         // ← union of biz + venue. THE one to gate on.
              "venue:read",
              "venue:update",
              "venue:media:upload",
              "venue:media:delete",
              "venue:verify:submit",
              "venue:reviews:reply",
              "venue:campaigns:create",
              "venue:campaigns:read",
              "venue:services:manage"
            ]
          },
          {
            "venueId": "...",
            "nameEn": "Adhamiyah Branch",
            "venueRoleName": "staff",         // ← staff on this one
            "venuePermissions": [
              "venue:read",
              "venue:media:upload"
            ],
            "effectivePermissions": [
              "venue:read",
              "venue:media:upload"
            ]
          }
        ]
      }
    ],
    "orphanVenues": []                         // venue-scope role with no parent biz
  }
}
```

## The gate — always use `effectivePermissions`

The flag is presence in the list. There are **no levels** — a permission is either there or it isn't.

```dart
bool canReadVenue(VenueAccess v)   => v.effectivePermissions.contains('venue:read');
bool canUpdateVenue(VenueAccess v) => v.effectivePermissions.contains('venue:update');
bool canUploadMedia(VenueAccess v) => v.effectivePermissions.contains('venue:media:upload');
bool canRunAds(VenueAccess v)      => v.effectivePermissions.contains('venue:campaigns:create');
bool canManageStaff(VenueAccess v) => v.effectivePermissions.contains('venue:staff:manage');
```

**Don't gate off `venueRoleName`** ("if role == 'manager' then ..."). The role-to-permission mapping is data-driven (rows in `role_permissions`), so it can be updated server-side without a Flutter release. Always read the permissions list directly.

## The complete venue permission vocabulary

These are the strings the server may put in `effectivePermissions`:

| Permission | What it gates |
|---|---|
| `venue:read` | View venue details + media |
| `venue:update` | Edit the venue profile (name, address, contact, etc.) |
| `venue:media:upload` | Upload images / videos (logo, cover, gallery photos) |
| `venue:media:delete` | Delete venue media; edit / reorder gallery photos |
| `venue:hours:manage` | Edit opening hours and the operating status |
| `venue:verify:submit` | Submit the venue for verification |
| `venue:reviews:reply` | Reply to customer reviews |
| `venue:staff:manage` | Invite users + assign roles on this venue |
| `venue:campaigns:create` | Create an ad campaign for this venue |
| `venue:campaigns:read` | View this venue's campaign list + stats |
| `venue:services:manage` | CRUD the venue's services |
| `venue:create` | (business-scope) create a new venue under this business |

## What each role actually gets (for reference)

| Role | Permissions |
|---|---|
| **owner** | Every `venue:*` permission |
| **manager** | Every `venue:*` permission **except** `venue:staff:manage` |
| **staff** | Only `venue:read` and `venue:media:upload` |

So a **manager** can read AND update; a **staff** member can only read. But again, don't hardcode that mapping in Flutter — just check the permissions list.

## How to filter "venues I manage or am staff in"

```dart
final access = await apiService.getMyAccess();
final myWorkVenues = <VenueAccess>[
  // every venue across every business in the response
  for (final biz in access.data!.businesses) ...biz.venues,
  // plus orphan venues (venue-scope role with no parent biz)
  ...access.data!.orphanVenues,
];

// Optional: filter to only the roles you care about
final managerOrStaff = myWorkVenues.where((v) =>
    v.venueRoleName == 'manager' || v.venueRoleName == 'staff').toList();
```

`orphanVenues` is rare but real — it's a venue where the user has a venue-scope role but the parent business hasn't surfaced in the businesses list. Always merge it in or you'll miss venues.

## Where in the API the gate matters server-side

The backend `@PreAuthorize` annotations on the venue endpoints check the same permission strings. Examples you'd hit:

| Endpoint | Required permission |
|---|---|
| `GET /api/v1/business/venues/{venueId}` | `venue:read` |
| `PUT /api/v1/business/venues/{venueId}` | `venue:update` |
| `GET /api/v1/business/venues/{venueId}/media/upload-url` | `venue:media:upload` |
| `POST /api/v1/business/campaigns` | `venue:campaigns:create` |
| `GET /api/v1/business/campaigns` | `venue:campaigns:read` |

So if you correctly hide the "Edit venue" button when `!canUpdateVenue(v)`, the PUT endpoint would also have 403'd anyway — your client gate just makes it a nicer UX.

## Understanding the two-tier permission model

Permissions can be granted at two scopes:

| Scope | Granted on | Stored in | Reaches |
|---|---|---|---|
| **Business** | A whole business account | `user_business_roles` | Every venue under that business |
| **Venue** | A single venue | `user_venue_roles` | Just that venue |

A user can have:

- **Business-only role** — e.g. "I'm the owner of the Karrada Cafés Group" → automatically grants permissions on every venue in the group.
- **Venue-only role** — e.g. "I'm just a manager at the Adhamiyah branch" → grants permissions only at that venue.
- **Both** — uncommon but supported. The two permission sets are unioned into `effectivePermissions`.

The server resolves all this for you. The client never needs to compute it.

## Why `effectivePermissions` matters more than `venuePermissions`

| Field | What it contains |
|---|---|
| `venuePermissions` | Only the permissions from the **venue-scope** role (or empty if no venue role) |
| `effectivePermissions` | **Union** of business-scope perms + venue-scope perms — what the user can actually do |

If a user is "owner" of the business but has no venue-scope role on a specific venue, `venuePermissions` is empty but `effectivePermissions` still has every perm (inherited from the business). **Always use `effectivePermissions` for gating.**

## TL;DR

- One call: `apiService.getMyAccess()`
- Collect: `[ ...biz.venues for biz in businesses, ...orphanVenues ]`
- Gate UI: `venue.effectivePermissions.contains('venue:update')` etc.
- Don't gate on `venueRoleName` — it's display-only
