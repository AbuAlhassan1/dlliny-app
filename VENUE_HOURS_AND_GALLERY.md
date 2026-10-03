# Venue Opening Hours + Photo Gallery — Backend + Client Guide

Reference for the V106 feature: weekly opening hours with a live, server-computed open/closed status, the operating status (temporarily / permanently closed), the platform Ramadan window, and a curated photo gallery for every venue. It ships 29 new endpoints across public, business, admin and platform-calendar surfaces, adds `openingHours` and `gallery` to the venue detail, and retires the three legacy `/media` routes with **410 Gone**.

Everything below was written from the code on `production` (commits `33a494c` through `782dd27`). Where the code differs from the design spec, the code wins; §12 lists every difference.

---

## Deploy note (read this first)

Everything that must happen before or at deploy. The full checklist, with the SQL, is §9.

1. **Run V106 on a real Postgres first: staging or a prod clone. This is REQUIRED and has not been done yet.** The SQL was only parsed (pglast) and the entities and JPQL were validated offline. Nothing has ever booted against it. Run Flyway V1…V106, boot the gateway once with `ddl-auto: validate`, and run the constraint checks in §9.2. If an entity type doesn't match the DDL, new pods crash-loop **after** V106 is already applied.
2. **V105 before V106.** Both are on `production`. Ship them in the same image, or V105 first. Flyway runs with `outOfOrder` off, so a history that has V106 but not V105 fails validation at startup. Never deploy a build that carries V106 without V105.
3. **S3 IAM preflight** on the backend role for bucket `app.aws.s3.bucket`:
   - `s3:GetObject` on `venues/*`, for the `HeadObject` at attach;
   - `s3:DeleteObject` on `venues/*`, for photo deletes (never used in production before);
   - `s3:ListBucket` on the bucket, so a missing key answers 404, not 403;
   - `s3:PutObject` on `venues/*`, which the presigned uploads already use.
   See §9.3 for what breaks without each one.
4. **Ship the whole backend feature in one release**, off-peak (early morning Baghdad time). If a new pod fails at startup with `canceling statement due to lock timeout`, V106 rolled back completely and the old pods keep serving. Simply redeploy (§9.4).
5. **Users' tokens go stale once.** V106 bumps `users.token_version` for every holder of the venue roles `owner`/`manager` and the business roles `business_owner`/`business_manager`. Each of these users gets one 401 `token_stale` on their next request. The app refreshes silently and retries. Expect one refresh wave. No action is needed.
6. **Admins sign in again.** Admin JWTs carry the permission set frozen at issue, with no `token_version`. `admin:platform_calendar:manage` (SUPERADMIN only) therefore reaches a live session only on the dashboard's next token refresh, which can be up to 8 h away. Tell every SUPERADMIN to sign out and back in after the deploy. Otherwise the Platform Calendar page stays missing for them.
7. **After deploy**, a SUPERADMIN enters the Ramadan 1448 window (expected around 2027-02-08 → 2027-03-09) and corrects it on moon-sighting night. Until a window exists, every venue runs its regular week.

---

## 1. What this feature is (and isn't)

**Is**:
- **Weekly hours per venue.** Every venue has a *Regular* week, plus an optional *Ramadan* week. Each day is exactly one of `CLOSED`, `OPEN_24H`, or `HOURS` with 1–4 ranges. A range whose close ≤ open runs past midnight.
- **Branch overrides.** A branch either follows the venue's weeks or owns its own Regular + Ramadan weeks (`venue_locations.hours_override`).
- **Operating status.** `OPEN`, `TEMPORARILY_CLOSED` (with an optional `reopensOn` date, after which the venue reopens by itself) or `PERMANENTLY_CLOSED`. It is set on the venue, and a branch can override it.
- **A platform Ramadan window.** A SUPERADMIN sets the inclusive Asia/Baghdad dates on the dashboard. An edit applies on the next request, on every pod.
- **Status computed on every request**, in Asia/Baghdad: `state`, `openNow`, `closesAt` / `opensAt`, `closingSoon` / `openingSoon` (60 min), `alwaysOpen`, `nextChangeAt`, and the Ramadan season. The status is never stored, cached or indexed.
- **A curated photo gallery** («صور المكان»):
  - up to **24 photos per venue** (hidden photos count), JPEG/PNG/WebP, ≤ 10 MB each;
  - width, height and an optional ThumbHash placeholder;
  - 0–3 tags from a fixed vocabulary of 8;
  - an optional branch attribution;
  - admin hide / unhide / hard delete.

**Isn't** (v1):
- "Open now" on list cards, map pins, trending or search, or as a filter. The status exists on the venue detail and on `GET /venues/{id}/hours` only.
- Dated special hours (Eid days, Ashura, Arbaeen, private events).
- Gallery videos, visitor photos, captions, reports on photos, server-side resizing.
- Admin gallery **upload**. Admins moderate only.
- An instant CDN purge on delete (§6.7).

**Where it sits next to existing venue media:**

| Concept | Storage | Status after V106 |
|---|---|---|
| Venue cover | `venues.cover_url` (image **or** video) | Unchanged. The card cover still prefers it |
| Legacy media | `venue_media` | Frozen: nothing reads it, and its three write endpoints answer 410 |
| **Gallery photo** | `venue_gallery_photos` | New: curated decor, seating and atmosphere photos |
| Food / menu photos | Posts, Menu | Unchanged; deliberately **not** gallery tags |

---

## 2. Data model (V106)

`hangout_api/hangout-gateway/src/main/resources/db/migration/V106__venue_hours_status_calendar_gallery.sql`

Flyway runs the file as **one transaction**. Its first statement is `SET LOCAL lock_timeout = '5s'`: when an `ALTER` waits more than 5 s for its ACCESS EXCLUSIVE lock on `venues`, `venue_locations` or `venue_hours`, the whole migration fails and rolls back instead of queueing every venue read behind it.

### `venue_hours` (the V2 table, extended)

```
id                UUID PK
venue_id          UUID NOT NULL → venues(id) ON DELETE CASCADE
day_of_week       SMALLINT NOT NULL  -- 0 = Sunday … 6 = Saturday (V2 CHECK)
open_time         TIME nullable
close_time        TIME nullable
is_closed         BOOLEAN NOT NULL   -- V106: SET NOT NULL (legacy NULLs → FALSE first)
is_ramadan        BOOLEAN NOT NULL   -- V106: SET NOT NULL
venue_location_id UUID nullable      -- NEW. NULL = the venue-default week; else that branch's OWN week
is_open_24h       BOOLEAN NOT NULL DEFAULT FALSE   -- NEW

FK fk_venue_hours_branch_same_venue:
    (venue_location_id, venue_id) → venue_locations(id, venue_id) ON DELETE CASCADE
    -- proves in the DB that a branch row's branch belongs to the same venue

CHECK chk_venue_hours_shape — a row is exactly one of:
    CLOSED marker   is_closed,   NOT is_open_24h, both times NULL
    24h marker      is_open_24h, NOT is_closed,   both times NULL
    range           both times set, open_time <> close_time, both < 24:00

UNIQUE INDEX ux_venue_hours_slot (venue_id, COALESCE(venue_location_id, nil-uuid),
                                  is_ramadan, day_of_week, COALESCE(open_time, 00:00))
INDEX idx_venue_hours_location (venue_location_id) WHERE venue_location_id IS NOT NULL
```

- **One row per range.** A `CLOSED` or `OPEN_24H` day is one marker row. An `HOURS` day has one row per range.
- **Whole weeks only.** The service always writes all 7 days of a season at once, so "no rows for a season" means "not set". Seven `CLOSED` days is a different thing: closed all week.
- **Legacy rows are normalised first.** Before the constraints are added, V106 rewrites any legacy rows: NULL flags become FALSE, `24:00` becomes `00:00`, equal open/close becomes a 24 h marker, a half-set range becomes CLOSED, and duplicate slots are deleted. No writer ever existed on production, so zero rows are expected (§9.1).

### `venues` and `venue_locations` (new columns)

```
venues.operating_status          VARCHAR(20) NOT NULL DEFAULT 'OPEN'   -- OPEN | TEMPORARILY_CLOSED | PERMANENTLY_CLOSED
venues.reopens_on                DATE nullable       -- CHECK: only with TEMPORARILY_CLOSED
venues.hours_updated_at          TIMESTAMPTZ nullable

venue_locations.hours_override   BOOLEAN NOT NULL DEFAULT FALSE        -- FALSE = inherit the venue's weeks
venue_locations.operating_status VARCHAR(20) nullable                  -- NULL = inherit the venue's status
venue_locations.reopens_on       DATE nullable       -- CHECK: only with TEMPORARILY_CLOSED
venue_locations.hours_updated_at TIMESTAMPTZ nullable
UNIQUE uq_venue_locations_id_venue (id, venue_id)     -- target of the composite FK above
```

**Entity rules.**
- `Venue.operatingStatus` is `@Builder.Default OPEN`. Without it, a builder-created venue would INSERT an explicit NULL into the NOT NULL column (the V105 bug class).
- `VenueLocation.hoursOverride` is a primitive whose zero value, `false`, is the safe default.
- `Venue` and `VenueLocation` are `@DynamicUpdate`. The status and flag columns are written **only** by JPQL updates (§8), never by setting a field and saving.

### `platform_calendar_periods`

```
id                   UUID PK
kind                 VARCHAR(20) NOT NULL   -- CHECK kind IN ('RAMADAN'); HOLIDAY later
starts_on, ends_on   DATE NOT NULL          -- INCLUSIVE Asia/Baghdad days: first .. last fasting day
label_ar, label_en   VARCHAR(100) nullable
note                 VARCHAR(500) nullable  -- e.g. "Sunni Endowment announcement, 2027-02-07 19:40"
created_by_admin_id, updated_by_admin_id   UUID → admin_accounts(id) ON DELETE SET NULL
created_at, updated_at TIMESTAMPTZ NOT NULL

CHECK chk_pcp_window: ends_on >= starts_on AND ends_on - starts_on <= 34   (at most 35 days)
INDEX idx_pcp_kind_window (kind, starts_on, ends_on)
```

There is no EXCLUDE constraint. The service rejects overlaps (409 `CALENDAR_OVERLAP`), and an overlap would be harmless to the resolver anyway: a day is Ramadan if **any** window holds it.

### `venue_gallery_photos`

```
id                  UUID PK
venue_id            UUID NOT NULL → venues(id) ON DELETE CASCADE
venue_location_id   UUID nullable → venue_locations(id) ON DELETE SET NULL   -- optional branch attribution
s3_key              VARCHAR(500) NOT NULL UNIQUE (uq_venue_gallery_photos_s3_key)
url                 VARCHAR(500) NOT NULL        -- full CDN URL
content_type        VARCHAR(20) NOT NULL         -- CHECK image/jpeg | image/png | image/webp
byte_size           INTEGER NOT NULL             -- from S3 HeadObject; CHECK 1..10485760
width, height       INTEGER NOT NULL             -- px, client-reported; CHECK 1..20000
placeholder_hash    VARCHAR(64) nullable         -- ThumbHash, base64
tags                VARCHAR(24)[] NOT NULL DEFAULT '{}'
                    -- CHECK ≤ 3, no NULL element, ⊆ {inside, outside, seating, ambience,
                    --                                facade, view, family_section, private_room}
sort_order          INTEGER NOT NULL DEFAULT 0   -- CHECK ≥ 0; not unique (ties sort by id)
is_hidden           BOOLEAN NOT NULL DEFAULT FALSE   -- admin takedown
hidden_at, hidden_reason (VARCHAR(500)), hidden_by_admin_id → admin_accounts ON DELETE SET NULL
                    -- CHECK chk_vgp_hidden: hidden ⇒ hidden_at set; visible ⇒ all three NULL
uploaded_by_user_id UUID → users(id) ON DELETE SET NULL
created_at, updated_at TIMESTAMPTZ NOT NULL

INDEX idx_vgp_venue_order (venue_id, sort_order, id)   -- ordered lists + card-cover fallback
INDEX idx_vgp_location (venue_location_id) WHERE venue_location_id IS NOT NULL
```

### What happens on delete

| Event | `venue_hours` | `venue_gallery_photos` |
|---|---|---|
| Venue deleted | CASCADE | CASCADE |
| Branch hard-deleted (online-only conversion, admin delete) | that branch's own weeks CASCADE | `venue_location_id` → NULL (the photo becomes venue-wide) |
| Branch soft-deleted (`active = false`) | rows kept, ignored on read (only active branches are evaluated) | attribution kept |
| Admin account deleted | — | `hidden_by_admin_id` → NULL; calendar `*_by_admin_id` → NULL |
| User deleted | — | `uploaded_by_user_id` → NULL |

### Permissions seeded

| Permission | Category | Granted to | Notes |
|---|---|---|---|
| `venue:hours:manage` | `venue` | `owner`, `manager` (venue scope); `business_owner`, `business_manager` (business scope) | **New.** Not staff. Followed by the `token_version` bump (Deploy note, item 5) |
| `admin:platform_calendar:manage` | `admin` | `SUPERADMIN` only | **New.** Admin JWTs freeze permissions: sign in again (Deploy note, item 6) |
| `venue:media:upload` | `venue` | owner, manager, **staff**, business_owner, business_manager | Existing (V14/V41), reused for gallery list + upload |
| `venue:media:delete` | `venue` | owner, manager, business_owner, business_manager | Existing, reused for gallery edit, reorder and delete |
| `admin:venues:manage` | `admin` | SUPERADMIN, ADMIN | Existing (V24), reused for admin hours and gallery moderation |

---

## 3. Endpoints — 29 new, 3 retired

Every response uses the standard envelope, `{ "success", "data", "error", "timestamp" }`. Null fields are omitted, so a `DELETE` that answers `ApiResponse.ok(null)` has no `data` key. Error messages of this feature start with a stable `CODE:` (§7).

### 3.1 Public surface (no auth; `GET /api/v1/venues/**` is `permitAll`)

| Method | Path | Response | Notes |
|---|---|---|---|
| `GET` | `/api/v1/venues/{venueId}/hours` | `VenueOpeningHoursResponse` | The same object as `VenueResponse.openingHours`. Unknown venue → 404 `Venue not found`. |
| `GET` | `/api/v1/venues/{venueId}/gallery?tag=&locationId=` | `List<GalleryPhotoResponse>` | Visible photos only, ordered `(sortOrder, id)`. See the filters below. |
| `GET` | `/api/v1/venues/{venueId}` and `/api/v1/venues/handle/{handle}` | `VenueResponse` | **Changed**: now carries `openingHours` and `gallery` (§4.1), and the legacy `hours` / `mediaUrls` change their source (§4.6). |

`/hours` costs 4 small queries: the venue, its active branches, the hours rows and the Ramadan windows.

Gallery filters:
- `tag` must be one of the 8 codes (unknown → 400 `GALLERY_TAG_UNKNOWN`). A blank `tag` means no filter.
- `locationId` returns that branch's photos **plus the venue-wide ones**. A `locationId` that is not an active branch of this venue → 404 `BRANCH_NOT_FOUND`.
- Unknown venue → 404 `Venue not found`.

None of these endpoints is HTTP-cached (no `@PublicCacheControl`): the status depends on the time of the request, and a takedown must disappear on the next request.

### 3.2 Business — hours & status

Base path: `/api/v1/business/venues/{venueId}`. Controller: `BusinessVenueHoursController`.

Every endpoint has `@PreAuthorize("hasAuthority('venue:hours:manage')")`, plus the per-venue check in §3.7. Every endpoint answers **200** with the whole editor model (`BusinessVenueHoursResponse`, §4.2) as it stands after the write.

| Method | Path | Body | Effect |
|---|---|---|---|
| `GET` | `/hours` | — | Editor model |
| `PUT` | `/hours` | `UpdateVenueHoursRequest` | Replaces the venue-default **Regular** week (required). For the **Ramadan** week: `ramadan` present → replaces it; absent or null → **keeps** it; `removeRamadan: true` → deletes it |
| `DELETE` | `/hours` | — | Deletes both venue-default weeks. The venue and every inheriting branch become UNKNOWN. Branches with their own weeks and all statuses are untouched |
| `PUT` | `/locations/{locationId}/hours` | `UpdateBranchHoursRequest` | `mode: OWN` replaces the branch's own Regular week, applies the same keep/replace/remove rule to its own Ramadan week, and sets `hours_override`. `mode: INHERIT` deletes both of the branch's weeks and clears the override |
| `PUT` | `/operating-status` | `UpdateOperatingStatusRequest` | The venue's status (+ `reopensOn`) |
| `PUT` | `/locations/{locationId}/operating-status` | `UpdateBranchOperatingStatusRequest` | `mode: OWN` sets the branch's own status; `mode: INHERIT` stores NULL |

A `locationId` that is not an **active** branch of this venue → 404 `BRANCH_NOT_FOUND`. That includes every id on an online-only venue.

### 3.3 Business — gallery

Base path: `/api/v1/business/venues/{venueId}/gallery`. Controller: `BusinessVenueGalleryController`.

| Method | Path | Permission (JWT gate + per-venue check) | Body / params | Response |
|---|---|---|---|---|
| `GET` | `/` | `venue:media:upload` | — | `BusinessGalleryResponse`: every photo, **hidden included** |
| `GET` | `/upload-url` | `venue:media:upload` | `?contentType=&contentLength=` | `GalleryUploadUrlResponse` |
| `POST` | `/` | `venue:media:upload` | `AttachGalleryPhotoRequest` | **201** new `BusinessGalleryPhotoResponse`, or **200** with the existing photo when this key is already attached (retry-safe) |
| `PATCH` | `/{photoId}` | `venue:media:delete` | `UpdateGalleryPhotoRequest` | `BusinessGalleryPhotoResponse` |
| `PUT` | `/order` | `venue:media:delete` | `ReorderGalleryRequest` | `BusinessGalleryResponse` |
| `DELETE` | `/{photoId}` | `venue:media:delete` | — | no `data` |

- **Upload.** Staff can list and upload. Editing tags or branch, reordering and deleting need `venue:media:delete` (owner and manager).
- **`upload-url` params.** Both are `required = false` on purpose and validated in the service. A missing or bad value therefore answers the feature's code (`GALLERY_INVALID_CONTENT_TYPE` / `GALLERY_INVALID_LENGTH`), not the generic `Missing required parameter`.
- **A photo of another venue** → 404 `PHOTO_NOT_FOUND`.

### 3.4 Admin — venue hours & gallery (`admin:venues:manage`)

Both controllers live in **hangout-venue**, next to `AdminEventController` (the PUBLIC_EVENTS placement). The admin side shares `VenueHoursServiceImpl` / `VenueGalleryServiceImpl` with the business side; there is no second copy of the logic in hangout-admin. There is no per-venue check: an admin may act on any venue. Every write adds a row to `admin_audit_log` (§8).

| Method | Path | Body | Effect / audit action |
|---|---|---|---|
| `GET` | `/api/v1/admin/venues/{venueId}/hours` | — | `BusinessVenueHoursResponse` |
| `PUT` | `/api/v1/admin/venues/{venueId}/hours` | `UpdateVenueHoursRequest` | as business · `VENUE_HOURS_UPDATE` |
| `DELETE` | `/api/v1/admin/venues/{venueId}/hours` | — | as business · `VENUE_HOURS_CLEAR` |
| `PUT` | `/api/v1/admin/venues/{venueId}/locations/{locationId}/hours` | `UpdateBranchHoursRequest` | as business · `VENUE_BRANCH_HOURS_UPDATE` |
| `PUT` | `/api/v1/admin/venues/{venueId}/operating-status` | `UpdateOperatingStatusRequest` | as business · `VENUE_STATUS_UPDATE` |
| `PUT` | `/api/v1/admin/venues/{venueId}/locations/{locationId}/operating-status` | `UpdateBranchOperatingStatusRequest` | as business · `VENUE_BRANCH_STATUS_UPDATE` |
| `GET` | `/api/v1/admin/venues/{venueId}/gallery` | — | `List<BusinessGalleryPhotoResponse>`, hidden included (with `hiddenReason` / `hiddenAt`) |
| `POST` | `/api/v1/admin/venues/{venueId}/gallery/{photoId}/hide` | `{ "reason": "…" }` (required, ≤ 500) | `BusinessGalleryPhotoResponse` · `VENUE_PHOTO_HIDE` |
| `POST` | `/api/v1/admin/venues/{venueId}/gallery/{photoId}/unhide` | — | `BusinessGalleryPhotoResponse` · `VENUE_PHOTO_UNHIDE` |
| `DELETE` | `/api/v1/admin/venues/{venueId}/gallery/{photoId}` | — | no `data` · `VENUE_PHOTO_DELETE` |

An unknown venue → 404 `VENUE_NOT_FOUND`.

### 3.5 Admin — platform calendar (`admin:platform_calendar:manage`, SUPERADMIN only)

Base path: `/api/v1/admin/platform-calendar`. Controller: `AdminPlatformCalendarController` in hangout-admin (a platform setting, like `AdminLocationController`).

| Method | Path | Body | Response |
|---|---|---|---|
| `GET` | `/?kind=RAMADAN` | — | `List<PlatformCalendarPeriodResponse>`, latest `startsOn` first. `kind` defaults to `RAMADAN`; any other value → 400 `CALENDAR_INVALID_KIND` |
| `GET` | `/status` | — | `PlatformCalendarStatusResponse` (the dashboard's status card) |
| `POST` | `/` | `PlatformCalendarPeriodRequest` | **201** period |
| `PUT` | `/{id}` | `PlatformCalendarPeriodRequest` | period. A **full replace**: an omitted label or note is cleared |
| `DELETE` | `/{id}` | — | no `data` |

- **Past and active windows can be edited and deleted**, so a correction on moon-sighting night always works.
- **There is no public calendar endpoint.** The app receives the window through `openingHours.ramadanWindow`.
- **An ADMIN** (not SUPERADMIN) gets 403.

### 3.6 Legacy venue media — 410 Gone

| Method | Path | Answer |
|---|---|---|
| `GET` | `/api/v1/business/venues/{venueId}/media/upload-url` | **410** `GONE: use /api/v1/business/venues/{venueId}/gallery` |
| `POST` | `/api/v1/business/venues/{venueId}/media/confirm` | **410** (same) |
| `DELETE` | `/api/v1/business/venues/{venueId}/media/{mediaId}` | **410** (same) |

- **Gates.** The routes keep their `@PreAuthorize` (`venue:media:upload` / `venue:media:delete`), so a caller without the authority still gets 403 first.
- **Query params.** The old query params are no longer bound: even a call with a parameter missing gets the 410.
- **Logging.** Each hit logs one WARN line: `Legacy venue media endpoint called venueId=… path=…`.
- **Why.** Nothing reads `venue_media` any more, so a write that still "worked" would be a silent black hole. There are zero callers, and `confirm` never returned an id, so it could not be adapted to the new table.
- **Service methods.** The three `BusinessVenueService` media methods are `@Deprecated`.

### 3.7 The per-venue permission check (why the new endpoints can answer 403)

- **The problem.** `AuthServiceImpl` puts the **union** of a user's permissions across all their venue and business roles into the JWT. `@PreAuthorize("hasAuthority('venue:media:delete')")` therefore only proves the user holds that permission *somewhere*: an owner of venue A who is staff at venue B passes it for B.
- **The fix.** Every new business endpoint keeps `@PreAuthorize` as the cheap coarse gate. The service then calls `VenuePermissionGuard.require(userId, venueId, permission)` first:

  1. The venue must exist, else 404 `VENUE_NOT_FOUND: venue not found`.
  2. `VenueAccessService.effectivePermissions(userId, venueId)` must contain the permission. That set is the permissions of the user's venue-scope role **here**, united with those of their business-scope roles at the venue's parent businesses (the same thing `/users/me/access` reports).
  3. Otherwise the guard throws Spring's `AccessDeniedException`. `GlobalExceptionHandler` answers it with the same **403** `"Access denied"` a failed `@PreAuthorize` gives. The `VENUE_PERMISSION_DENIED:` message is logged, not returned.

- **Cost.** 2–3 small indexed queries per call. Nothing is cached, so a role change applies on the next request.
- **Scope.** Subscription-tier permissions are not included; none of the three permissions comes from a tier.
- **Status codes.** Older venue endpoints still answer **400** "Access denied to this venue" for the same situation. Only the new endpoints answer 403.

---

## 4. Response shapes

**Time values are pre-formatted Strings, always.** Production has no `spring.jackson` config, and clients must never re-interpret a value in the device's zone:

| Kind | Format | Example |
|---|---|---|
| wall-clock time | `HH:mm` | `"02:00"` |
| date | `YYYY-MM-DD` (Baghdad calendar date) | `"2026-09-29"` |
| Baghdad date-time | ISO-8601 with the offset | `"2026-09-29T02:00:00+03:00"` |
| stored instant (`*UpdatedAt`, `createdAt`, `hiddenAt`) | ISO-8601 UTC, whole seconds | `"2026-09-20T10:12:44Z"` |

`dayOfWeek` is always **0 = Sunday … 6 = Saturday** (the storage and wire convention). Iraq's Saturday-first week is a display concern only.

### 4.1 `VenueResponse.openingHours` = `GET /venues/{venueId}/hours` (`VenueOpeningHoursResponse`)

The excerpt below comes from the contract fixture (`VenueResponseJsonContractTest`, evaluated Monday 2026-09-28 21:40 Baghdad). The venue has two branches: Karrada is primary and inherits; the second branch has its own hours.

```json
{
  "timezone": "Asia/Baghdad",
  "evaluatedAt": "2026-09-28T21:40:00+03:00",
  "ramadanWindow": null,
  "summary": {
    "locationId": "68d5c7be-7a14-44d7-83cb-9d59dac62764",
    "hoursSource": "VENUE",
    "statusSource": "VENUE",
    "operatingStatus": "OPEN",
    "reopensOn": null,
    "status": {
      "state": "OPEN",
      "openNow": true,
      "closingSoon": false,
      "openingSoon": false,
      "alwaysOpen": false,
      "closesAt": { "at": "2026-09-29T02:00:00+03:00", "localTime": "02:00", "localDate": "2026-09-29", "dayOfWeek": 2, "dayOffset": 1 },
      "opensAt": null,
      "nextChangeAt": "2026-09-29T02:00:00+03:00",
      "season": "REGULAR",
      "reopensOn": null,
      "spanOperatingDate": "2026-09-28",
      "spanSeason": "REGULAR"
    },
    "today": {
      "date": "2026-09-28", "dayOfWeek": 1, "season": "REGULAR", "kind": "HOURS",
      "intervals": [ { "opens": "09:00", "closes": "02:00", "overnight": true } ],
      "ramadanEveIntervals": []
    },
    "lastNight": null,
    "regular": { "days": [
      { "dayOfWeek": 0, "kind": "HOURS", "intervals": [
          { "opens": "09:00", "closes": "13:00", "overnight": false },
          { "opens": "16:00", "closes": "02:00", "overnight": true } ] },
      { "dayOfWeek": 1, "kind": "HOURS", "intervals": [ { "opens": "09:00", "closes": "02:00", "overnight": true } ] },
      "… dayOfWeek 2..4 …",
      { "dayOfWeek": 5, "kind": "CLOSED",   "intervals": [] },
      { "dayOfWeek": 6, "kind": "OPEN_24H", "intervals": [] }
    ] },
    "ramadan": { "days": [ { "dayOfWeek": 0, "kind": "HOURS", "intervals": [ { "opens": "20:00", "closes": "03:30", "overnight": true } ] }, "… 6 more …" ] },
    "hoursUpdatedAt": "2026-09-20T10:12:44Z"
  },
  "branches": [
    { "locationId": "68d5c7be-7a14-44d7-83cb-9d59dac62764", "hoursSource": "VENUE", "statusSource": "VENUE", "…": "same as summary" },
    { "locationId": "600ecfc7-8f00-4743-95d8-15d82dce8c3f", "hoursSource": "BRANCH", "statusSource": "VENUE",
      "operatingStatus": "OPEN", "reopensOn": null,
      "status": { "state": "OPEN", "openNow": true,
                  "closesAt": { "at": "2026-09-29T00:00:00+03:00", "localTime": "00:00", "localDate": "2026-09-29", "dayOfWeek": 2, "dayOffset": 1 },
                  "nextChangeAt": "2026-09-29T00:00:00+03:00", "…": "…" },
      "today": { "date": "2026-09-28", "dayOfWeek": 1, "season": "REGULAR", "kind": "HOURS",
                 "intervals": [ { "opens": "10:00", "closes": "00:00", "overnight": true } ], "ramadanEveIntervals": [] },
      "lastNight": null, "regular": { "days": [ "…7…" ] }, "ramadan": null,
      "hoursUpdatedAt": "2026-09-22T08:01:10Z" }
  ]
}
```

| Field | Meaning |
|---|---|
| `timezone` | always `"Asia/Baghdad"` |
| `evaluatedAt` | the evaluation instant at `+03:00`. The app measures its refresh timers from it, not from the device clock |
| `ramadanWindow` | `{startsOn, endsOn, active}`: the window containing today (`active: true`), else the next one starting **within 30 days** (`active: false`), else `null` |
| `summary` | the **primary** branch's effective scope (the top-level address mirrors the primary too), or the venue default for an online-only venue or one with no active branch |
| `branches` | one scope per active branch, primary first; **`[]` unless ≥ 2 active branches** |

**`ScopeHoursResponse`** (one effective scope, after inheritance; the client never resolves inheritance itself):

| Field | Meaning |
|---|---|
| `locationId` | the branch; `null` = the venue-default scope |
| `hoursSource` | `VENUE` \| `BRANCH` \| `NONE`. `NONE` ⇒ `regular` and `today` are null and the state is `UNKNOWN`, unless the scope is closed by its status |
| `statusSource` | `VENUE` \| `BRANCH` |
| `operatingStatus`, `reopensOn` | the effective **stored** status and reopen date |
| `status` | the computed `OpenStatusResponse` (below) |
| `today` | today's operating day after season selection (`TodayHoursResponse`); `null` when hours are not set |
| `lastNight` | the same shape for yesterday. Present **only** while the state is `OPEN` in last night's after-midnight tail, so a card can say «الليلة 6:00 م – 3:00 ص» next to "open now" |
| `regular`, `ramadan` | the effective weeks (`WeeklyScheduleResponse`, exactly 7 days, Sunday first) or `null` |
| `hoursUpdatedAt` | last replace of the week that applies, or `null` |

**`OpenStatusResponse`:**

| Field | Meaning |
|---|---|
| `state` | `OPEN` \| `CLOSED` \| `TEMPORARILY_CLOSED` \| `PERMANENTLY_CLOSED` \| `UNKNOWN` |
| `openNow` | `true`/`false`; **`null` only when `UNKNOWN`** (hours not set; the app never guesses "closed") |
| `closingSoon` | OPEN and the close is ≤ 60 min away (inclusive) |
| `openingSoon` | CLOSED and the next opening is ≤ 60 min away (inclusive). Always `false` while TEMPORARILY_CLOSED |
| `alwaysOpen` | OPEN with no close inside the 7-day horizon ("Open 24 hours"); `closesAt` is then `null` |
| `closesAt` | `Moment`: OPEN and not `alwaysOpen`. The **real** closing instant, with touching ranges merged |
| `opensAt` | `Moment`: CLOSED or TEMPORARILY_CLOSED with a known next opening within the horizon; else `null` |
| `nextChangeAt` | ISO offset date-time at which `openNow` flips (`closesAt` when OPEN, else `opensAt`), or `null`. The app refetches `/hours` then |
| `season` | `REGULAR` \| `RAMADAN` of **today's** operating day (day level) |
| `reopensOn` | `YYYY-MM-DD` while TEMPORARILY_CLOSED with a future reopen date |
| `spanOperatingDate` | OPEN only: the operating day of the night we are in (yesterday during last night's tail) |
| `spanSeason` | OPEN only: `REGULAR` \| `RAMADAN` of that occurrence. **Drives the Ramadan badge**: during Eid night after midnight `season` is REGULAR but `spanSeason` is RAMADAN |

**`Moment`**: `{ at, localTime, localDate, dayOfWeek, dayOffset }`. `dayOffset` is the number of whole days from the Baghdad `today` of the evaluation: 0 = today, 1 = tomorrow, up to 7 at the horizon edge.

**`TodayHoursResponse`** (used for `today` and `lastNight`):
- `date`, `dayOfWeek` and `season` describe the operating day.
- `kind` + `intervals` are the day's **own** rule. The state can be OPEN from last night's tail while `today.kind` is `CLOSED`.
- `ramadanEveIntervals` is non-empty **only on the day before Ramadan day 1**. It holds the Ramadan night ranges added to that day (§6.5).

**`HoursIntervalResponse`**: `{ opens, closes, overnight }`. `overnight` means `closes <= opens`, i.e. the range ends the next calendar day. `closes: "00:00"` means "until midnight".

### 4.2 `BusinessVenueHoursResponse` (the editor model)

Returned by business and admin `GET /hours` and by **every** hours or status write.

```json
{
  "venueId": "a185bdc1-…",
  "timezone": "Asia/Baghdad",
  "evaluatedAt": "2026-09-28T21:40:00+03:00",
  "today": "2026-09-28",
  "ramadanWindow": { "startsOn": "2027-02-08", "endsOn": "2027-03-09", "active": false },
  "venue": {
    "locationId": null, "labelAr": null, "labelEn": null, "districtNameAr": null, "districtNameEn": null,
    "isPrimary": false, "hoursMode": "OWN", "statusMode": "OWN",
    "operatingStatus": "OPEN", "reopensOn": null, "statusExpired": false,
    "regular": { "days": [ "…7…" ] }, "ramadan": { "days": [ "…7…" ] },
    "effectiveStatus": { "…": "OpenStatusResponse" }, "hoursUpdatedAt": "2026-09-20T10:12:44Z"
  },
  "branches": [
    { "locationId": "68d5c7be-…", "labelAr": "الكرادة", "labelEn": null,
      "districtNameAr": "الكرادة", "districtNameEn": "Karrada", "isPrimary": true,
      "hoursMode": "INHERIT", "statusMode": "INHERIT", "operatingStatus": null, "reopensOn": null,
      "statusExpired": false, "regular": null, "ramadan": null,
      "effectiveStatus": { "…": "…" }, "hoursUpdatedAt": null }
  ]
}
```

- **`today`** is the Baghdad date. The editor's reopen-date picker uses it, never the device date.
- **`ramadanWindow`** is the active window, else the next future window with **no look-ahead limit** (unlike the public 30 days).
- **`venue` and `branches`** use the same record, `BusinessScopeHoursResponse`. On `venue`, `locationId`, `labelAr`, `labelEn`, `districtNameAr` and `districtNameEn` are always `null`, `isPrimary` is `false`, and both modes are `OWN`.
- **`branches` lists every active branch, a single one included.** A sole branch can still carry an override, for example after a 2 → 1 branch delete or when an admin set one, and the editor must show that.
- **A branch shows what it stores.** `regular`, `ramadan` and `operatingStatus` are the branch's **own** values, `null` while it inherits. `effectiveStatus` is computed after inheritance.
- **`hoursUpdatedAt`** is the last replace of this scope's own weeks. An inheriting branch has `null`: switching to INHERIT clears it.
- **`statusExpired`** is `true` when the scope is TEMPORARILY_CLOSED and `reopensOn <= today`. The closure has already lapsed by itself, and the editor offers "set OPEN".

### 4.3 Gallery shapes

**`GalleryPhotoResponse`** (public; the items of `VenueResponse.gallery.photos` and of `GET /venues/{id}/gallery`):
```json
{
  "id": "e3a130da-9982-4383-88a4-11ba771176c5",
  "url": "https://d1b744kvymcq8d.cloudfront.net/venues/a185bdc1-…/gallery/5c1e….webp",
  "width": 1536, "height": 2048, "aspectRatio": 0.75,
  "placeholderHash": "3OcRJYB4d3h/iIeHeEh3eIhw+j2w",
  "tags": ["inside", "seating"],
  "locationId": null,
  "sortOrder": 0,
  "createdAt": "2026-09-27T18:03:11Z"
}
```
`aspectRatio` is `width / height` rounded to 4 decimals, so the grid can lay out before the image loads. `locationId: null` means the photo is venue-wide.

**`BusinessGalleryPhotoResponse`** is the same keys, flat, plus:
```json
{ "hidden": false, "hiddenReason": null, "hiddenAt": null,
  "contentType": "image/webp", "byteSize": 412933, "uploadedByUserId": "…" }
```

**`VenueResponse.gallery`** (`VenueGalleryResponse`):
```json
{ "totalCount": 1,
  "photos": [ { "…": "GalleryPhotoResponse" } ],
  "tagCounts": { "inside": 1, "seating": 1 } }
```
- `photos` is every **visible** photo (≤ 24), in `(sortOrder, id)` order.
- `tagCounts` holds only the tags that occur, in vocabulary order.
- Neither is ever `null`.

**`BusinessGalleryResponse`** (manage list; also the answer of `PUT /order`):
```json
{ "photos": [ { "…": "BusinessGalleryPhotoResponse, hidden included" } ],
  "maxPhotos": 24, "remaining": 23,
  "privacyHintTags": ["family_section", "private_room"] }
```
- `remaining` = `max(0, 24 − photos.length)`.
- `privacyHintTags` lists the tags under which the manager shows the privacy hint «لا تنشر صوراً يظهر فيها زبائن يمكن التعرف عليهم دون موافقتهم».

**`GalleryUploadUrlResponse`**:
```json
{ "uploadUrl": "https://…s3…/venues/{venueId}/gallery/{uuid}.jpg?X-Amz-…",
  "key": "venues/{venueId}/gallery/{uuid}.jpg",
  "expiresInSeconds": 300, "maxBytes": 10485760 }
```

### 4.4 Platform calendar shapes

```jsonc
// PlatformCalendarPeriodResponse
{ "id": "…", "kind": "RAMADAN", "startsOn": "2027-02-08", "endsOn": "2027-03-09",
  "days": 30,                 // inclusive length, 1..35
  "state": "UPCOMING",        // ACTIVE | UPCOMING | PAST, against the Baghdad today
  "labelAr": "رمضان ١٤٤٨", "labelEn": "Ramadan 1448",
  "note": "Sunni Endowment announcement, 2027-02-07 19:40",
  "createdAt": "2026-09-29T08:00:00Z", "updatedAt": "2026-09-29T08:00:00Z" }

// PlatformCalendarStatusResponse (GET /status)
{ "today": "2027-01-10",
  "activeRamadan": null,      // the window containing today
  "nextRamadan": null,        // earliest window starting after today, no look-ahead limit
  "lastRamadan": { "…": "period" },   // the window that ended most recently
  "venuesWithHours": 412,     // venues with a venue-default Regular week
  "venuesWithRamadanHours": 57,
  "reminder": { "show": true, "approxNextStart": "2027-02-08" } }
```

The `reminder` rule is in §6.8.

### 4.5 `VenueResponse` changes

`openingHours` (`VenueOpeningHoursResponse`) and `gallery` (`VenueGalleryResponse`) are appended after `onlineOnly`, the old last key. Both are **never null**: a venue without hours has `summary.hoursSource = NONE` and state `UNKNOWN`, and a venue without photos has `totalCount: 0`. `GET /venues/handle/{handle}` goes through the same `getById`, so the map venue sheet gets the same data.

### 4.6 Legacy fields kept byte-compatible for shipped builds

**`hours`** (`List<VenueHoursResponse>`, `VenueHoursLegacyProjection`):
- **Source.** Only the **venue-default** rows (`venue_location_id IS NULL`), so an old client never sees a branch's days twice.
- **Order.** `ramadan` → `dayOfWeek` → open time, markers first.
- **Ids.** Every `id` is the real row UUID. It is stable across reads and changes only when that week is saved.
- **Row shapes.** Times stay `"HH:mm:ss"`:
  - a `CLOSED` marker → `openTime: null, closeTime: null, closed: true`;
  - an `OPEN_24H` marker → `openTime: "00:00:00", closeTime: "00:00:00", closed: false`, which reads as a full 24 h under the "close ≤ open ⇒ next day" rule;
  - a range row maps 1:1.
- **Never null.** `[]` when the venue has no rows.

```json
{ "id": "859b3f37-…", "dayOfWeek": 6, "openTime": "00:00:00", "closeTime": "00:00:00", "closed": false, "ramadan": false }
```

**`mediaUrls`** (`List<String>`) is now **the visible gallery photos' URLs, in gallery order**. `venue_media` is no longer read. The list is never null and has no null element.

**Summary cards** (`coverUrl` on list, nearby, district, followed and intent cards):
- The chain is `venues.cover_url`, unchanged (image **or** video; 51 of the 56 live venues have a video cover that `VenuePosterCard` plays), then the **first visible gallery photo** by `(sort_order, id)`, then `null`.
- `VenueCoverResolver` does it in at most one query per page, and in none when every venue on the page has a cover.
- This replaced an arbitrary `venue_media` row and four N+1 paths.
- A hidden photo is never used.

---

## 5. Request bodies

Times, dates and enums are **Strings with `@Pattern`**, parsed in the service. A malformed `LocalTime` or enum in a typed field would fail inside Jackson and give a 400 **without** a `CODE:` prefix; as Strings, every bad value gets its stable code.

### Hours

```java
record HoursIntervalInput(String opens, String closes)            // "HH:mm", 00:00–23:59
record HoursDayInput(Integer dayOfWeek,                           // 0..6
                     String kind,                                 // CLOSED | OPEN_24H | HOURS
                     List<HoursIntervalInput> intervals)          // required; [] for CLOSED / OPEN_24H; ≤ 4
record WeeklyScheduleInput(List<HoursDayInput> days)              // exactly 7
record UpdateVenueHoursRequest(WeeklyScheduleInput regular,       // required
                               WeeklyScheduleInput ramadan,       // null/absent = KEEP the stored Ramadan week
                               Boolean removeRamadan)             // true = delete it; true + ramadan = 400
record UpdateBranchHoursRequest(String mode,                      // OWN | INHERIT
                                WeeklyScheduleInput regular,      // OWN: required; INHERIT: must be absent
                                WeeklyScheduleInput ramadan,      // OWN: same keep/replace rule; INHERIT: absent
                                Boolean removeRamadan)            // INHERIT: must not be true
```

Example `PUT /api/v1/business/venues/{venueId}/hours`. The regular week has a split Sunday, late nights, a closed Friday and a 24 h Saturday; the Ramadan week has night hours:
```json
{
  "regular": { "days": [
    { "dayOfWeek": 0, "kind": "HOURS",    "intervals": [ { "opens": "09:00", "closes": "13:00" }, { "opens": "16:00", "closes": "02:00" } ] },
    { "dayOfWeek": 1, "kind": "HOURS",    "intervals": [ { "opens": "09:00", "closes": "02:00" } ] },
    { "dayOfWeek": 2, "kind": "HOURS",    "intervals": [ { "opens": "09:00", "closes": "02:00" } ] },
    { "dayOfWeek": 3, "kind": "HOURS",    "intervals": [ { "opens": "09:00", "closes": "02:00" } ] },
    { "dayOfWeek": 4, "kind": "HOURS",    "intervals": [ { "opens": "09:00", "closes": "03:00" } ] },
    { "dayOfWeek": 5, "kind": "CLOSED",   "intervals": [] },
    { "dayOfWeek": 6, "kind": "OPEN_24H", "intervals": [] }
  ] },
  "ramadan": { "days": [
    { "dayOfWeek": 0, "kind": "HOURS", "intervals": [ { "opens": "20:00", "closes": "03:30" } ] },
    "… dayOfWeek 1..6, same shape …"
  ] }
}
```
- **Why it is valid.** Saturday's 24 h ends at Sun 00:00, before Sun 09:00, and Sunday 16:00–02:00 ends Mon 02:00, before Mon 09:00.
- **Regular-only saves.** A body with only `regular` keeps the stored Ramadan week. To remove the week, send `"removeRamadan": true`.

### Operating status

```java
record UpdateOperatingStatusRequest(String status,                // OPEN | TEMPORARILY_CLOSED | PERMANENTLY_CLOSED (required)
                                    String reopensOn)             // YYYY-MM-DD, TEMPORARILY_CLOSED only
record UpdateBranchOperatingStatusRequest(String mode,            // OWN | INHERIT
                                          String status,          // OWN: required; INHERIT: must be absent
                                          String reopensOn)       // INHERIT: must be absent
```
```json
{ "status": "TEMPORARILY_CLOSED", "reopensOn": "2026-10-12" }
{ "mode": "OWN", "status": "PERMANENTLY_CLOSED" }
{ "mode": "INHERIT" }
```
Every status PUT writes both columns, so an omitted `reopensOn` clears the stored one. `OPEN` and `PERMANENTLY_CLOSED` never carry a date.

### Gallery

```java
record AttachGalleryPhotoRequest(String key,              // from upload-url; ^venues/{venueId}/gallery/{uuid}.(jpg|png|webp)$
                                 Integer width,           // 1..20000
                                 Integer height,          // 1..20000 (and max/min ≤ 5)
                                 String placeholderHash,  // optional base64 ThumbHash, ^[A-Za-z0-9+/]{8,60}={0,2}$
                                 List<String> tags,       // 0..3 known codes; duplicates dropped; null = none
                                 UUID venueLocationId)    // optional active branch of THIS venue; null or NIL = venue-wide
record UpdateGalleryPhotoRequest(List<String> tags,       // null = unchanged; [] = clear; else REPLACES the list
                                 UUID venueLocationId)    // null = unchanged; NIL UUID = clear
record ReorderGalleryRequest(List<UUID> photoIds)         // 1..24; must equal the venue's current set
record HideGalleryPhotoRequest(String reason)             // admin; required, ≤ 500
```
The NIL UUID `00000000-0000-0000-0000-000000000000` is the same "clear" sentinel as `UpdateEventRequest` / `AdminEventServiceImpl.NIL_UUID`.

### Platform calendar

```java
record PlatformCalendarPeriodRequest(String kind,         // "RAMADAN"
                                     String startsOn,     // YYYY-MM-DD, first fasting day
                                     String endsOn,       // YYYY-MM-DD, last fasting day (the day before Eid al-Fitr)
                                     String labelAr,      // ≤ 100
                                     String labelEn,      // ≤ 100
                                     String note)         // ≤ 500, which authority's announcement
```
```json
{ "kind": "RAMADAN", "startsOn": "2027-02-08", "endsOn": "2027-03-09",
  "labelAr": "رمضان ١٤٤٨", "labelEn": "Ramadan 1448",
  "note": "Sunni Endowment announcement, 2027-02-07 19:40" }
```
Labels and the note are trimmed, and blank becomes `null`.

---

## 6. Rules

### 6.1 Schedule semantics

- **Zone.** Every computation uses Asia/Baghdad (a fixed UTC+3, no DST). The time is always `clock.instant()` from the injected `Clock` bean, converted with `ZoneId.of("Asia/Baghdad")` explicitly. The JVM default zone (UTC on production) is never used.
- **A day** is exactly one of:
  - `CLOSED`, with no intervals;
  - `OPEN_24H`, which covers `[D 00:00, D+1 00:00)`;
  - `HOURS`, with 1–4 intervals.
- **A range belongs to the operating day it opens on.**
  - If `closes > opens`, it covers `[D opens, D closes)`.
  - Otherwise it covers `[D opens, D+1 closes)`: it is **overnight**. `"00:00"` as the close means "until midnight".
  - `"24:00"` is rejected.
  - The start is inclusive and the end exclusive.
- **Merge at read time.** Ranges that overlap **or touch** are unioned into one span, so "closes at" is always the real closing instant. For example, Mon 18:00–00:00 followed by a Tue `OPEN_24H` is one span that closes Wed 00:00.
- **The operating-day rule.** The season (Regular/Ramadan) and the temporary-closure suppression are chosen per **operating day**, never per clock instant. The part of a night after midnight follows the day the night began on. For example, a Thu 18:00–03:00 range keeps the venue OPEN at Fri 01:30 even though Friday is `CLOSED`. That is the case `lastNight` exists for.

### 6.2 Write-side validation (`WeeklyScheduleValidator`)

The same rules apply on the business and the admin paths, on `regular` and `ramadan` separately. The whole request is validated **before** the first write, so a rejected request changes nothing.

| Rule | Code |
|---|---|
| exactly 7 days whose `dayOfWeek` set is exactly {0..6} | `HOURS_DAYS_INCOMPLETE` |
| `kind` ∈ {`CLOSED`, `OPEN_24H`, `HOURS`} | `HOURS_INVALID_KIND` |
| `CLOSED`/`OPEN_24H` carry no interval; `HOURS` carries ≥ 1; `intervals` present | `HOURS_KIND_MISMATCH` |
| ≤ 4 intervals a day | `HOURS_TOO_MANY_INTERVALS` |
| times match `^([01]\d\|2[0-3]):[0-5]\d$` (`"24:00"`, `"9:00"`, `"09:00:00"` rejected) | `HOURS_INVALID_TIME` |
| `opens ≠ closes` (use `OPEN_24H`) | `HOURS_EMPTY_INTERVAL` |
| duration ≥ 15 min (an overnight range counts across midnight) | `HOURS_INTERVAL_TOO_SHORT` |
| **no overlap anywhere in the cyclic week.** Every `OPEN_24H` day and every interval become minute-of-week segments, split at the Saturday→Sunday wrap. Touching is allowed. An overnight tail running into a next-day `OPEN_24H` is an overlap: write "…–00:00" instead, which reads as the same merged span | `HOURS_OVERLAP` (the message names both day/time pairs) |
| `regular` present on the venue PUT and on a branch `OWN` PUT | `HOURS_REGULAR_REQUIRED` |
| not both `ramadan` and `removeRamadan: true` | `HOURS_RAMADAN_CONFLICT` |
| branch `mode` ∈ {`OWN`, `INHERIT`} | `HOURS_INVALID_MODE` |
| branch `INHERIT` carries no schedule and no `removeRamadan: true` | `HOURS_INHERIT_WITH_SCHEDULE` |
| `status` present (venue PUT; branch `OWN`) | `STATUS_REQUIRED` |
| `status` ∈ {`OPEN`, `TEMPORARILY_CLOSED`, `PERMANENTLY_CLOSED`} | `STATUS_INVALID` |
| branch status `mode` ∈ {`OWN`, `INHERIT`} | `STATUS_INVALID_MODE` |
| branch status `INHERIT` carries no `status` and no `reopensOn` | `STATUS_INHERIT_WITH_VALUE` |
| `reopensOn` only with `TEMPORARILY_CLOSED` | `STATUS_REOPEN_DATE_NOT_ALLOWED` |
| `reopensOn` is a real `YYYY-MM-DD` date with `today < reopensOn ≤ today + 365` (Baghdad `today`) | `STATUS_REOPEN_DATE_INVALID` |

**Overlaps across seasons are never checked.** A regular Sunday running to 02:00 next to a Ramadan Monday opening at 01:00 is legal; the two are unioned at read time.

### 6.3 Inheritance (per scope)

```
hoursOwner   = branch != null && branch.hoursOverride ? BRANCH(branch) : VENUE
regular      = rows of hoursOwner, !ramadan        → null = not set
ramadan      = rows of hoursOwner,  ramadan        → null = none
statusOwner  = branch != null && branch.operatingStatus != null ? branch : venue
hoursSource  = regular == null ? NONE : (hoursOwner == VENUE ? VENUE : BRANCH)
statusSource = statusOwner == branch ? BRANCH : VENUE
```
- **Overrides are pure, in both directions.**
  - A branch with its own `OPEN` status is evaluated from its hours even when the venue is `PERMANENTLY_CLOSED`.
  - A `TEMPORARILY_CLOSED` branch closes only that branch.
- **An overriding branch owns both weeks.** It never falls back to the venue's Ramadan week. Without a Ramadan week of its own, it runs its regular week during Ramadan.
- **Override is not inherit.** `hours_override = true` with seven `CLOSED` days means closed all week.
- **Inactive branches are ignored.** Soft-deleted branches are never evaluated, whatever rows they keep.

### 6.4 Status precedence and temporary closure

`PERMANENTLY_CLOSED` > `TEMPORARILY_CLOSED` before its reopen date > `UNKNOWN` (no regular week) > the hours.

- **`TEMPORARILY_CLOSED` without `reopensOn`**: closed, with no `opensAt`.
- **`TEMPORARILY_CLOSED` with `reopensOn = R`**: operating days before R never open. That **includes the after-midnight tail of the night of R−1**. `opensAt` is the first opening on or after R 00:00, within 7 days of R.
- **It reopens automatically.** There is no job and the column is never reset. From day R on, the read path simply evaluates the hours again. The editor then shows `statusExpired: true`.
- **Venue-level events.** A venue-level status change publishes `VENUE_UPDATED` (§8). Branch status changes publish nothing.

### 6.5 Ramadan window and the two edge nights

Let S be the first fasting day (`starts_on`) and E the last fasting day (`ends_on`, the day before Eid al-Fitr). The window is **inclusive** Asia/Baghdad dates.

- **Days S..E** use the scope's Ramadan week, if it has one. That is the whole operating day, including its after-midnight tail.
- **The first Ramadan night, the eve S−1.** S−1 is not a fasting day, so it keeps its **regular** rule. It also **adds** the Ramadan week's ranges for that weekday that open **at or after 15:00**. The two are unioned, so the first taraweeh and suhoor night follows the Ramadan hours while the eve's daytime stays regular.
  - Only `HOURS` ranges are added; an `OPEN_24H` Ramadan day is never added on the eve.
  - Why 15:00: iftar in Baghdad falls between about 17:00 and 19:30 in every season.
  - The added ranges are reported as `today.ramadanEveIntervals`.
- **Eid night, the evening of E into the morning of E+1.** E is a fasting day, so its whole rule, **including its night**, is the Ramadan rule. Regular hours start on E+1 (Eid day 1).
- **Without a Ramadan week or a window.** A scope with no Ramadan week uses its regular week during the window and on the eve. No window set means regular everywhere.
- **Do not start the window a day early.** That would put the eve's daytime on the Ramadan week and still leave Eid night unchanged.
- **Edits apply on the next request, on every pod.** The windows are read per request and never cached.

Worked example: regular every day 10:00–23:00 except Sunday 18:00–02:00; Ramadan every day 20:00–03:00; window **Mon 2027-02-08 … Tue 2027-03-09**. These are `OpeningHoursResolverTest` cases H14, H15, H4, H5, H16, H7 and H8.

| Now (Baghdad) | Which night | state | closes / opens | `season` | `spanSeason` |
|---|---|---|---|---|---|
| Sun 02-07 12:00 | eve, daytime | CLOSED | opens Sun 18:00 (regular) | REGULAR | — |
| Sun 02-07 23:00 | first Ramadan night | OPEN | closes Mon 03:00 (18:00–02:00 ∪ 20:00–03:00) | REGULAR | RAMADAN |
| Mon 02-08 01:00 | day 1, last night's tail | OPEN | closes 03:00 | RAMADAN | RAMADAN (span Sun) |
| Mon 02-08 12:00 | fasting day | CLOSED | opens 20:00 | RAMADAN | — |
| Tue 03-09 21:00 | Eid night | OPEN | closes Wed 03:00 | RAMADAN | RAMADAN |
| Wed 03-10 01:00 | Eid day 1, last night's tail | OPEN | closes 03:00 | REGULAR | RAMADAN (span Tue) |
| Wed 03-10 05:00 | Eid day 1 | CLOSED | opens 10:00 (regular) | REGULAR | — |

The app shows the «أوقات رمضان مفعّلة» badge from `spanSeason` while OPEN, and from `today.season` otherwise.

### 6.6 Computed fields

- **Horizon.** The resolver looks at operating days `[today−1, today+7]`: `today−1` for last night's tail, and +7 so a "Fridays only" venue still gets its next opening. An opening further out is reported as `opensAt: null`, and the UI shows only "Closed now".
- **Soon.** `closingSoon` and `openingSoon` use a 60-minute threshold, inclusive: exactly 60 min away counts.
- **`alwaysOpen`.** The current span reaches past the horizon end (`today+8 00:00`). An every-day `OPEN_24H` week is "Open 24 hours"; a 24 h run that ends before a closed day is not.
- **`nextChangeAt`.** `closesAt` when OPEN; `opensAt` when CLOSED or TEMPORARILY_CLOSED with a date; otherwise `null`.
- **`lastNight`.** Present only when the state is `OPEN` and `spanOperatingDate` is yesterday.
- **Public `ramadanWindow`.** The window containing today, else the next one starting within 30 days. The editor's `ramadanWindow` has no limit.

### 6.7 Gallery rules

- **Cap.** 24 photos per venue, **hidden ones included**, enforced at attach under the venue row lock.
- **Tags.** A photo has 0–3 tags from the fixed vocabulary below (`VenueGalleryTags.ALL`, mirrored by the V106 CHECK `chk_vgp_tags`: change both together). Duplicates are dropped, and an unknown code → 400 `GALLERY_TAG_UNKNOWN`. Food and menu are deliberately excluded: this is a decor-and-setting gallery. Clients render only these 8 codes and drop any other, so a code added on the server later never shows up as a raw locale key.

  | code | ar | en | amenity link |
  |---|---|---|---|
  | `inside` | من الداخل | Inside | – |
  | `outside` | الجلسات الخارجية | Outdoor seating | `hasOutdoor` |
  | `seating` | الجلسات | Seating | – |
  | `ambience` | الأجواء | Ambience | – |
  | `facade` | الواجهة والمدخل | Entrance & facade | – |
  | `view` | الإطلالة | View | – |
  | `family_section` | قسم العوائل | Family section | `family` |
  | `private_room` | الغرف الخاصة | Private rooms | `hasPrivateRoom` |

- **Upload URL** (`GET …/upload-url`). The checks run in this order:
  1. `contentType` ∈ {`image/jpeg`, `image/png`, `image/webp`}, else `GALLERY_INVALID_CONTENT_TYPE`.
  2. `1 ≤ contentLength ≤ 10485760`, else `GALLERY_INVALID_LENGTH`.
  3. An advisory cap check: 409 `GALLERY_LIMIT_REACHED` at 24. Attach re-checks it and is authoritative.
  4. Two rate limits, both 400 `GALLERY_RATE_LIMITED`: first **30 per hour per person at this venue**, so one staff member cannot use up the owner's budget; then **120 per hour per venue**, which caps orphan uploads. A request the venue cap rejects still counts toward that person's 30.

  After the checks:
  - **Key.** `venues/{venueId}/gallery/{random-uuid}.{jpg|png|webp}`. Every upload gets a fresh key, so keys are immutable and cacheable forever.
  - **Presign.** The URL signs **both `Content-Type` and `Content-Length`**, so S3 itself rejects a body of any other type or size (S3 403). The TTL is 300 s.
- **Attach** (`POST …/gallery`). The steps run in this order:
  1. **Key.** It must match `^venues/{venueId}/gallery/[0-9a-f-]{36}\.(jpg|png|webp)$` for **this** venue, else `GALLERY_KEY_INVALID`.
  2. **Dimensions.** Each side 1..20000 and the aspect ratio at most 5:1, else `GALLERY_DIMENSIONS_INVALID`.
  3. **Tags**, as above.
  4. **S3 `HeadObject`.** It re-checks what actually landed in S3, and the client's type and size are never trusted:
     - no object → `GALLERY_OBJECT_MISSING`;
     - a stored type that is not allowed or doesn't match the key's extension → `GALLERY_UNSUPPORTED_TYPE`;
     - more than 10 MB → `GALLERY_TOO_LARGE`.

     HeadObject runs **before** the lock, so no row lock is held across the S3 round trip. A 404 **or 403** from S3 counts as "missing": without `s3:ListBucket`, S3 answers a missing key with 403. The 403 case logs WARN `s3.head.forbidden key=…`.
  5. **Branch.** `venueLocationId` must be an active branch of this venue, else 404 `BRANCH_NOT_FOUND`. NIL or null means venue-wide.
  6. **Lock** the venue row (`SELECT … FOR UPDATE`).
  7. **Already attached?** `findByS3Key(key)` returns the existing photo with **200**. This check runs **after** the lock, so a concurrent retry of the same key sees the first attach once it commits.
  8. **Cap.** Count ≥ 24 → 409 `GALLERY_LIMIT_REACHED`.
  9. **Insert** at the end (`sortOrder = max + 1`) with `saveAndFlush`. If a concurrent attach still wins the unique key, the answer is 409 `GALLERY_DUPLICATE_KEY`, which the app treats as success and then reloads the list. Any other constraint failure is rethrown, giving the generic 409 "Data conflict…".
- **PATCH.** `tags` replaces the list (`[]` clears it). `venueLocationId` must be an active branch of this venue; the NIL UUID clears the attribution. A hidden photo can be edited.
- **Reorder.** The `photoIds` set must **equal** the venue's current set, hidden photos included, with no duplicates. Otherwise the answer is 409 `GALLERY_ORDER_MISMATCH` (refresh and retry). Then `sortOrder = index`. `sort_order` has no unique constraint, and ties sort by `id`.
- **Delete** (business or admin). The row is hard-deleted now; the **S3 origin object** is deleted **after commit**, best-effort (`S3Service.delete` logs WARN `Failed to delete S3 object …` and swallows the error). Gaps in `sort_order` are fine.
  - **CloudFront edge copies keep being served until their TTL expires**, and devices keep what they already cached (keys are immutable).
  - So DELETE means "removed from dlliny and from storage", not an instant global purge. A legal takedown that must vanish at once needs a manual CloudFront invalidation by ops.
  - The owner or manager can also hard-delete a photo an admin had hidden.
- **Hide** (admin, `reason` required). The photo leaves every API response at once: the public list, `gallery`, `mediaUrls` and the card-cover fallback. **Its CDN URL stays reachable until it is deleted.**
  - Hiding an already-hidden photo updates the reason and keeps the original `hiddenAt`.
  - A hidden photo still counts toward the 24 and still appears in the manage list with its reason.
- **Unhide** clears all four hidden columns. Unhiding a visible photo is a no-op, with no audit row.
- **Every gallery write takes the venue row lock first**: attach, patch, reorder, delete, hide and unhide. The writers therefore serialise. For example, a reorder racing a delete answers `GALLERY_ORDER_MISMATCH` instead of a 500.

### 6.8 Platform calendar rules

- **Validation.**
  - A bad or impossible date (`2027-02-30`) → 400 `CALENDAR_INVALID_DATE`.
  - `endsOn < startsOn`, or a window longer than 35 days → 400 `CALENDAR_RANGE_INVALID`.
- **Overlap.** Another RAMADAN window sharing at least one day → **409** `CALENDAR_OVERLAP`. Both ends are inclusive; back-to-back windows don't overlap, and a PUT excludes the window itself.
- **Unknown id** → 404 `CALENDAR_PERIOD_NOT_FOUND`.
- **Far future.** A window starting more than 2 years after today is accepted but WARN-logged as `platform_calendar.far_future` (a likely year typo such as 2072 for 2027).
- **An unchanged PUT** writes nothing and adds no audit row.
- **`reminder.show`** is computed against the Baghdad today. It is true when:
  - no RAMADAN window is active or upcoming, **and**
  - either some entry T of `APPROX_RAMADAN_STARTS = [2027-02-08, 2028-01-28, 2029-01-16]` has `T−45 ≤ today ≤ T+30` with no window starting within `T ± 20` days, **or** the last window ended more than 300 days ago.

  The +30 tail keeps the banner up when Ramadan has begun and nobody has entered it.
- **`reminder.approxNextStart`.** The table entry that triggered the rule, else the first entry on or after today. It is `null` once the table runs out, and the 300-day rule keeps the banner working then. **Extend the table once a year** (`AdminPlatformCalendarServiceImpl.APPROX_RAMADAN_STARTS`).

---

## 7. Error codes

Every feature error has the shape `"error": "CODE: human detail"`. Clients map the text before the first `:` to localized copy. A bean-validation 400 joins several messages with `", "`; the **first** message's code wins.

| HTTP | Codes |
|---|---|
| 400 | **Hours:** `HOURS_DAYS_INCOMPLETE`, `HOURS_INVALID_KIND`, `HOURS_KIND_MISMATCH`, `HOURS_TOO_MANY_INTERVALS`, `HOURS_INVALID_TIME`, `HOURS_EMPTY_INTERVAL`, `HOURS_INTERVAL_TOO_SHORT`, `HOURS_OVERLAP`, `HOURS_REGULAR_REQUIRED`, `HOURS_INVALID_MODE`, `HOURS_INHERIT_WITH_SCHEDULE`, `HOURS_RAMADAN_CONFLICT` |
| 400 | **Status:** `STATUS_REQUIRED`, `STATUS_INVALID`, `STATUS_INVALID_MODE`, `STATUS_INHERIT_WITH_VALUE`, `STATUS_REOPEN_DATE_NOT_ALLOWED`, `STATUS_REOPEN_DATE_INVALID` |
| 400 | **Gallery:** `GALLERY_INVALID_CONTENT_TYPE`, `GALLERY_INVALID_LENGTH`, `GALLERY_KEY_INVALID`, `GALLERY_OBJECT_MISSING`, `GALLERY_UNSUPPORTED_TYPE`, `GALLERY_TOO_LARGE`, `GALLERY_DIMENSIONS_INVALID`, `GALLERY_PLACEHOLDER_INVALID`, `GALLERY_TOO_MANY_TAGS`, `GALLERY_TAG_UNKNOWN`, `GALLERY_RATE_LIMITED` |
| 400 | **Calendar:** `CALENDAR_INVALID_KIND`, `CALENDAR_INVALID_DATE`, `CALENDAR_RANGE_INVALID` |
| 403 | `Access denied`, with no code: either the JWT authority gate or the per-venue guard (§3.7) |
| 404 | `VENUE_NOT_FOUND` (business and admin paths), `Venue not found` without a code (public `/hours`, `/gallery` and the venue detail), `BRANCH_NOT_FOUND`, `PHOTO_NOT_FOUND`, `CALENDAR_PERIOD_NOT_FOUND` |
| 409 | `GALLERY_LIMIT_REACHED`, `GALLERY_ORDER_MISMATCH`, `GALLERY_DUPLICATE_KEY` (the app treats it as success), `CALENDAR_OVERLAP` |
| 410 | `GONE: use /api/v1/business/venues/{venueId}/gallery` (legacy `/media` routes) |

**400s without a code.** A few 400s carry no `CODE:` prefix, and clients show their generic error for them:
- a non-numeric `dayOfWeek` or `width`, or a malformed UUID in a JSON body → `Invalid value for '<field>'`;
- a malformed `?locationId=` → `Invalid value for 'locationId'`;
- the admin `hide` reason and the calendar label/note size limits, which use plain bean-validation messages;
- an empty `photoIds` on reorder.

The UI never sends these shapes.

---

## 8. Behind the scenes

### Write path (hours and status: `VenueHoursServiceImpl`)

Every write runs these steps, in this order:
1. **Who.** A business actor passes `VenuePermissionGuard.require(userId, venueId, "venue:hours:manage")`. An admin actor has already passed `admin:venues:manage`. `Actor.user(id)` / `Actor.admin(id)` let both controllers share one service.
2. **Lock.** `venueRepository.findByIdForUpdate(venueId)` serialises every hours, status and gallery write of one venue.
3. **Validate** the whole request (§6.2).
4. **Write.** Bulk JPQL deletes per scope and season, then `saveAll` of the new rows. The status and flag columns are written only through the JPQL `update*` methods:
   - `VenueRepository.updateOperatingStatus` and `updateHoursUpdatedAt`;
   - `VenueLocationRepository.updateHoursOverride` and `updateOperatingStatus`.

   Two reasons:
   - **Deletes run first.** An entity-level delete would lose to Hibernate's inserts-before-deletes flush order and hit `ux_venue_hours_slot`.
   - **No stale full-row saves.** `Venue` has no `@Version`, and a stale full-row `save()` elsewhere would silently revert the status.

   The last update of every operation flushes and clears the persistence context.
5. **Read back** the whole editor model from fresh rows.
6. **Audit** (admin only). The details are the scope's `{before, after}`, plus `locationId` and `mode` for branch writes. For status writes, `before` and `after` are `{operatingStatus, reopensOn}`.

**Stale-write protection elsewhere.** V106 also moved the long-lived `Venue` writers to single-column JPQL updates, so they can no longer write back a stale status:
- **Video thumbnails.** The sweeper, the upload listener and the admin `regenerate/VENUE_COVER` use `updateCoverThumbnailUrl`, guarded on `cover_url` being unchanged. The admin call answers 409 if the cover changed meanwhile (`VIDEO_THUMBNAILS_OPS.md`).
- **Follow / unfollow** use an atomic `incrementFollowerCount` / `decrementFollowerCount`.

`@DynamicUpdate` on `Venue` and `VenueLocation` limits the remaining managed writers to the columns they changed.

**Known risk: lock order.** Branch hours and status writes lock `venues`, then update `venue_locations`. `VenueLocationServiceImpl.updateLocation` on the primary branch takes the opposite order, with no venue lock. An owner editing the primary branch's address while someone saves that branch's hours can therefore deadlock. Postgres aborts one of the two after `deadlock_timeout` (a generic error; a retry succeeds). This is rare and accepted for v1. The follow-up belongs to the branches code: make `updateLocation` / `deleteLocation` lock the venue row first.

### No caching, anywhere

- **No `@Cacheable`.** Caffeine is per pod, so an eviction on one pod would leave the others stale after a moon-sighting edit, and the Ramadan window is one indexed query on a table with a few rows per year.
- **No `@PublicCacheControl`** on `/venues/{id}`, `/venues/handle/{h}`, `/venues/{id}/hours` or `/venues/{id}/gallery`.
- **Images.** Gallery image URLs are immutable, so the CDN and `cached_network_image` may keep them indefinitely.
- **Future list surfaces** (cards, pins, trending) must compute the status **after** any Redis or Elasticsearch read, never inside one.

### Events

| Write | Event |
|---|---|
| Venue-level operating status **changed** (business or admin) | `VENUE_UPDATED` (`hangout.venue.updated`, via the outbox) → `SearchIndexConsumer` re-indexes. Harmless, and it keeps search ready to act on "permanently closed" later |
| Hours, branch hours, branch status, gallery, calendar | none: no projection stores any of them |

### Admin audit (`AdminAuditWriter`, hangout-infrastructure)

| Action | `entityType` | `entityId` | `details` |
|---|---|---|---|
| `VENUE_HOURS_UPDATE`, `VENUE_HOURS_CLEAR` | `VENUE` | venue | `{before, after}` (venue scope) |
| `VENUE_BRANCH_HOURS_UPDATE` | `VENUE` | venue | `{before, after, locationId, mode}` |
| `VENUE_STATUS_UPDATE` | `VENUE` | venue | `{before, after}` as `{operatingStatus, reopensOn}` |
| `VENUE_BRANCH_STATUS_UPDATE` | `VENUE` | venue | `{before, after, locationId, mode}` |
| `VENUE_PHOTO_HIDE` | `VENUE_GALLERY_PHOTO` | photo | `{venueId, reason, s3Key, url}` |
| `VENUE_PHOTO_UNHIDE` | `VENUE_GALLERY_PHOTO` | photo | `{venueId, previousReason}` |
| `VENUE_PHOTO_DELETE` | `VENUE_GALLERY_PHOTO` | photo | `{venueId, s3Key, url}` |
| `PLATFORM_CALENDAR_CREATE`, `_UPDATE`, `_DELETE` | `PLATFORM_CALENDAR_PERIOD` | period | `{changes: {field: {from, to}}}` |

- **When the writer skips.** It skips an unknown admin with a WARN and stores unserializable details as `{}`.
- **When it is not non-fatal.** A database failure of the audit INSERT itself marks the caller's transaction rollback-only, so the action rolls back with it: a 500. The writers flush their own change **before** auditing, so a constraint failure surfaces as the action's own error.
- **Business actions are not audited.** Only admin writes produce these rows.

### Query budget of `GET /venues/{id}`

Three queries were added:
- `findAllForVenue`: the default **and** every branch's rows, grouped in memory;
- one uncached Ramadan-window query;
- one visible-gallery query, which feeds `gallery.photos`, `gallery.tagCounts` and `mediaUrls` at once.

Branches were already loaded. The resolver runs in memory per scope, at most 9 operating days × 8 ranges.

---

## 9. Migration + deployment checklist

### 9.1 Preflight (read-only, production DB)

```sql
SELECT version, success FROM flyway_schema_history ORDER BY installed_rank DESC LIMIT 3;  -- is V105 applied (or shipping with this image)?
SHOW server_version;                                                                        -- expect 16
SELECT count(*) AS rows, count(DISTINCT venue_id) AS venues,
       count(*) FILTER (WHERE is_closed IS NULL OR is_ramadan IS NULL)     AS null_flags,
       count(*) FILTER (WHERE open_time = close_time)                      AS equal_times,
       count(*) FILTER (WHERE open_time = '24:00' OR close_time = '24:00') AS t24
FROM venue_hours;                                               -- expected: all 0 (no writer ever existed)
SELECT media_type, is_active, count(*) FROM venue_media GROUP BY 1, 2;
SELECT count(DISTINCT m.venue_id) FROM venue_media m JOIN venues v ON v.id = m.venue_id
 WHERE m.is_active AND v.cover_url IS NULL;                     -- cards losing the legacy fallback (active venues: expected 0)
SELECT p.name, r.name FROM permissions p JOIN role_permissions rp ON rp.permission_id = p.id
  JOIN roles r ON r.id = rp.role_id
 WHERE p.name IN ('venue:media:upload', 'venue:media:delete') ORDER BY 1, 2;  -- staff on upload only
```
- **If `venue_hours` has rows**, V106 normalises them (§2). They were never displayed, so owners re-check them in the editor.
- **If the fallback count is > 0** (only inactive venues are expected), those venues show their logo or a placeholder on cards until the owner sets a cover or uploads a photo.

### 9.2 REQUIRED: real-Postgres V106 check (staging or a prod clone, before production)

V106 has **not** run against a real database yet. Do all four steps on `postgis/postgis:16-3.4`, staging or a prod clone:

1. **Migrate and validate.** Run Flyway V1…V106 (V105 included), then boot the gateway once with `ddl-auto: validate` (JDK 21). This proves that the entity types match the DDL:
   - `@Enumerated(STRING)` ↔ `VARCHAR(20)`;
   - `String[]` ↔ `varchar(24)[]`;
   - `LocalDate` ↔ `DATE`, `Instant` ↔ `TIMESTAMPTZ`, `Short` ↔ `SMALLINT`;
   - the NOT NULL flags.
2. **Constraints.** In one transaction that you roll back, each of these statements must **fail**:
   - a `venue_hours` row with `close_time = '24:00'`;
   - a row with `open_time = close_time`;
   - `is_closed` together with times;
   - a CLOSED marker plus a `00:00` range in the same slot;
   - a branch row whose `venue_id` ≠ the branch's venue (composite FK);
   - a venue `reopens_on` with `OPEN`;
   - a gallery tag `'food'`, or 4 tags;
   - `is_hidden = false` with a `hidden_reason`;
   - `byte_size = 0`;
   - a 36-day calendar window.

   And this one must **pass**: `DELETE FROM venue_locations WHERE id = :branch` deletes that branch's `venue_hours` rows and NULLs its photos' `venue_location_id`.
3. **Normalisation.** Seed synthetic legacy `venue_hours` rows (NULL flags, equal times, `24:00`, duplicates). Re-run only V106's normalisation block, then check that the shape CHECK and `ux_venue_hours_slot` can be added.
4. **Lock timeout.** In one session, run `BEGIN; SELECT * FROM venues FOR SHARE;` and keep it open. Run the migration from a second session. It must fail within about 5 s with `canceling statement due to lock timeout`, leaving no V106 row in `flyway_schema_history` and no new column. Close the first session and re-run: it succeeds.

### 9.3 S3 IAM preflight

Read the role policy of the backend's AWS credentials for bucket `app.aws.s3.bucket`.

| Permission | Needed for | If missing |
|---|---|---|
| `s3:PutObject` on `venues/*` | the presigned upload (already used by every upload flow) | uploads fail with S3 403 |
| `s3:GetObject` on `venues/*` | `HeadObject` at attach | **every attach answers 400 `GALLERY_OBJECT_MISSING`**, plus `s3.head.forbidden` WARN lines |
| `s3:ListBucket` on the bucket | lets S3 answer 404 for a missing key | still works (a 403 is treated as missing), but a genuinely missing key and an IAM fault look alike: grant it |
| `s3:DeleteObject` on `venues/*` | the after-commit delete (never exercised in production before) | photo rows are deleted but the files stay (WARN `Failed to delete S3 object …`) |

### 9.4 Deploy order

1. **V105 ships first**, or in the same image as V106.
2. **The staging check in §9.2 is green.**
3. **Backend on `production`, the whole feature in one release** (Coolify Dockerfile, JDK 21), off-peak. A partial `production` is inconsistent: the detail's `mediaUrls` would read a gallery that has no write API yet.
   - If a new pod fails at startup with `canceling statement due to lock timeout`, nothing was applied. **Redeploy.** If it happens twice, look for long transactions on `venues` and redeploy once they end:
     ```sql
     SELECT pid, now() - xact_start, query FROM pg_stat_activity WHERE state <> 'idle' ORDER BY 2 DESC;
     ```
   - During the rollout, old pods keep working: the new columns are unmapped there, and DB defaults fill them on inserts.
   - Old app builds are unaffected. `hours` and `mediaUrls` keep their shapes, and the new keys are ignored.
   - **The token bump makes owners', managers' and business owners/managers' access tokens stale once** (401 `token_stale` → silent refresh). `JwtAuthFilter` caches `token_version` for up to 60 s per pod, which the restart resets anyway.
4. **Smoke test** (§9.5), including the current store build of the app.
5. **Dashboard release** the same day.
   - **SUPERADMINs sign out and back in** (admin JWTs freeze permissions; without a fresh sign-in, the page appears only after the next refresh, within 8 h).
   - Enter the tentative **Ramadan 1448** window and correct it on moon-sighting night.
6. **App release** (About block, map and branch status, editors, gallery manager). New builds tolerate an older backend: the new fields are nullable.

### 9.5 After deploy

**Smoke** (scripted curl against staging, then production):
- **Owner, hours.**
  - `PUT /hours` with regular + Ramadan → 200.
  - `PUT /hours` with `regular` only → 200, and the Ramadan week is still there. Then send `removeRamadan: true` → the week is gone.
  - `GET /venues/{id}`: `hours` keeps its shape, `openingHours` is present, and `GET /venues/{id}/hours` equals `openingHours`.
- **Owner, error codes.**
  - `PUT locations/{L}/operating-status {"mode":"OWN"}` → 400 `STATUS_REQUIRED`.
  - `GET gallery/upload-url` with no params → 400 `GALLERY_INVALID_CONTENT_TYPE`.
- **A user who is staff at V and owner of W.**
  - `PUT /business/venues/{V}/hours` → **403**.
  - upload-url → S3 PUT → attach on V → 201.
  - `DELETE` a V photo → **403**.
  - `PATCH` a W photo → 200.
- **Gallery edge cases.**
  - The 25th attach → 409 `GALLERY_LIMIT_REACHED`.
  - An S3 PUT whose length ≠ `contentLength` → S3 403.
  - Two concurrent attaches of one key → one 201 and one 200 with the same id.
  - A never-uploaded key → 400 `GALLERY_OBJECT_MISSING`.
- **Admin moderation.**
  - Hide a photo → it disappears from `/gallery`, `mediaUrls` and the card cover.
  - Delete it → the S3 object is gone.
- **Legacy.** `/media/*` → 410, plus a WARN line.
- **Platform calendar**, as a SUPERADMIN after signing in again:
  - create, edit and delete a window; a second, overlapping one → 409;
  - an ADMIN → 403;
  - an edit shows on the next `GET /venues/{id}/hours`.
- **Stale-write regression.**
  1. Set V (with a video cover) to TEMPORARILY_CLOSED.
  2. Call `POST /api/v1/admin/media/thumbnails/regenerate/VENUE_COVER/{V}`, then follow and unfollow V.
  3. V is still TEMPORARILY_CLOSED, `coverThumbnailUrl` is refreshed, and `followerCount` went +1 and −1.

**Monitoring:**
- **4xx rate per new endpoint**, by `CODE:` prefix.
- **WARN lines:**

  | Log line | Watch for |
  |---|---|
  | `Legacy venue media endpoint called` | target: 0. After 30 days with none, the cleanup migration drops the endpoints, `VenueMedia` and `venue_media` |
  | `s3.head.forbidden` | more than a few a day means IAM (§9.3) |
  | `Failed to delete S3 object` | IAM `s3:DeleteObject` |
  | `platform_calendar.far_future` | a year typo in a Ramadan window |
  | `Gallery attach hit an unexpected constraint` | a bug, not a user mistake |

- **ERROR:** S3 `headObject` failures other than 404/403 (they are rethrown as 500s).
- **Latency:** `GET /api/v1/venues/{id}` p95 before and after. The budget is +5 ms for the three small indexed queries.
- **Product numbers.** `/platform-calendar/status` shows the venues with hours and with Ramadan hours; watch the latter from 3 weeks before Ramadan.

### 9.6 Rollback

V106 is additive for everything the old code reads:
- The previous image still validates: the new columns are unmapped, and it doesn't know the new tables.
- The one behavioural difference is that the old `findByVenueId` would also return branch rows in `hours`, which old clients don't render.
- The token bump is harmless.

No down-migration is needed.

---

## 10. Client integration

### Flutter (`hangout_app`)

**Response DTOs** (json_serializable, `lib/domain/dto/response/`). Every new `VenueResponse` field is **nullable**, so a new build against an older backend hides the sections instead of failing. Enums use `unknownEnumValue`, so a value added on the server later never breaks parsing.
- `venue_opening_hours_response.dart`:
  - enums `OpenState`, `HoursSource`, `HoursDayKind`, `HoursSeason`;
  - `VenueOpeningHoursDto` (with `branch(locationId)`), `ScopeHoursDto`, `OpenStatusDto`, `HoursMomentDto`, `WeeklyScheduleDto`, `DayScheduleDto`, `TodayHoursDto`, `HoursIntervalDto`, `RamadanWindowDto`.
- `venue_gallery_response.dart`: `VenueGalleryDto`, and `GalleryPhotoDto`, which also carries the business-only `hidden`, `hiddenReason`, `hiddenAt`, `contentType`, `byteSize` and `uploadedByUserId`.
- `business_venue_hours_response.dart`: `BusinessVenueHoursResponse`, `EditableScopeHoursDto`.
- `business_gallery_response.dart`: `BusinessGalleryResponse`, `GalleryUploadUrlResponse`.
- `venue_response.dart`: `VenueResponse` gains `VenueOpeningHoursDto? openingHours` and `VenueGalleryDto? gallery`. `VenueHoursDto`, `hours` and `mediaUrls` are unchanged.

**Request DTOs** (`lib/domain/dto/request/`, `includeIfNull: false`):
- `venue_hours_requests.dart`: `UpdateVenueHoursRequest`, `UpdateBranchHoursRequest`, `WeeklyScheduleInput`, `HoursDayInput`, `HoursIntervalInput`, `UpdateOperatingStatusRequest`, `UpdateBranchOperatingStatusRequest`. `includeIfNull: false` omits a null `ramadan`, which the server reads as **keep**.
- `gallery_requests.dart`: `AttachGalleryPhotoRequest`, `UpdateGalleryPhotoRequest`, `ReorderGalleryRequest`, and the constant `kClearVenueLocationId` (the NIL UUID).

**Retrofit methods** (`lib/data/api/api_service.dart`, 14):

| Surface | Methods |
|---|---|
| Public | `getVenueOpeningHours`, `listVenueGallery({tag, locationId})` |
| Business hours | `businessGetVenueHours`, `businessUpdateVenueHours`, `businessClearVenueHours`, `businessUpdateBranchHours`, `businessUpdateVenueOperatingStatus`, `businessUpdateBranchOperatingStatus`. All return `ApiResponse<BusinessVenueHoursResponse>` |
| Business gallery | `businessListGallery`, `businessGetGalleryUploadUrl(contentType, contentLength)`, `businessAttachGalleryPhoto`, `businessUpdateGalleryPhoto`, `businessReorderGallery`, `businessDeleteGalleryPhoto` |

The venue detail still comes from the existing `getVenue` / `getVenueByHandle`. The three legacy media methods were removed. Upload goes `businessGetGalleryUploadUrl` → the existing `uploadToS3`, which sends `Content-Length = file.length()`, the same value passed as `contentLength` → `businessAttachGalleryPhoto`.

**Helpers:**
- `VenuePerm.hoursManage = 'venue:hours:manage'` (`access_helpers.dart`), next to `VenuePerm.mediaUpload` / `mediaDelete`.
- `kGalleryTags` and `knownTags(...)` (`presentation/venue/utils/gallery_tags.dart`). Render only known codes.
- `VenueErrorCodes` / `VenueApiError` (`presentation/venue/utils/venue_error_codes.dart`): `CODE:` → localized key.
- `venue_hours_format.dart`: Saturday-first display order and time labels.
- "Today" always comes from the server (`summary.today.date`, `BusinessVenueHoursResponse.today`), never from the device clock.

**Contract fixture.** `VenueResponseJsonContractTest` (hangout-venue) writes `target/contract/venue_response_v106.json`. The app's copy is `test/fixtures/venue_response_v106.json`, parsed by `test/domain/dto/venue_response_v106_test.dart`.

**Codegen after pulling:**
```
cd hangout_app
dart run build_runner build --delete-conflicting-outputs
```

### Admin dashboard (`hangout-super-admin-dashboard`)

- **API modules:** `src/api/venueHours.ts` (`venueHoursApi`), `src/api/venueGallery.ts` (`venueGalleryApi`), `src/api/platformCalendar.ts` (`platformCalendarApi`).
- **Types:** `src/types/venueHours.ts`, `venueGallery.ts`, `platformCalendar.ts`.
- **Error codes:** `src/lib/apiErrorCode.ts` extracts the `CODE:` prefix.
- **Routes:** the Platform Calendar route has `meta.permission: 'admin:platform_calendar:manage'`, and the venue Hours / Gallery tabs gate their actions on `admin:venues:manage`.

Endpoint and permission tables for the dashboard: `hangout_api/ADMIN_DASHBOARD_GUIDE.md` §6.19–§6.21 and §7.

---

## 11. Endpoint quick-ref

### Public (no auth)
```
GET    /api/v1/venues/{venueId}                       (+ openingHours, gallery)
GET    /api/v1/venues/handle/{handle}                 (+ openingHours, gallery)
GET    /api/v1/venues/{venueId}/hours
GET    /api/v1/venues/{venueId}/gallery?tag=&locationId=
```

### Business: hours & status
```
GET    /api/v1/business/venues/{venueId}/hours
PUT    /api/v1/business/venues/{venueId}/hours
DELETE /api/v1/business/venues/{venueId}/hours
PUT    /api/v1/business/venues/{venueId}/locations/{locationId}/hours
PUT    /api/v1/business/venues/{venueId}/operating-status
PUT    /api/v1/business/venues/{venueId}/locations/{locationId}/operating-status
```
Permission: `venue:hours:manage` **+** the same permission at this venue (`VenuePermissionGuard`).

### Business: gallery
```
GET    /api/v1/business/venues/{venueId}/gallery                       venue:media:upload
GET    /api/v1/business/venues/{venueId}/gallery/upload-url?contentType=&contentLength=   venue:media:upload
POST   /api/v1/business/venues/{venueId}/gallery                       venue:media:upload
PATCH  /api/v1/business/venues/{venueId}/gallery/{photoId}             venue:media:delete
PUT    /api/v1/business/venues/{venueId}/gallery/order                 venue:media:delete
DELETE /api/v1/business/venues/{venueId}/gallery/{photoId}             venue:media:delete
```
Each permission is also checked at this venue.

### Admin: venue hours & gallery
```
GET    /api/v1/admin/venues/{venueId}/hours
PUT    /api/v1/admin/venues/{venueId}/hours
DELETE /api/v1/admin/venues/{venueId}/hours
PUT    /api/v1/admin/venues/{venueId}/locations/{locationId}/hours
PUT    /api/v1/admin/venues/{venueId}/operating-status
PUT    /api/v1/admin/venues/{venueId}/locations/{locationId}/operating-status
GET    /api/v1/admin/venues/{venueId}/gallery
POST   /api/v1/admin/venues/{venueId}/gallery/{photoId}/hide
POST   /api/v1/admin/venues/{venueId}/gallery/{photoId}/unhide
DELETE /api/v1/admin/venues/{venueId}/gallery/{photoId}
```
Permission: `admin:venues:manage`.

### Admin: platform calendar
```
GET    /api/v1/admin/platform-calendar?kind=RAMADAN
GET    /api/v1/admin/platform-calendar/status
POST   /api/v1/admin/platform-calendar
PUT    /api/v1/admin/platform-calendar/{id}
DELETE /api/v1/admin/platform-calendar/{id}
```
Permission: `admin:platform_calendar:manage` (SUPERADMIN only).

### Retired (410 Gone)
```
GET    /api/v1/business/venues/{venueId}/media/upload-url
POST   /api/v1/business/venues/{venueId}/media/confirm
DELETE /api/v1/business/venues/{venueId}/media/{mediaId}
```

---

## 12. Where the code differs from the design spec

The code is the source of truth. These differences were found while writing this guide:

| Topic | Code | Spec said |
|---|---|---|
| `BusinessGalleryResponse` | also carries `privacyHintTags: ["family_section", "private_room"]` | not in the shape |
| `reminder.approxNextStart` | the table entry that triggered the banner (during an un-entered Ramadan it names **this** year's start), else the first entry ≥ today | always the first entry ≥ today |
| Calendar `PUT` with no change | no UPDATE, no audit row | always audited |
| `VENUE_PHOTO_HIDE` audit details | `{venueId, reason, s3Key, url}` | `{venueId, reason}` |
| Unhide of a visible photo | a no-op, no audit row; `VENUE_PHOTO_UNHIDE` details are `{venueId, previousReason}` | not specified |
| Hide of an already-hidden photo | updates the reason, keeps the original `hiddenAt` | not specified |
| Branch `INHERIT` hours | `hours_updated_at = NULL` | one pseudo-code line passed `now` (settled in the hours review) |
| Venue status PUT without `status` | 400 `STATUS_REQUIRED` | a bare `@NotNull` (branch-only `STATUS_REQUIRED`) |
| Missing `intervals` on a day | 400 `HOURS_KIND_MISMATCH` | not specified |
| Blank tag / over-long key | `GALLERY_TAG_UNKNOWN` / `GALLERY_KEY_INVALID` | not specified |
| Attach with the NIL UUID as `venueLocationId` | accepted as "venue-wide" | only PATCH mentioned NIL |
| `hours.write.rejected` INFO log | **does not exist** | listed under monitoring |
| S3 delete failure log | `Failed to delete S3 object <key>: …` | `S3 delete failed` |
| Far-future calendar window | accepted with WARN `platform_calendar.far_future` | not specified |
| Admin sign-in after deploy | the dashboard's token refresh also re-derives permissions, so the page appears within 8 h even without signing in again; signing in makes it immediate | "must sign in again" |
| Guide location | this file at the repo root, next to `PUBLIC_EVENTS.md` | placed once at the repo root and once under `hangout_api/` |

---

## 13. File map (backend)

**Migration**
- `hangout-gateway/src/main/resources/db/migration/V106__venue_hours_status_calendar_gallery.sql`

**Domain (hangout-domain)**
- `entity/venue/VenueHours.java`: modified (`venueLocation`, `open24h`, NOT NULL flags)
- `entity/venue/Venue.java`, `entity/venue/VenueLocation.java`: modified (status columns, `@DynamicUpdate`)
- `entity/venue/VenueOperatingStatus.java`, `entity/venue/VenueGalleryPhoto.java`
- `entity/platform/PlatformCalendarKind.java`, `entity/platform/PlatformCalendarPeriod.java`
- `repository/venue/VenueHoursRepository.java`:
  - `findAllForVenue` replaces `findByVenueId`;
  - the per-scope and per-season bulk deletes;
  - `countVenuesWithDefaultHours`.
- `repository/venue/VenueRepository.java`:
  - `findByIdForUpdate`, `updateOperatingStatus`, `updateHoursUpdatedAt`;
  - `updateCoverThumbnailUrl`, `incrementFollowerCount`, `decrementFollowerCount`.
- `repository/venue/VenueLocationRepository.java`: `findByVenueIdWithDistrict`, `updateHoursOverride`, `updateOperatingStatus`
- `repository/venue/VenueGalleryPhotoRepository.java`, `repository/platform/PlatformCalendarPeriodRepository.java`
- `repository/rbac/UserBusinessRoleRepository.java`: `findPermissionNamesByUserIdAndBusinessIdIn`

**Shared (hangout-infrastructure)**
- `hours/OpeningHoursResolver.java`: the pure resolver.
- `hours/WeeklyScheduleValidator.java`: the pure validator.
- `hours/VenueHoursRows.java`: rows ↔ pattern.
- `hours/` value types: `DateWindow`, `DayKind`, `DayRule`, `OpenState`, `ResolvedDay`, `ResolvedStatus`, `ScheduleInput`, `ScopeMode`, `Season`, `TimeRange`, `WeeklyPattern`.
- `service/PlatformCalendarService.java` + `PlatformCalendarServiceImpl.java`: the uncached window reads.
- `service/AdminAuditWriter.java`: the shared admin audit writer.
- `service/S3Service.java`: `generatePresignedPutUrl(key, type, length)` and `headObject`. `service/S3ObjectInfo.java`.
- `service/VenueAccessService.java` + `Impl`: `effectivePermissions`, `hasVenuePermission`.
- `scheduler/VideoThumbnailSweeper.java`, `service/VideoThumbnailEventListener.java`: single-column cover-thumbnail writes.

**Application (hangout-venue)**
- `controller/`: `PublicVenueHoursController`, `PublicVenueGalleryController`, `BusinessVenueHoursController`, `BusinessVenueGalleryController`, `AdminVenueHoursController`, `AdminVenueGalleryController`.
- `security/VenuePermissionGuard.java`.
- `service/`: `VenueHoursService` + `impl/VenueHoursServiceImpl`, `VenueGalleryService` + `impl/VenueGalleryServiceImpl`.
- `service/VenueHoursViewAssembler.java`: reads → DTOs, inheritance, window lookup.
- `service/VenueGalleryViewAssembler.java`, `service/VenueHoursLegacyProjection.java`, `service/VenueCoverResolver.java`.
- `service/`: `Actor`, `ApiTimeFormats`, `GalleryAttachResult`, `VenueGalleryTags`.
- `service/impl/VenueServiceImpl.java`: the detail, the card covers, the atomic follower counts.
- `service/impl/IntentServiceImpl.java`: the card covers.
- `mapper/VenueMapper.java`: ignores the two new fields.
- `dto/request/`:
  - `HoursIntervalInput`, `HoursDayInput`, `WeeklyScheduleInput`, `UpdateVenueHoursRequest`, `UpdateBranchHoursRequest`, `UpdateOperatingStatusRequest`, `UpdateBranchOperatingStatusRequest`;
  - `AttachGalleryPhotoRequest`, `UpdateGalleryPhotoRequest`, `ReorderGalleryRequest`, `HideGalleryPhotoRequest`.
- `dto/response/`:
  - `VenueOpeningHoursResponse`, `ScopeHoursResponse`, `OpenStatusResponse`, `TodayHoursResponse`, `MomentResponse`, `WeeklyScheduleResponse`, `DayScheduleResponse`, `HoursIntervalResponse`, `RamadanWindowResponse`;
  - `BusinessVenueHoursResponse`, `BusinessScopeHoursResponse`;
  - `GalleryPhotoResponse`, `BusinessGalleryPhotoResponse`, `BusinessGalleryResponse`, `GalleryUploadUrlResponse`, `VenueGalleryResponse`;
  - `VenueResponse` (+2 components).

**Admin (hangout-admin)**
- `controller/AdminPlatformCalendarController.java`
- `service/AdminPlatformCalendarService.java` + `impl/AdminPlatformCalendarServiceImpl.java`
- `dto/request/PlatformCalendarPeriodRequest.java`
- `dto/response/PlatformCalendarPeriodResponse.java`, `PlatformCalendarStatusResponse.java`, `PlatformCalendarReminderResponse.java`
- `controller/AdminVideoThumbnailController.java`: 409 when the cover changed during ffmpeg.

**Business (hangout-business)**
- `controller/BusinessVenueController.java`: the three legacy `/media/*` routes → 410.
- `service/BusinessVenueService.java`: the media methods are `@Deprecated`.

**Tests** (JUnit 5 + AssertJ + Mockito; no database):
- **hangout-infrastructure:**
  - `OpeningHoursResolverTest`, which covers the whole case table: A, B, C, D, E, F, G, H, X and J1–J3 under two default zones;
  - `OpeningHoursResolverOracleTest`, 3,000 random cases against a brute-force oracle;
  - `WeeklyScheduleValidatorTest`, `DayRuleTest`, `VenueHoursRowsTest`;
  - `PlatformCalendarServiceImplTest`, `AdminAuditWriterTest`, `S3ServiceTest`, `VenueAccessServiceImplTest`;
  - `VideoThumbnailSweeperTest`, `VideoThumbnailEventListenerTest`.
- **hangout-venue:**
  - `VenueHoursServiceImplTest`, `VenueHoursViewAssemblerTest`, `VenueGalleryServiceImplTest`, `VenueGalleryViewAssemblerTest`;
  - `VenueCoverResolverTest`, `VenueCardCoverCallSitesTest`, `VenueServiceImplDetailTest`, `VenueServiceImplFollowTest`;
  - `VenueHoursControllersTest`, `VenueGalleryControllersTest`;
  - `VenueHoursRequestValidationTest`, `GalleryRequestValidationTest`;
  - `VenueResponseJsonContractTest`, which writes the Flutter fixture;
  - `VenuePermissionGuardTest`, `ActorTest`.
- **hangout-admin:** `AdminPlatformCalendarServiceImplTest`, `AdminPlatformCalendarControllerTest`, `AdminVideoThumbnailControllerTest`.
- **hangout-business:** `BusinessVenueControllerLegacyMediaTest`.
- **hangout-domain:** `RepositoryQueryValidationTest` validates every JPQL method offline.

---

## 14. Future extensions (deferred)

- **"Open now" on cards, pins, trending and search, plus an open-now filter.** The status and override flags are plain columns, and hours sit in one table indexed on `venue_id`. Batch-load the rows with the same pure resolver, **after** any cache or ES read. A paginated SQL filter would need an `EXPLAIN` and a comparison against the resolver first.
- **Dated special hours** (Eid, Ashura/Arbaeen, private events). This is additive: a `venue_hours_exceptions` table plus a `HOLIDAY` value in the `platform_calendar_periods.kind` CHECK. The resolver has one hook for it, `rulesFor(day)`, and the operating-day rule already says how an exception treats the previous night's tail: it doesn't touch it.
- **Per-venue permission check on the older venue endpoints** (media/logo/cover, locations, services, menu…). `VenuePermissionGuard` can be applied one line per method.
- **Automated CloudFront invalidation on delete.** It needs the `awssdk:cloudfront` module, an `app.cdn.distribution-id` setting and `cloudfront:CreateInvalidation` on the role.
- **Orphan-upload sweeper** for keys under `venues/*/gallery/` that were presigned but never attached.
- **Lock order.** `VenueLocationServiceImpl.updateLocation` / `deleteLocation` should take the venue row lock first (§8).
- **Cleanup migration.** After 30 days with no legacy-media WARN line, drop the `/media` endpoints, `VenueMedia` and `venue_media`.
- **Hide or de-rank `PERMANENTLY_CLOSED` venues** in lists, map and search. `VENUE_UPDATED` already fires on the status change.
