# Public Events — Backend + Client Guide

Reference for the Public Events feature: admin-authored + business-authored advertisable events with media, an external CTA URL, and an "I'm interested" RSVP-lite counter. Ships with 16 endpoints across public / admin / business surfaces. Same visibility + moderation semantics as other content in the codebase.

---

## 1. What this feature is (and isn't)

**Is**: A one-to-many broadcast surface. A curator (admin or business owner) creates an event; users see it in the events tab, tap "I'm interested" to save it, click through to an external URL (ticket vendor, RSVP form, etc.). Attribution is enforced by DB CHECK — every event is authored by exactly one of an admin OR a business.

**Isn't**:
- A **Hangout** — hangouts are peer-to-peer meetups with invitations and attendance status. Events don't invite anyone; they broadcast.
- An **AdCampaign** — campaigns are paid impression systems with budgets and target audiences. Events are free / editorial content.
- A **VenueAnnouncement** — announcements are text-only notices on a venue's profile page. Events carry media and RSVPs, and can be off-platform.

**Comparison table** (from the design discussion):

| Concept | Title | Description | Media | Want-to-come | External URL | Advertisable |
|---|---|---|---|---|---|---|
| Hangout          | ❌ | ✅ | ✅ | ✅ (invitations) | ⚠️ WhatsApp only | ✅ (OPEN policy) |
| Post             | ❌ | ✅ (caption) | ✅ | ❌ | ❌ | ✅ |
| AdCampaign       | ⚠️ internal | ❌ | ❌ | ❌ | ❌ (click counter) | ✅ (paid) |
| VenueAnnouncement | ✅ (bilingual) | ✅ (bilingual body) | ❌ | ❌ | ❌ | ✅ (venue profile) |
| **PublicEvent**  | ✅ (bilingual) | ✅ (bilingual) | ✅ | ✅ (single-tap) | ✅ (`externalUrl` + label) | ✅ (public list) |

---

## 2. Data model (V101)

Three tables.

### `public_events`

```
id                       UUID PK
title_ar, title_en       VARCHAR(200) NOT NULL — bilingual titles
description_ar,          TEXT nullable
description_en           TEXT nullable
starts_at                TIMESTAMPTZ NOT NULL
ends_at                  TIMESTAMPTZ nullable   -- open-ended when null
external_url             VARCHAR(500) nullable
external_url_label       VARCHAR(60) nullable   -- "Buy tickets", "Register"
venue_id                 UUID nullable → venues(id) ON DELETE SET NULL
venue_location_id        UUID nullable → venue_locations(id) ON DELETE SET NULL
hangout_id               UUID nullable → hangouts(id)       ON DELETE SET NULL
created_by_admin_id      UUID nullable → admin_accounts(id)    ON DELETE SET NULL
created_by_business_id   UUID nullable → business_accounts(id) ON DELETE SET NULL
active                   BOOLEAN NOT NULL DEFAULT TRUE
hidden                   BOOLEAN NOT NULL DEFAULT FALSE
interested_count         INT     NOT NULL DEFAULT 0   -- denormalized counter
created_at, updated_at   TIMESTAMPTZ

CHECK chk_event_attribution:
    (admin IS NOT NULL AND business IS NULL)
 OR (business IS NOT NULL AND admin IS NULL)

CHECK chk_event_window:
    ends_at IS NULL OR ends_at > starts_at

CHECK chk_event_external_url_label:
    (url IS NULL AND label IS NULL) OR (url IS NOT NULL)
```

Indexes:
- `(starts_at)` — public list ordering
- `(created_at DESC)` — admin dashboard
- `(venue_id, created_at DESC)` — business dashboard

### `public_event_media`

Same shape as `hangout_media` / `post_media`:
```
id, event_id, media_type ('image'|'video'), url, thumbnail_url,
aspect_ratio NUMERIC(6,4), sort_order, uploaded_by, created_at
CHECK: media_type IN ('image','video')
```

### `public_event_interests`

RSVP-lite. One row per (event, user):
```
event_id, user_id (composite PK), created_at
```

Index `(user_id, created_at DESC)` backs the "My interested events" list.

### Permissions seeded

- `admin:events:manage` → SUPERADMIN, ADMIN
- `venue:events:manage` → owner, manager (venue-scope) + business_owner, business_manager (business-scope)

Token-version bumped on affected venue/business users so they pick up the new authority on next request. Admins re-derive on next token refresh.

---

## 3. Endpoints — 16 total

### Public surface (`USER` role required)

Base path: `/api/v1/events`

| Method | Path | Effect |
|---|---|---|
| `GET`    | `/?status=&page=&size=` | Paginated list. `status` = `UPCOMING` (default) \| `PAST` \| `ALL`. Active + not hidden. |
| `GET`    | `/{eventId}` | Detail + viewer-relative `interestedByMe`. |
| `POST`   | `/{eventId}/interest` | Mark interested. Idempotent. Returns the refreshed event. |
| `DELETE` | `/{eventId}/interest` | Remove interest. Idempotent. Returns the refreshed event. |
| `GET`    | `/me/interested?page=&size=` | The viewer's interested events, newest interest first. Excludes hidden / soft-deleted. |

**Pagination**: standard Spring `Page<T>` — `content[]`, `number`, `size`, `totalElements`, `totalPages`, `last`. Flutter's existing `PagedResponse<T>` maps 1:1.

### Admin CRUD (`admin:events:manage`)

Base path: `/api/v1/admin/events`

| Method | Path | Effect |
|---|---|---|
| `GET`    | `/`                    | Full listing (incl. inactive + hidden), newest-created first |
| `GET`    | `/{id}`                | Detail |
| `POST`   | `/`                    | Create — attribution stamped to caller admin |
| `PATCH`  | `/{id}`                | Edit any field (sentinels — §5) |
| `DELETE` | `/{id}`                | Soft delete (`active = false`) |
| `POST`   | `/{id}/hide`, `/unhide` | Moderation toggle |
| `POST`   | `/{id}/media`          | Attach one media item |
| `DELETE` | `/{id}/media/{mediaId}` | Remove one media item |

### Business CRUD (`venue:events:manage` + venue access)

Base path: `/api/v1/business/venues/{venueId}/events`

Every endpoint calls `VenueAccessService.assertVenueAccess(userId, venueId)` — the permission gates existence, the access assertion scopes it to a specific venue.

| Method | Path | Effect |
|---|---|---|
| `GET`    | `/`                              | Paginated list of this venue's events |
| `GET`    | `/{id}`                          | Detail; 404 if the event belongs to another venue |
| `POST`   | `/`                              | Create — attribution stamped to the venue's business |
| `PATCH`  | `/{id}`                          | Edit fields |
| `DELETE` | `/{id}`                          | Soft delete |
| `POST`   | `/{id}/media`                    | Attach media |
| `DELETE` | `/{id}/media/{mediaId}`          | Remove media |

Business note: `hide`/`unhide` is admin-only — business owners can't override moderation.

---

## 4. Response shape

`PublicEventResponse` — the same shape returned by every read path (public, admin, business):

```json
{
  "id": "…",
  "titleAr": "…",
  "titleEn": "…",
  "descriptionAr": "…",
  "descriptionEn": "…",
  "startsAt": "2026-08-15T18:00:00Z",
  "endsAt": "2026-08-15T22:00:00Z",
  "externalUrl": "https://tickets.example.com/…",
  "externalUrlLabel": "Buy tickets",
  "venueId": "…",
  "venueNameAr": "…",
  "venueNameEn": "…",
  "branch": {
    "id": "…", "labelAr": "…", "labelEn": "…",
    "addressAr": "…", "addressEn": "…", "isPrimary": true
  },
  "hangoutId": null,
  "interestedCount": 247,
  "interestedByMe": true,
  "active": true,
  "createdByAdminId": null,
  "createdByBusinessId": "…",
  "createdAt": "…",
  "updatedAt": "…",
  "media": [
    {
      "id": "…", "mediaType": "image",
      "url": "https://cdn…/…jpg", "thumbnailUrl": null,
      "aspectRatio": 1.7778, "sortOrder": 0, "createdAt": "…"
    }
  ]
}
```

**Viewer-aware fields**:
- `interestedByMe` — populated by every public endpoint. Always `false` on admin/business dashboard reads (no viewer identity per-row).

**Nullable/optional fields**:
- `endsAt`, `externalUrl`, `externalUrlLabel`, `venueId`+related, `hangoutId`, `descriptionAr/En` — all nullable.
- `branch` — populated only when `venueLocationId` was set on the event.
- `createdByAdminId` XOR `createdByBusinessId` (DB CHECK guarantees).

---

## 5. Rules enforced

### At create + update

- **Window**: `endsAt` must be after `startsAt` when set. `startsAt` required on create; PATCH treats null as "leave unchanged".
- **External URL / label pair**: setting a label without a URL is rejected (both on service + DB CHECK). Setting a URL without a label is fine — client renders a generic "Learn more".
- **Venue attribution**: `venueId` is optional (off-platform events allowed). If `venueLocationId` is set, the branch must belong to the same venue — cross-venue branch attribution 400s with `Branch X does not belong to venue Y`.
- **Hangout link**: `hangoutId` must exist if set. `ON DELETE SET NULL` on the FK — deleting a hangout later doesn't wipe the event.
- **Business cross-venue guard**: business callers cannot ship an event whose body `venueId` differs from the URL-path `venueId`. Applies on both create and PATCH.

### PATCH sentinels

The PATCH endpoints treat `null` as "leave unchanged". To explicitly *clear* a nullable field, use these:

| Field | Clear sentinel |
|---|---|
| `endsAt` | `"1970-01-01T00:00:00Z"` (Instant.EPOCH) → clears to open-ended |
| `externalUrl` | `""` (empty string) → clears the URL **and** the label together (invariant preserved) |
| `externalUrlLabel` | `""` → clears just the label |
| `venueId`, `venueLocationId`, `hangoutId` | `"00000000-0000-0000-0000-000000000000"` (nil-UUID) → clears the FK |

### Attribution (create-time)

- **Admin** callers: `createdByAdmin` stamped from the calling admin's id.
- **Business** callers: `createdByBusiness` resolved via `business_venue_access.findByIdVenueId(venueId)` — same pattern as `BusinessChallengeService`. Throws `BusinessException("No business account linked to this venue")` if the venue has no such row (admin-created ghost venues that were never handed off to a business).

### Interest counter

Denormalized on `public_events.interested_count`, atomically bumped by:

```sql
UPDATE public_events
SET interested_count = GREATEST(0, interested_count + :delta), updated_at = NOW()
WHERE id = :id
```

`GREATEST(0, ...)` clamps decrement races so the counter never goes negative. The bump only fires when the interest insert / delete actually changed a row (existing interest ignored — idempotency preserved without double-counting).

**Source of truth** is `SELECT COUNT(*) FROM public_event_interests WHERE event_id = ?`. If the denormalized column ever drifts, a periodic reconciler can resync from that query.

### Existence not leaking (business surface)

`findEventInVenue` throws `ResourceNotFoundException` (404) when the target belongs to a different venue or a business path is used with an admin-authored event — deliberate to avoid confirming existence of resources the caller can't touch.

---

## 6. Behind the scenes

### Batched hydration

The list endpoints do 3 queries total for a page, not N-per-row:

1. Page of events.
2. **One** media query for the whole page's `event_id`s, grouped in Java.
3. **One** viewer-interested query returning a `Set<UUID>` of event ids the viewer has marked.

Same pattern the feed uses. Prevents the audit-#10 N+1 recurrence on grid-heavy screens.

### Attribution via `business_venue_access`

Business-side create looks up the business account through `business_venue_access` (identical helper to `BusinessChallengeServiceImpl.resolveBusinessForVenue`). A venue that was created directly by admin (no business account linked) can still host events, but only via the admin surface — the business path throws with a clear message.

### Moderation vs soft-delete

Two orthogonal flags:

- `active = false` (soft delete) — event drops out of every public list; still visible on admin dashboard. Business owner can "delete" their own event this way.
- `hidden = true` (moderation) — event drops out of public list; still visible on admin AND business dashboards. Only admins can toggle.

The public-facing `/api/v1/events/{id}` requires **both** `active = true AND hidden = false` to return; either flag being set produces 404.

### `hangout_id` deep-link semantics

Purely a client hint. Setting it doesn't change any business logic — the client renders a "See the hangout" affordance and, on tap, jumps to `/api/v1/hangouts/{id}`. If the linked hangout is later cancelled or soft-deleted, the FK's `ON DELETE SET NULL` handles cleanup automatically.

---

## 7. Client integration (Flutter)

### New DTOs

Response:
- `PublicEventResponse` — with nested `PublicEventBranch`.
- `PublicEventMediaResponse`.

Request:
- `CreateEventRequest`.
- `UpdateEventRequest`.
- `AttachEventMediaRequest`.

All in the standard barrel exports (`requests.dart`, `responses.dart`).

### Retrofit methods (16)

Grouped in `api_service.dart` under the `Public Events` section — public (5), admin (9), business (7).

Naming:
- Public: `listPublicEvents`, `getPublicEvent`, `markEventInterested`, `unmarkEventInterested`, `listMyInterestedEvents`.
- Admin: `adminListEvents`, `adminGetEvent`, `adminCreateEvent`, `adminUpdateEvent`, `adminDeleteEvent`, `adminHideEvent`, `adminUnhideEvent`, `adminAttachEventMedia`, `adminRemoveEventMedia`.
- Business: `businessListEvents`, `businessGetEvent`, `businessCreateEvent`, `businessUpdateEvent`, `businessDeleteEvent`, `businessAttachEventMedia`, `businessRemoveEventMedia`.

Return types: `ApiResponse<PublicEventResponse>` for single reads and mutations, `ApiResponse<PagedResponse<PublicEventResponse>>` for lists, `ApiResponse<PublicEventMediaResponse>` for media attach, `ApiResponse<dynamic>` for the void endpoints (delete/hide).

### Post-pull codegen step

```
cd hangout_app
dart run build_runner build --delete-conflicting-outputs
```

Regenerates the 5 new `.g.dart` files + `api_service.g.dart` with the 16 endpoint bindings. No wiring changes required beyond that.

### Suggested UX

**Public list**:
- Grid or vertical card list, sorted by `startsAt` (upcoming) or `-startsAt` (past).
- Each card: cover from `media[0]` (video → thumbnailUrl, image → url), title in preferred locale, `interestedCount` chip, "Learn more" CTA button (label = `externalUrlLabel` fallback to `Learn more`) when `externalUrl` is set.
- Interest toggle at the corner: filled heart when `interestedByMe`, outline otherwise. Tap → optimistic update + POST/DELETE.

**Detail**:
- Full media strip (horizontal PageView or scroll).
- Bilingual title + description.
- Venue + branch line (when set); "Online / Off-platform" when not.
- Big `Learn more` button linking to `externalUrl` — use `url_launcher` with external app mode.
- Interested counter + toggle button.
- Deep-link chip "See the hangout" when `hangoutId` is set.

**Admin dashboard**:
- CRUD table + create/edit modal. Fields map 1:1 to the DTO. Sentinel behavior for PATCH is worth surfacing as UI (e.g., a "Clear" button on the URL field posts `""`, on the endsAt field posts the Instant.EPOCH string).

**Business dashboard**:
- Same shape, scoped to the venue's events. `venueId` field is hidden (comes from URL). Hangout picker only shows hangouts organized by this business.

---

## 8. Migration + deployment checklist

1. **Flyway V101** applies:
   - Creates 3 tables + indexes.
   - Seeds `admin:events:manage` and `venue:events:manage` permissions.
   - Grants to SUPERADMIN/ADMIN + owner/manager + business_owner/business_manager.
   - Bumps `token_version` on venue/business-scope users so the new authority appears on next request.
2. **Deploy backend** — no other schema-only steps.
3. **Flutter side**: pull, run `build_runner`, no code edits.
4. First smoke test: `POST /api/v1/admin/events` as SUPERADMIN, then hit `GET /api/v1/events` as a normal user and check the row appears.

---

## 9. Endpoint quick-ref

### Public
```
GET    /api/v1/events?status=UPCOMING|PAST|ALL&page=&size=
GET    /api/v1/events/{eventId}
POST   /api/v1/events/{eventId}/interest
DELETE /api/v1/events/{eventId}/interest
GET    /api/v1/events/me/interested?page=&size=
```
Permission: `hasRole('USER')`.

### Admin
```
GET    /api/v1/admin/events?page=&size=
GET    /api/v1/admin/events/{eventId}
POST   /api/v1/admin/events
PATCH  /api/v1/admin/events/{eventId}
DELETE /api/v1/admin/events/{eventId}
POST   /api/v1/admin/events/{eventId}/hide
POST   /api/v1/admin/events/{eventId}/unhide
POST   /api/v1/admin/events/{eventId}/media
DELETE /api/v1/admin/events/{eventId}/media/{mediaId}
```
Permission: `admin:events:manage`.

### Business
```
GET    /api/v1/business/venues/{venueId}/events?page=&size=
GET    /api/v1/business/venues/{venueId}/events/{eventId}
POST   /api/v1/business/venues/{venueId}/events
PATCH  /api/v1/business/venues/{venueId}/events/{eventId}
DELETE /api/v1/business/venues/{venueId}/events/{eventId}
POST   /api/v1/business/venues/{venueId}/events/{eventId}/media
DELETE /api/v1/business/venues/{venueId}/events/{eventId}/media/{mediaId}
```
Permission: `venue:events:manage` **+** venue access via `VenueAccessService`.

---

## 10. File map (backend)

**Migration**
- `hangout-gateway/src/main/resources/db/migration/V101__public_events.sql`

**Domain (entities + repos)**
- `hangout-domain/entity/event/PublicEvent.java`
- `hangout-domain/entity/event/PublicEventMedia.java`
- `hangout-domain/entity/event/PublicEventInterest.java`
- `hangout-domain/entity/event/PublicEventInterestId.java`
- `hangout-domain/repository/event/PublicEventRepository.java`
- `hangout-domain/repository/event/PublicEventMediaRepository.java`
- `hangout-domain/repository/event/PublicEventInterestRepository.java`

**Application (hangout-venue)**
- `service/PublicEventService.java` + `impl/PublicEventServiceImpl.java`
- `service/AdminEventService.java` + `impl/AdminEventServiceImpl.java`
- `service/BusinessEventService.java` + `impl/BusinessEventServiceImpl.java`
- `controller/PublicEventController.java`
- `controller/AdminEventController.java`
- `controller/BusinessEventController.java`
- `dto/response/PublicEventResponse.java`
- `dto/response/PublicEventMediaResponse.java`
- `dto/request/CreateEventRequest.java`
- `dto/request/UpdateEventRequest.java`
- `dto/request/AttachEventMediaRequest.java`

**Client (hangout_app)**
- `domain/dto/response/public_event_response.dart`
- `domain/dto/response/public_event_media_response.dart`
- `domain/dto/request/create_event_request.dart`
- `domain/dto/request/update_event_request.dart`
- `domain/dto/request/attach_event_media_request.dart`
- `data/api/api_service.dart` — 16 new Retrofit methods

---

## 11. Future extensions (deferred)

- **Cursor pagination** — currently offset (Spring Page). For very large event catalogs, add cursor variants matching the feed pattern.
- **Interest analytics** — the raw `public_event_interests` rows already exist. A "who's interested" list for admins is trivial to add later (mirrors the followers list pattern).
- **Push notification on interest** — an event's organizer might want a nudge when interest spikes. Wire an outbox event on interest insert (matches how challenges do `USER_LEVELED_UP`).
- **Trending order** — public list is currently chronological. A trending option ranking by `log(interested_count) / hoursOld^k` is a small addition.
- **Recurring events** — schema supports a single `starts_at` / `ends_at` today. Recurring RRULE-style scheduling would need a new `event_occurrences` table.
