# Hangout Venue Branch Selection

**Feature:** When a user creates a hangout, they must pick a specific
branch of the chosen venue. Single-branch venues auto-select their
primary; multi-branch venues force the picker; online-only venues
have no branch at all.

**Status:** Shipped end-to-end (backend + Flutter). All 19 Maven
modules clean install. `dart analyze` clean.

**Flyway migration:** `V90`.

---

## Table of Contents

1. [Why](#why)
2. [Data model](#data-model)
3. [Validation rules](#validation-rules)
4. [Backend changes](#backend-changes)
5. [Flutter changes](#flutter-changes)
6. [API contract](#api-contract)
7. [Client UX guidance](#client-ux-guidance)
8. [Things to know before deploy](#things-to-know-before-deploy)

---

## Why

Before this change, hangouts only carried `venue_id` — the venue
identity, with no notion of *which* physical location. A multi-branch
chain (e.g. a café with Karada + Mansour + Jadriya branches) couldn't
tell attendees which branch to show up at.

`venue_locations` (branches) have existed for a while, but content —
posts, memories, hangouts, reviews — only pointed at the venue. This
change adds branch attribution to hangouts as the first content type
to gain it. The same pattern can be applied to posts / memories /
reviews later if the product needs it.

---

## Data model

### V90 migration

```sql
ALTER TABLE hangouts
    ADD COLUMN venue_location_id UUID
        REFERENCES venue_locations(id) ON DELETE SET NULL;
```

- **Nullable.** Online-only venues legitimately have no branch.
- **ON DELETE SET NULL.** Admin-deleting a branch doesn't cascade-blow
  the historical hangouts that happened there — they degrade to
  "venue, no branch info".
- **Backfilled.** Every existing hangout was pointed at its venue's
  primary branch. Online-only hangouts stay NULL (correct: there was
  never a branch).
- **Partial index** `idx_hangouts_venue_location_id` covers the
  non-NULL path for "all hangouts at this branch" queries.

### `Hangout` entity

```java
@ManyToOne(fetch = FetchType.LAZY)
@JoinColumn(name = "venue_location_id")
private VenueLocation venueLocation;
```

Lazy because the feed batches branch info via the bulk projection
path; the field is only dereferenced when assembling a response.

---

## Validation rules

The same rule applies to **both** create paths (user-facing +
admin-ghost). Enforced by `VenueBranchResolverService.resolveBranch`
in `hangout-infrastructure`.

| Venue state | Client sends `venueLocationId` | Server result |
|---|---|---|
| **Online-only** | `null` (or omitted) | OK — hangout has no branch |
| **Online-only** | any non-null value | **400** `Online-only venues have no branches — venueLocationId must be null` |
| **1 active branch** (primary) | omitted / `null` | OK — server auto-selects the primary branch |
| **1 active branch** | matches the primary id | OK (idempotent) |
| **1 active branch** | any other id | **400** `Selected branch does not belong to this venue` |
| **2+ active branches** | omitted / `null` | **400** `This venue has multiple branches — venueLocationId is required` |
| **2+ active branches** | matches a branch id | OK |
| **2+ active branches** | unknown id | **400** `Selected branch does not belong to this venue` |
| **0 branches, not online-only** (legacy data drift) | any value | OK — hangout gets `null` branch; admin dashboard should flag the venue as needing setup |

---

## Backend changes

### New file

| Path | Purpose |
|---|---|
| `hangout-gateway/src/main/resources/db/migration/V90__hangout_venue_location.sql` | Schema migration: column, FK, backfill, partial index |
| `hangout-infrastructure/src/main/java/com/beestar/hangout/infrastructure/service/VenueBranchResolverService.java` | Shared `resolveBranch(Venue, UUID requestedBranchId)` helper. Lives in infrastructure so both `hangout-hangout` and `hangout-admin` reuse the same rule without cross-module deps. |

### Modified files

| Path | Change |
|---|---|
| `hangout-domain/.../entity/hangout/Hangout.java` | Added `VenueLocation venueLocation` lazy association. |
| `hangout-hangout/.../dto/request/CreateHangoutRequest.java` | New optional `UUID venueLocationId`. |
| `hangout-admin/.../dto/request/CreateGhostHangoutRequest.java` | Same field for the ghost-content admin path. |
| `hangout-hangout/.../service/impl/HangoutServiceImpl.java` | Injects `VenueBranchResolverService`; calls `branchResolver.resolveBranch(...)` inside `doCreate` before building the hangout. Drops the now-unused direct `VenueLocationRepository` injection. |
| `hangout-admin/.../service/impl/AdminGhostContentServiceImpl.java` | Same resolver injection + call inside `createHangoutAsGhost`. |
| `hangout-hangout/.../dto/response/HangoutResponse.java` | New nested `Branch` record (`id, labelAr, labelEn, addressAr, addressEn, isPrimary`). Populated in `toResponse`. |
| `hangout-feed/.../dto/response/HangoutFeedItem.java` | New nested `Branch` record with the same shape. Populated in the batched `toHangoutFeedItem` projection. |

### `VenueBranchResolverService.resolveBranch` algorithm

```text
if venue.isOnlineOnly():
    if requestedBranchId != null  → throw "Online-only venues have no branches"
    return null

branches = venueLocationRepository.findByVenueId(venue.id)
if branches.isEmpty():
    return null   // legacy data drift; physical venue with no branch rows

if branches.size() == 1:
    solo = branches[0]
    if requestedBranchId != null && requestedBranchId != solo.id
        → throw "Selected branch does not belong to this venue"
    return solo                                       // auto-select primary

# multi-branch path
if requestedBranchId == null
    → throw "This venue has multiple branches — venueLocationId is required"
return branches.first(b => b.id == requestedBranchId)
              or throw "Selected branch does not belong to this venue"
```

---

## Flutter changes

### Files touched

| Path | Change |
|---|---|
| `lib/domain/dto/request/create_hangout_request.dart` | New `String? venueLocationId` field on `CreateHangoutRequest`. Marked optional in the constructor; the JSON serializer (with `includeIfNull: false`) omits the key when null. |
| `lib/domain/dto/response/hangout_response.dart` | New `branch: HangoutBranch?` field on `HangoutResponse` + new `HangoutBranch` class (`id, labelAr?, labelEn?, addressAr?, addressEn?, isPrimary`). |
| `lib/domain/dto/response/feed_response.dart` | New `branch: HangoutFeedBranch?` field on `HangoutFeedItem` + new `HangoutFeedBranch` class. (Distinct from `HangoutBranch` so json_serializable codegen for the two files stays unambiguous — JSON shape is identical.) |
| `*.g.dart` (3 files) | Regenerated by `build_runner`. |

### `api_service.dart` was NOT changed

The endpoint signatures didn't change — `CreateHangoutRequest` and
`HangoutResponse` are referenced by name, and the new fields flow
through automatically via the updated DTOs and their regenerated
`*.g.dart` serializers.

---

## API contract

### Request

`POST /api/v1/hangouts` and `POST /api/v1/business/venues/{venueId}/hangouts`:

```json
{
  "venueId": "...",
  "venueLocationId": "...",        // optional/required per validation rules
  "description": "...",
  "scheduledAt": "2026-07-01T20:00:00Z",
  "joinPolicy": "OPEN",
  "postVisibility": "PUBLIC",
  "whatsappLink": "https://wa.me/...",
  "inviteeUserIds": ["..."],
  "inviteMessage": "..."
}
```

Same field added to the admin ghost-content body
`POST /api/v1/admin/users/ghost/{id}/hangouts`.

### Response

Both `HangoutResponse` (hangout details endpoint) and `HangoutFeedItem`
(feed payloads) gain a `branch` field:

```json
{
  "id": "...",
  "venueId": "...",
  "venueNameAr": "مقهى الزمن",
  "venueNameEn": "Cafe Az-Zaman",
  "branch": {
    "id": "...",
    "labelAr": "فرع الكرادة",
    "labelEn": "Karada branch",
    "addressAr": "شارع 62، الكرادة، بغداد",
    "addressEn": "Street 62, Karada, Baghdad",
    "isPrimary": true
  },
  ...
}
```

`branch` is `null` on:
- Online-only venues (legitimate — no physical location).
- Legacy hangouts at physical venues that had no branch rows at the
  time `V90` ran (rare; degrades gracefully).

---

## Client UX guidance

### Picking a branch in the hangout composer

Source of truth is `VenueResponse.locations` (already returned by
`GET /venues/{venueId}`), or the dedicated
`GET /venues/{venueId}/locations` endpoint.

```dart
final venue = await api.getVenue(venueId);
final branches = venue.data!.data!.locations;

if (branches.isEmpty) {
  // Online-only venue (or legacy). No picker.
  request = CreateHangoutRequest(venueId: venueId, ...);
}
else if (branches.length == 1) {
  // Single branch — no picker. You can omit venueLocationId entirely
  // (server auto-selects the primary) or pass branches[0].id explicitly.
  request = CreateHangoutRequest(venueId: venueId, ...);
}
else {
  // Multi-branch — show the picker. venueLocationId MUST be sent.
  request = CreateHangoutRequest(
    venueId: venueId,
    venueLocationId: pickedBranch.id,
    ...
  );
}
```

### Rendering a hangout's branch

```dart
// On a feed card or hangout-details screen:
final hangout = ...;
if (hangout.branch != null) {
  final label = locale == 'ar' ? hangout.branch!.labelAr : hangout.branch!.labelEn;
  final address = locale == 'ar' ? hangout.branch!.addressAr : hangout.branch!.addressEn;
  // Render under the venue chip:  مقهى الزمن — فرع الكرادة
  //                                شارع 62، الكرادة، بغداد
}
```

For consistency: when `labelAr` / `labelEn` is null but `address*` is
set, fall back to the address as the chip label.

---

## Things to know before deploy

### Migration

- **V90 runs at startup** (Spring Boot Flyway integration). No manual
  step.
- **Backfill is idempotent.** Re-running V90 wouldn't change anything
  because it's an `UPDATE ... WHERE venue_location_id IS NULL` —
  except the column is created in the same migration, so the
  invariant is "every hangout at a physical-venue-with-a-primary-branch
  has its `venue_location_id` set after V90 runs."

### Behaviour change for clients

- **Multi-branch venues become unaccepting of a create-hangout without
  `venueLocationId`.** Old Flutter builds that don't send the field
  will 400 against multi-branch venues only. Single-branch and
  online-only venues remain unchanged.
- The recommended migration window: ship the new mobile build first
  (it sends `venueLocationId` correctly), then deploy backend V90 +
  validator. Or roll out together if the multi-branch fleet is small.

### Edge cases handled

- **Branch deleted after the hangout was created.** The FK is
  `ON DELETE SET NULL`, so the hangout's `branch` becomes `null` and
  the card falls back to "venue only" rendering. No 500s.
- **Venue converted to online-only after creation.** Online conversion
  already drops branch rows via the existing flow
  (`VenueLocationRepository.deleteByVenueId`). The `ON DELETE SET
  NULL` rule extends gracefully: historical hangouts lose their
  branch attribution and render as "venue only", which matches the
  venue's new state.
- **Concurrent branch picker + admin demoting primary.** The
  resolver checks against `findByVenueId` at create time, so the
  picker either succeeds with the chosen branch or 400s with
  "Selected branch does not belong to this venue" if the branch was
  deleted between the picker render and submit.

### What's NOT in this batch

- Branch attribution for **posts**, **memories**, **reviews**. Same
  pattern (`venue_location_id` column + resolver call + DTO field)
  can be applied if the product needs it.
- A `GET /branches/{branchId}/hangouts` listing endpoint. The data is
  in place (partial index supports it); the controller hasn't been
  built.
- Branch-aware analytics (per-branch foot traffic from hangouts).
  Hookable later off `venue_location_id` in the analytics rollup
  scheduler.

---

*End of doc.*
