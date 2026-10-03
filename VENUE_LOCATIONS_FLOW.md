# Venue Locations Flow

Multi-location venues — one venue can fan out across N physical branches while still representing one brand/menu/style for the rest of the app. Backend-only.

---

## 1. Concept

Until V62, a venue was a single physical place: one row in `venues` with one `location`, one address, one phone. V62 introduces a side table so a venue can have multiple branches.

| Field | Pre-V62 | Post-V62 |
|---|---|---|
| Identity | venue = brand + place | venue = brand; branches = places |
| Coordinates | `venues.location` | `venue_locations.location` (N rows per venue) |
| Address / phone | `venues.address_*` / `venues.phone` | `venue_locations.address_*` / `venue_locations.phone` |
| Existing reads (For You, nearby, profile header) | direct on `venues` | same — `venues.*` is now a **mirror of the primary branch** |
| Map | one pin per venue | **one pin per branch** within the radius |

Two invariants:

- **Every venue has at least one branch.** The migration backfills one branch per existing venue (marked primary). Delete refuses to remove the last branch.
- **Every venue has exactly one primary branch.** Enforced by a partial unique index. The primary is the "default" — its data mirrors back to the `venues` row so legacy queries keep working.

Content (posts, memories, hangouts, reviews) **still attaches to the venue**, not a branch. The branch is a presentational overlay on top of the venue, not an identity fragmentation.

---

## 2. Migration (V62)

[`V62__venue_locations.sql`](hangout_api/hangout-gateway/src/main/resources/db/migration/V62__venue_locations.sql)

```sql
CREATE TABLE venue_locations (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    venue_id     UUID NOT NULL REFERENCES venues(id) ON DELETE CASCADE,
    label_ar     VARCHAR(100),
    label_en     VARCHAR(100),
    address_ar   VARCHAR(500),
    address_en   VARCHAR(500),
    city_id      SMALLINT REFERENCES cities(id)    ON DELETE SET NULL,
    district_id  INTEGER  REFERENCES districts(id) ON DELETE SET NULL,
    phone        VARCHAR(20),
    location     GEOGRAPHY(POINT, 4326) NOT NULL,
    is_primary   BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order   SMALLINT NOT NULL DEFAULT 0,
    active       BOOLEAN  NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_venue_locations_venue ON venue_locations (venue_id);
CREATE INDEX idx_venue_locations_geom  ON venue_locations USING GIST (location);

CREATE UNIQUE INDEX uq_venue_locations_primary_per_venue
    ON venue_locations (venue_id)
    WHERE is_primary;

-- Backfill: one location per existing venue, marked primary.
INSERT INTO venue_locations (...)
SELECT id, address_ar, address_en, city_id, district_id, phone, location, TRUE, 0
FROM venues WHERE location IS NOT NULL;
```

### Why `GEOGRAPHY` not `GEOMETRY`
Matches the existing `venues.location` column. Geography measures on a sphere — KNN-sorted lookups (`ORDER BY location <-> point`) and `ST_DWithin(..., radiusMeters)` work in meters out of the box.

### Why the partial unique index
Multiple branches per venue, exactly one primary. The `WHERE is_primary` partial means non-primary rows don't participate in the constraint, so promoting a new branch is a clean two-step: set the new one's `is_primary = true`, then demote the old one. (The service does both inside one transaction.)

---

## 3. Data Model

### 3.1 Entity

[`VenueLocation`](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/venue/VenueLocation.java)

```java
@Entity
@Table(name = "venue_locations")
public class VenueLocation {
    UUID id;
    Venue venue;                 // @ManyToOne LAZY
    String labelAr, labelEn;     // optional branch name
    String addressAr, addressEn;
    City city;                   // @ManyToOne LAZY
    District district;           // @ManyToOne LAZY
    String phone;
    Point location;              // GEOGRAPHY(POINT, 4326)
    boolean isPrimary;
    short sortOrder;
    boolean active;
    Instant createdAt, updatedAt;
}
```

### 3.2 Repository

[`VenueLocationRepository`](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/venue/VenueLocationRepository.java)

| Method | Purpose |
|---|---|
| `findByVenueId(venueId)` | All active branches of one venue, **primary first** then by `sort_order`. Used by `VenueResponse.locations` projection and the public list endpoint. |
| `findByVenueIdIn(venueIds)` | Batched version — same ordering. Reserved for feed/summary projections if `locationCount` or `primaryLocation` ever ships on the summary endpoint. |
| `findFirstByVenueIdAndIsPrimaryTrue(venueId)` | Single-shot primary lookup. |
| `countByVenueIdAndActiveTrue(venueId)` | Used by the delete guard. |
| `demoteOtherPrimaries(venueId, keepId)` | `@Modifying` — flips every `is_primary = true` row of this venue (except `keepId`) off. Called inside the same transaction that promotes a new primary, so the partial unique index never sees two primaries at once. |
| `findNearbyLocationIds(lat, lng, radiusMeters, limit)` | Native: KNN-sorted (`<->`) `ST_DWithin` query over `venue_locations` joined to `venues.is_active = true`. Returns location ids in nearest-first order. Used by the map endpoint. |

---

## 4. Service: Create / Update / Delete

[`VenueLocationServiceImpl`](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/service/impl/VenueLocationServiceImpl.java)

Every mutation goes through `VenueAccessService.assertVenueAccess(actorUserId, venueId)`. The endpoint-level `@PreAuthorize("hasAuthority('venue:update')")` is the broad gate; the service re-asserts the venue-row-level access — same defense-in-depth as the rest of the venue management surface.

### 4.1 Add

```java
addLocation(actorUserId, venueId, request) {
    venueAccessService.assertVenueAccess(actorUserId, venueId);
    long existing = locationRepository.countByVenueIdAndActiveTrue(venueId);

    boolean wantPrimary = existing == 0 || request.isPrimary() == TRUE;
    // First branch is auto-primary regardless of the flag.

    save the new location with the resolved isPrimary;

    if (wantPrimary) {
        locationRepository.demoteOtherPrimaries(venueId, newLoc.id);
        syncPrimaryToVenue(venue, newLoc);    // §5
    }
    return toResponse(newLoc);
}
```

### 4.2 Update

```java
updateLocation(actorUserId, venueId, locationId, request) {
    // ... access checks, partial field copy ...

    boolean promotingToPrimary = request.isPrimary == TRUE && !loc.isPrimary;
    if (request.isPrimary == FALSE && loc.isPrimary) {
        throw new BusinessException(
            "Cannot unset the primary branch directly. Promote another branch first.");
    }
    if (promotingToPrimary) loc.setPrimary(true);

    save;
    if (promotingToPrimary) locationRepository.demoteOtherPrimaries(venueId, loc.id);

    if (loc.isPrimary) syncPrimaryToVenue(loc.venue, loc);
}
```

### 4.3 Delete (soft)

```java
deleteLocation(actorUserId, venueId, locationId) {
    venueAccessService.assertVenueAccess(actorUserId, venueId);
    if (countActive(venueId) <= 1) throw "Cannot delete the only branch";
    if (loc.isPrimary)             throw "Cannot delete the primary branch. Promote another first.";
    loc.setActive(false);
    save;
}
```

Soft delete (`active = false`) — the row stays for any historical references (review-by-location, future analytics) but disappears from listings. Hard delete would still cascade via the `ON DELETE CASCADE` FK if the venue itself is removed.

---

## 5. The `venues` Row as a Primary Mirror

The key trick that lets V62 ship without touching the rest of the codebase:

> Whenever the primary branch changes (created, promoted, or its address/lat-lng/phone is edited), `syncPrimaryToVenue` mirrors the data back to the `venues` row.

```java
private void syncPrimaryToVenue(Venue venue, VenueLocation primary) {
    venue.setLocation(primary.getLocation());
    venue.setAddressAr(primary.getAddressAr());
    venue.setAddressEn(primary.getAddressEn());
    venue.setCity(primary.getCity());
    venue.setDistrict(primary.getDistrict());
    venue.setPhone(primary.getPhone());
    venueRepository.save(venue);
}
```

What this buys:

- `GET /api/v1/venues/nearby` — still queries `venues.location` (the primary).
- For You feed nearby-venue ranking — unchanged.
- Profile header — reads `venues.address_*` and renders fine.
- Existing analytics rollups keyed on `venues.city_id` / `venues.district_id` — unchanged.

The only place that fans out to all branches today is the **map endpoint** (§7). Everything else uses the primary.

---

## 6. REST Surface

| Method | Path | Authority | Body |
|---|---|---|---|
| `GET` | `/api/v1/venues/{venueId}/locations` | public read | — |
| `GET` | `/api/v1/business/venues/{venueId}/locations` | `venue:read` | — |
| `POST` | `/api/v1/business/venues/{venueId}/locations` | `venue:update` | `CreateVenueLocationRequest` |
| `PUT` | `/api/v1/business/venues/{venueId}/locations/{locationId}` | `venue:update` | `UpdateVenueLocationRequest` |
| `DELETE` | `/api/v1/business/venues/{venueId}/locations/{locationId}` | `venue:update` | — |

### 6.1 Request DTOs

[`CreateVenueLocationRequest`](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/dto/request/CreateVenueLocationRequest.java)

```java
record CreateVenueLocationRequest(
    String labelAr, String labelEn,        // optional branch name
    String addressAr, String addressEn,
    Short cityId, Integer districtId,
    String phone,
    @NotNull Double latitude,              // -90..90
    @NotNull Double longitude,             // -180..180
    Boolean isPrimary,                     // honored after the first branch
    Short sortOrder) {}
```

[`UpdateVenueLocationRequest`](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/dto/request/UpdateVenueLocationRequest.java) — same shape, every field nullable, partial update.

### 6.2 Response DTO

[`VenueLocationResponse`](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/dto/response/VenueLocationResponse.java)

```java
record VenueLocationResponse(
    UUID id, UUID venueId,
    String labelAr, String labelEn,
    String addressAr, String addressEn,
    Short cityId, String cityNameAr,
    Integer districtId, String districtNameAr, String districtNameEn,
    String phone,
    double latitude, double longitude,
    boolean isPrimary, short sortOrder) {}
```

### 6.3 Embedded on the venue detail

`VenueResponse` gains:

```java
List<VenueLocationResponse> locations;   // primary first
```

Single-location venues get a one-element list. The top-level `latitude`/`longitude`/`addressAr`/`addressEn`/`cityId`/`districtId`/`phone` continue to mirror the primary branch for back-compat — new UI iterates the list.

---

## 7. Map Endpoint Fan-Out

[`MapServiceImpl.getVenuePins`](hangout_api/hangout-map/src/main/java/com/beestar/hangout/map/service/impl/MapServiceImpl.java)

### 7.1 Before V62

```
venueRepository.findNearby(lat, lng, radius, 200)   // queries venues.location
  → one MapVenuePin per venue
```

### 7.2 After V62

```
venueLocationRepository.findNearbyLocationIds(...)  // queries venue_locations.location
  → fetch entities (with venue eagerly joined)
  → one MapVenuePin per branch, nearest-first
```

### 7.3 Pin shape

[`MapVenuePin`](hangout_api/hangout-map/src/main/java/com/beestar/hangout/map/dto/response/MapVenuePin.java)

```java
record MapVenuePin(
    UUID id,             // venue id — tap → venue profile (back-compat)
    UUID locationId,     // NEW — specific branch this pin represents
    String nameAr, String nameEn,
    String labelAr,      // NEW — branch chip, populated only when distinguishing
    String labelEn,      //       (the venue has >1 branch in the visible tile)
    double latitude, double longitude,
    String categoryCode, BigDecimal avgRating,
    boolean hasActiveHangout) {}
```

### 7.4 Branch label gating

```java
Map<UUID, Long> branchCountByVenue = byId.values().stream()
    .collect(groupingBy(l -> l.getVenue().getId(), counting()));

boolean multiBranch = branchCountByVenue.getOrDefault(v.getId(), 1L) > 1;
labelAr = multiBranch ? loc.getLabelAr() : null;
```

A single-branch venue ships `labelAr = null` even if a label is stored — keeps the chip out of the way when it's not adding information.

### 7.5 Analytics impressions

Recorded against the **venue** (not the branch), so the existing daily rollup aggregates correctly regardless of how many pins a viewer saw for the same venue. One pin = one impression on the underlying venue (subject to the 10% sampling already in `AnalyticsImpressionService`).

---

## 8. Concurrency

| Race | Outcome |
|---|---|
| Two concurrent promote-to-primary calls on the same venue | One transaction's `demoteOtherPrimaries` + insert wins; the other hits the partial unique index `uq_venue_locations_primary_per_venue` and rolls back. |
| Update of a location's address/lat happens concurrently with another branch being promoted to primary | Both transactions land cleanly — they touch different rows. The mirror to `venues` is only done by the primary-mutation transaction; a non-primary address change doesn't trigger the mirror. |
| Delete the primary while another tx is promoting a sibling | Delete refuses (`Cannot delete the primary branch`); promotion proceeds; after commit the old primary can be deleted. |

No explicit pessimistic locks needed — the partial unique index is the only cross-row invariant and it's enforced at insert/update time.

---

## 9. Error Responses

| Condition | HTTP | Message |
|---|---|---|
| Venue not found | 404 | "Venue not found" |
| Location not found / wrong venue | 404 | "Location not found" |
| City id unknown | 404 | "City not found" |
| District id unknown | 404 | "District not found" |
| Trying to `isPrimary = false` on the current primary | 400 | "Cannot unset the primary branch directly. Promote another branch first." |
| Delete the last remaining branch | 400 | "Cannot delete the only branch — a venue must always have at least one location." |
| Delete the primary branch | 400 | "Cannot delete the primary branch. Promote another branch first." |
| Missing required body fields | 400 | Bean-validation messages |

---

## 10. What's Intentionally Out of Scope (for v1)

- **Per-branch content.** Posts / memories / hangouts / reviews still attach to `venue_id`, not `venue_location_id`. If you later want "this hangout happened at the Karada branch," it's a `venue_location_id` column on the relevant tables + an additional filter — purely additive, no V62 churn.
- **"Closest branch" sorting on `/api/v1/venues/nearby`.** That endpoint still uses `venues.location` (the primary). With the map fan-out you already see all branches as pins; if the list-view needs the same treatment, swap the query to `venue_locations` and aggregate-by-venue or split into one row per branch (UX decision).
- **`locationCount` on summary endpoints.** Kept the summary payload small for now. If a multi-branch badge ever ships on the home feed card, add `Long locationCount` to `VenueSummaryResponse` and project it via `findByVenueIdIn` (already batched).
- **Per-branch hours.** `venue_hours` still hangs off `venue_id`. Same additive change if needed.
- **Per-branch analytics.** Analytics still rolls up at venue level. Splitting impressions / followers by branch would need a `venue_location_id` column on the analytics tables.

---

## 11. File Index

| File | Role |
|---|---|
| [V62__venue_locations.sql](hangout_api/hangout-gateway/src/main/resources/db/migration/V62__venue_locations.sql) | Schema + backfill |
| [VenueLocation.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/venue/VenueLocation.java) | JPA entity |
| [VenueLocationRepository.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/venue/VenueLocationRepository.java) | Queries — incl. `demoteOtherPrimaries` and native `findNearbyLocationIds` |
| [VenueLocationResponse.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/dto/response/VenueLocationResponse.java) | Response DTO |
| [CreateVenueLocationRequest.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/dto/request/CreateVenueLocationRequest.java) | Create payload |
| [UpdateVenueLocationRequest.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/dto/request/UpdateVenueLocationRequest.java) | Partial update payload |
| [VenueLocationService.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/service/VenueLocationService.java) | Interface |
| [VenueLocationServiceImpl.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/service/impl/VenueLocationServiceImpl.java) | CRUD + sync-primary-to-venue logic |
| [BusinessVenueLocationController.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/controller/BusinessVenueLocationController.java) | Business REST surface |
| [PublicVenueLocationController.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/controller/PublicVenueLocationController.java) | Public read |
| [VenueResponse.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/dto/response/VenueResponse.java) | `locations` array added |
| [VenueServiceImpl.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/service/impl/VenueServiceImpl.java) | Projects `locations` on detail; calls `VenueLocationServiceImpl::toResponse` |
| [VenueMapper.java](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/mapper/VenueMapper.java) | `@Mapping(target = "locations", ignore = true)` — service populates manually |
| [MapVenuePin.java](hangout_api/hangout-map/src/main/java/com/beestar/hangout/map/dto/response/MapVenuePin.java) | `locationId` + `labelAr/En` added |
| [MapServiceImpl.java](hangout_api/hangout-map/src/main/java/com/beestar/hangout/map/service/impl/MapServiceImpl.java) | Pin fan-out logic |

---

## 12. Quick Reference: End-to-End Add a Branch

1. Business owner calls **`POST /api/v1/business/venues/{venueId}/locations`** with `{ labelAr: "فرع زيونة", addressAr: "...", latitude: 33.31, longitude: 44.45, isPrimary: false }`.
2. Service asserts venue access → inserts a row in `venue_locations` with `is_primary = false` (since explicit) and `sort_order = (existing count)`.
3. `venues.*` unchanged (this branch isn't primary).
4. Returns the new `VenueLocationResponse`.
5. Next call to `GET /api/v1/map/venues?lat=...&lng=...` near the new coordinates → returns a pin with `locationId` = the new branch, and **both pins now carry `labelAr`** (the venue went from 1 → 2 branches).

## 13. Quick Reference: Promote a Branch

1. **`PUT /api/v1/business/venues/{venueId}/locations/{locationId}`** with `{ isPrimary: true }`.
2. Service flips this row's `is_primary = true`, saves.
3. `demoteOtherPrimaries(venueId, locationId)` clears the flag on the previous primary inside the same transaction.
4. `syncPrimaryToVenue` mirrors the new primary's `location`, `address_*`, `city_id`, `district_id`, `phone` back to the `venues` row.
5. From here on, `/api/v1/venues/nearby`, For You ranking, and the venue profile header all return the new primary's data.
