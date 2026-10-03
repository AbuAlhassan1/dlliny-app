# Venue Creation Flow — End-to-End Guide

A step-by-step walkthrough of the venue creation flow, from prerequisite business onboarding through the optional content + verification surfaces. Endpoints listed in the order you call them.

---

## 0. Prerequisite — Be a Business User

Before you can create a venue, you need a `BusinessAccount` with the `venue:create` permission. That's a separate onboarding flow:

```
POST /api/v1/business/requests        — submit business application
   ↓
   (admin reviews + approves out-of-band)
   ↓
You get the BusinessAccount + `venue:create` perm in your next JWT
```

After approval, your JWT carries `venue:create`, `venue:read`, `venue:update`, `business:venues:manage`, and the rest. If you already have a business account, skip to step 1.

---

## 1. Create the Venue Row

The single endpoint that creates the `venues` row and bootstraps everything else.

**`POST /api/v1/business/venues`** — auth: `venue:create`

Payload — `CreateBusinessVenueRequest`:

```jsonc
{
  "nameAr":         "كافيه بيروت",     // required, ≤ 200 chars
  "nameEn":         "Café Beirut",     // optional, ≤ 200 chars
  "descriptionAr":  "...",             // optional, TEXT
  "descriptionEn":  "...",             // optional, TEXT
  "categoryId":     3,                 // optional, FK venue_categories.id

  // Location — required iff !onlineOnly, forbidden iff onlineOnly
  "latitude":       33.5138,           // -90..90
  "longitude":      36.2765,           // -180..180
  "addressAr":      "...",             // optional, ≤ 500 chars
  "addressEn":      "...",             // optional
  "cityId":         1,                 // optional, FK cities.id
  "districtId":     12,                // optional, FK districts.id

  "phone":          "+9647xx",         // optional, ≤ 20 chars
  "website":        "https://...",     // optional, ≤ 500 chars
  "priceRange":     2,                 // optional, 1–4
  "inheritStyle":   true,              // false → "style" required
  "style":          "{...}",           // jsonb; only when !inheritStyle

  "onlineOnly":     false              // default false; true forbids lat/lng
}
```

**Response — `BusinessVenueResponse`:**

```jsonc
{
  "venueId":   "f9...",        // ← use this everywhere below
  "handle":    "cafe_beirut_a3f9c1",  // auto-generated; customize in step 3
  "nameAr":    "كافيه بيروت",
  "nameEn":    "Café Beirut",
  // ... full venue shape
}
```

**What the backend does automatically:**

| Action | When |
|---|---|
| Creates the `venues` row | Always |
| Generates a unique handle (V71) | Always — slugified from `name_en` with a 6-hex suffix |
| Grants caller the venue **`owner`** role | Always |
| Creates primary `venue_locations` branch row | Only when `!onlineOnly` |
| Publishes `hangout.venue.created` Kafka event | Always — triggers search indexing |

**Alt path — for multi-business owners:**

If you own multiple businesses and want to scope the venue under a specific one:

```
POST /api/v1/business/accounts/{businessId}/venues
```

Same payload. The auth check additionally verifies you own the target `businessId`.

---

## 2. Add Media (Optional but Typical)

All upload endpoints follow the same **two-step** pattern: request a presigned S3 URL, PUT bytes directly to S3, then confirm with the backend.

### 2.1 Logo (single image)

```
1. GET  /api/v1/business/venues/{venueId}/logo/upload-url?contentType=image/png
        → { uploadUrl, key }

2. PUT  <uploadUrl>
        Content-Type: image/png
        Body: <raw image bytes>
        (uploads directly to S3 — no auth header to S3)

3. POST /api/v1/business/venues/{venueId}/logo
        Body: { "key": "<key from step 1>" }
        → sets venues.logo_url
```

Allowed types: `image/jpeg`, `image/png`, `image/webp`.

### 2.2 Cover (single image, GIF, or video)

Same pattern, different paths:

```
GET  /api/v1/business/venues/{venueId}/cover/upload-url?contentType=video/mp4
PUT  <uploadUrl>
POST /api/v1/business/venues/{venueId}/cover
```

Allowed types: `image/jpeg`, `image/png`, `image/webp`, `image/gif`, `video/mp4`, `video/webm`, `video/quicktime`.

### 2.3 Gallery photos (curated, up to 24 — V106)

The venue's photo gallery («صور المكان»): decor, seating and atmosphere
photos, images only (`image/jpeg`, `image/png`, `image/webp`), ≤ 10 MB
each, **24 per venue** (photos hidden by a moderator count).

```
1. GET  /api/v1/business/venues/{venueId}/gallery/upload-url?contentType=image/jpeg&contentLength=412933
        → { uploadUrl, key, expiresInSeconds: 300, maxBytes: 10485760 }

2. PUT  <uploadUrl>
        Content-Type / Content-Length: exactly as requested (both are signed,
        so S3 rejects any other size)

3. POST /api/v1/business/venues/{venueId}/gallery
        Body: { "key": "<key from step 1>", "width": 1536, "height": 2048,
                "placeholderHash": "<ThumbHash, optional>",
                "tags": ["inside"], "venueLocationId": null }
        → 201 with the photo, or 200 with the existing one when the key is
          already attached (retry-safe)
```

Repeat per photo. Tags come from a fixed vocabulary of 8 (`inside`,
`outside`, `seating`, `ambience`, `facade`, `view`, `family_section`,
`private_room`), at most 3 per photo. `venueLocationId` attributes the photo
to one branch; null = the whole venue.

Managing the gallery:

```
GET    /api/v1/business/venues/{venueId}/gallery            — every photo incl. hidden, + maxPhotos, remaining
PATCH  /api/v1/business/venues/{venueId}/gallery/{photoId}  — { tags?, venueLocationId? } (NIL UUID clears the branch)
PUT    /api/v1/business/venues/{venueId}/gallery/order      — { photoIds: [...] } — the full current set, in order
DELETE /api/v1/business/venues/{venueId}/gallery/{photoId}
```

Readers get the visible photos embedded as `VenueResponse.gallery`
(`totalCount`, `photos`, `tagCounts`), or from
`GET /api/v1/venues/{venueId}/gallery?tag=&locationId=`.

> **Legacy.** The old `…/media/upload-url`, `…/media/confirm` and
> `DELETE …/media/{mediaId}` endpoints answer **410 Gone** since V106, and
> the app no longer calls them. `VenueResponse.mediaUrls` is kept for
> shipped builds: it now lists the visible gallery photos' URLs.

### 2.4 Delete media

```
DELETE /api/v1/business/venues/{venueId}/logo
DELETE /api/v1/business/venues/{venueId}/cover
DELETE /api/v1/business/venues/{venueId}/gallery/{photoId}
```

---

## 3. Customize the Handle (Recommended)

The auto-generated handle (`cafe_beirut_a3f9c1`) works but isn't memorable. The first thing most venue owners do is shorten it.

**`PATCH /api/v1/business/venues/{venueId}/handle`** — auth: `venue:update`

```jsonc
{ "handle": "cafe_beirut" }
```

**Validation rules** (enforced server-side):

| Rule | Detail |
|---|---|
| Length | 3–30 chars |
| Charset | `[a-z0-9_.]` |
| Start + end | Must be `[a-z0-9]` (no leading/trailing `_` or `.`) |
| No consecutive separators | `__`, `..`, `_.`, `._` all rejected |
| Reserved words | `admin`, `support`, `api`, `hangout`, `me`, etc. — see `VenueHandleService.RESERVED` |
| Case | Stored lowercase, case-insensitive unique |
| Rate limit | One change per venue per **30 days** |
| Cooldown | Released handles park **90 days** before re-claim |

**Response:** updated `BusinessVenueResponse` with the new handle. Old handle goes into `venue_handle_history`.

---

## 4. Add Venue Content (Any Order — All Optional)

Each subsection below is self-contained. None depend on the others. Skip what you don't need.

### 4.1 Extra branches (multi-location venues)

For chains with multiple physical locations. The primary location was auto-created in step 1.

```
POST   /api/v1/business/venues/{venueId}/locations    — add a branch
PUT    /api/v1/business/venues/{venueId}/locations/{locationId}
DELETE /api/v1/business/venues/{venueId}/locations/{locationId}
```

### 4.2 Services (shisha, valet, wifi, etc.)

```
GET    /api/v1/venues/service-types                                  — public master list
POST   /api/v1/business/venues/{venueId}/services                    — add one
       Body: { "serviceTypeId": int, "price": double?, "imageUrl": string? }
PUT    /api/v1/business/venues/{venueId}/services/{serviceId}        — edit / soft-disable
DELETE /api/v1/business/venues/{venueId}/services/{serviceId}        — hard delete
```

Auth: `venue:services:manage` (owner / manager / staff).

For service images, use the upload-url endpoint at `.../services/image-upload-url?contentType=image/jpeg`.

### 4.3 Menu

```
POST   /api/v1/business/venues/{venueId}/menu/sections     — create section
POST   /api/v1/business/venues/{venueId}/menu/items        — create item in section
PUT    .../menu/sections/{sectionId}
PUT    .../menu/items/{itemId}
DELETE .../menu/sections/{sectionId}
DELETE .../menu/items/{itemId}
```

Auth: `venue:menu:manage`. Items belong to sections; sections render in `sortOrder`.

### 4.4 Announcements

```
POST   /api/v1/business/venues/{venueId}/announcements
PUT    /api/v1/business/venues/{venueId}/announcements/{id}
DELETE /api/v1/business/venues/{venueId}/announcements/{id}
```

Auth: `venue:announcements:manage`. Pinned announcements show first on the venue profile.

### 4.5 Operating hours & status (V106)

Hours have their own endpoints — they were never part of the main
`PUT /api/v1/business/venues/{venueId}` (its body has no hours field).

```
GET    /api/v1/business/venues/{venueId}/hours                                    — the editor model
PUT    /api/v1/business/venues/{venueId}/hours                                    — venue-default Regular week (+ Ramadan week)
DELETE /api/v1/business/venues/{venueId}/hours                                    — clear both weeks (visitors see no hours)
PUT    /api/v1/business/venues/{venueId}/locations/{locationId}/hours             — branch: { mode: OWN | INHERIT, … }
PUT    /api/v1/business/venues/{venueId}/operating-status                         — { status, reopensOn? }
PUT    /api/v1/business/venues/{venueId}/locations/{locationId}/operating-status  — branch: { mode, status?, reopensOn? }
```

Auth: `venue:hours:manage` (owner, manager — not staff), checked **at this
venue**. Every call answers the whole editor model.

- A week is 7 days (`dayOfWeek` 0 = Sunday … 6 = Saturday), each `CLOSED`,
  `OPEN_24H`, or `HOURS` with 1–4 `{ opens, closes }` (`HH:mm`). A range whose
  close ≤ open runs past midnight; `closes: "00:00"` means "until midnight".
- `ramadan` omitted → the stored Ramadan week is **kept**; sent → replaced;
  `removeRamadan: true` → deleted. The Ramadan dates are set by dlliny.
- Status is `OPEN`, `TEMPORARILY_CLOSED` (optional `reopensOn`, after which it
  reopens by itself) or `PERMANENTLY_CLOSED`.
- Validation errors are 400 with a stable `CODE:` message prefix
  (`HOURS_OVERLAP`, `HOURS_INTERVAL_TOO_SHORT`, `STATUS_REOPEN_DATE_INVALID`…).

Readers get the server-computed status and hours (Asia/Baghdad) as
`VenueResponse.openingHours`, or from the lightweight
`GET /api/v1/venues/{venueId}/hours`. The legacy `VenueResponse.hours` array
keeps its old shape (venue-default rows only) for shipped builds.

### 4.6 Staff

Assign user-venue roles:

```
GET    /api/v1/business/venue-roles                                 — list assignable roles
GET    /api/v1/business/venues/{venueId}/staff                      — current staff
PUT    /api/v1/business/venues/{venueId}/staff/{userId}             — assign role
       Body: { "roleName": "manager" }   // "manager" | "staff"
DELETE /api/v1/business/venues/{venueId}/staff/{userId}             — revoke
```

Auth: `venue:staff:manage` (owner only). The owner role can't be reassigned — use the business-transfer flow if the entire venue needs to change hands.

### 4.7 Posts and product posts

```
POST /api/v1/business/venues/{venueId}/posts        — create a venue post
        Body: { ..., "isProduct": true, "price": 25000 }   // optional product fields
```

Marking `isProduct: true` makes the post orderable — see [PRODUCT_ORDERS_FLOW.md](PRODUCT_ORDERS_FLOW.md).

Auth: `venue:posts:create`.

---

## 5. Submit for Verification (Optional)

To earn the blue checkmark:

```
POST /api/v1/business/venues/{venueId}/verify
     Body: { "documents": "<json or comma-separated CDN URLs>" }
```

Auth: `venue:verify:submit`. Documents should include the trade license (CR), proof of ownership, and contact details.

Status checks:

```
GET /api/v1/business/venues/verification-requests   — your submissions + their status
```

Admin reviews out-of-band; the venue owner gets:
- Push notification + in-app notification on approve / reject
- `venues.is_verified` flipped to `true` on approval
- A rejection note in the verification request row

---

## 6. Edit Anything Later

The main update endpoint is a partial-update PATCH-style PUT — only the fields you send are touched:

```
PUT /api/v1/business/venues/{venueId}
    Body: UpdateBusinessVenueRequest
```

Auth: `venue:update`.

**What you can edit:** name (Ar/En), description, category, location coords + address + city/district, phone, website, price range, style, etc. Opening hours and the operating status have their own endpoints (§4.5).

**What you cannot edit:**
- `onlineOnly` — create-time only. You cannot flip an online venue to physical or vice versa.
- `handle` — use the dedicated `PATCH /api/v1/business/venues/{venueId}/handle` endpoint (rate-limited).
- `isVerified` — admin-controlled via the verification flow.
- `ownerUserId` — use the business-transfer flow.

---

## 7. Minimum Viable Venue

If you just want a venue live with the bare minimum, this is the smallest path:

```
1. POST   /api/v1/business/venues                          — create
2. GET    /api/v1/business/venues/{id}/logo/upload-url     — presigned URL
3. PUT    <uploadUrl>                                      — upload logo to S3
4. POST   /api/v1/business/venues/{id}/logo                — confirm
5. PATCH  /api/v1/business/venues/{id}/handle              — friendly handle
```

**Five calls.** The venue is now:

- ✓ Discoverable in feeds + search
- ✓ Visible on the map (if physical)
- ✓ Reachable by deep link `hangout://venue/{handle}`
- ✓ Showing a logo
- ✗ Not yet verified (blue check)
- ✗ No content beyond the basics (hours/photos/menu/services/staff/posts/products)

Everything else can be added incrementally as the venue scales.

---

## 8. Permission Cheat Sheet

Quick reference for which permission gates which endpoint:

| Permission | Granted to | Endpoints |
|---|---|---|
| `venue:create` | business owner | `POST /api/v1/business/venues` |
| `venue:read` | owner, manager, staff | `GET /api/v1/business/venues` |
| `venue:update` | owner, manager | `PUT .../venues/{id}`, `PATCH .../handle` |
| `venue:media:upload` | owner, manager, staff | logo/cover upload + confirm; gallery list, upload-url + attach |
| `venue:media:delete` | owner, manager | DELETE logo/cover; gallery tags / branch, reorder, delete |
| `venue:hours:manage` | owner, manager | hours, Ramadan week, branch overrides, operating status (§4.5) |
| `venue:verify:submit` | owner, manager | `POST .../verify` |
| `venue:staff:manage` | owner | `PUT/DELETE .../staff/{userId}` |
| `venue:services:manage` | owner, manager, staff | services CRUD |
| `venue:menu:manage` | owner, manager, staff | menu CRUD |
| `venue:announcements:manage` | owner, manager, staff | announcements CRUD |
| `venue:posts:create` | owner, manager, staff | `POST .../posts` |
| `venue:posts:delete` | owner, manager | `DELETE .../posts/{id}` |
| `venue:orders:manage` | owner, manager, staff | product order management |
| `business:venues:manage` | owner | broad business-level admin |

---

## 9. Lifecycle Summary

```
[business onboarding]
        │
        ▼
POST /api/v1/business/venues
        │ ← auto-generates handle, owner role, primary location
        ▼
[upload logo]    [upload cover]    [upload gallery]
        │              │                  │
        └──────────────┼──────────────────┘
                       ▼
PATCH /handle       (customize)
        │
        ▼
[add content]   hours, services, menu, announcements, staff, branches, posts
        │
        ▼
POST /verify        (optional — blue check)
        │
        ▼
Venue is fully operational
        │
        ▼
PUT /venues/{id}    (edit anything later — except onlineOnly + handle + verified)
```

---

*Generated alongside the V71 venue-handles migration and the venue/product-orders work.*
