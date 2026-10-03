# Venue Analytics — Backend Reference

A complete walkthrough of how the venue analytics system works on the Spring Boot backend (`hangout_api/`). Read this end-to-end before wiring the Flutter side — the data model and timing quirks here drive most of the UI decisions.

---

## 1. What this is

Per-venue analytics for business owners. 14 read endpoints across **6 dashboard surfaces**, gated by a Free / Pro split:

| Surface | Endpoints | Tier |
|---|---|---|
| **Buzz + trends** | `/buzz`, `/daily`, `/hangout-funnel` | Free |
| **Content** | `/content/top-posts`, `/content/top-memories`, `/content/review-trend` | Free |
| **Footfall** | `/footfall` | Pro |
| **Competition** | `/leaderboard`, `/movers`, `/peer-benchmark` | Pro |
| **Audience** | `/audience/demographics`, `/audience/activity`, `/audience/loyalists` | Pro |
| **Funnel** | `/funnel` | Pro |

All endpoints sit under `/api/v1/business/venues/{venueId}/analytics/...`. Authority required: `venue:read` (granted to any venue staffer / owner). Service-layer re-asserts venue access against the caller.

---

## 2. Product framing

Vanity metrics (likes, followers) are commodity — every Instagram-clone has them. The actual selling angle is the data nobody else can compute because they don't own a venue-aware social graph + structured event/memory data:

- **Footfall + buzz** — "23 people created memories at your venue last Saturday between 8-11pm." Google has dwell-time but no per-venue mention granularity; Instagram has neither.
- **Competitive rank** — "#3 of 28 cafes in Karrada this week, up from #5." Requires the full graph.
- **Funnel** — feed/map/search impression → profile view → follow → visit → repeat. Five real stages, not the two Instagram-business gives you.

That's the wedge. Everything else is filler that keeps the Free tier sticky enough to upgrade from.

---

## 3. Architecture overview

```
┌────────────── source tables ──────────────┐         ┌── rollup tables ──┐
│                                            │         │                   │
│ memories         (24h expiry)              │         │ venue_analytics_  │
│ memory_mentions  (USER memory tags venue)  │ ──┐     │ daily             │
│ posts            (venue-authored)          │   │     │  ↳ per (venue,    │
│ hangouts         (location → venue)        │   ├──▶  │     day)          │
│ hangout_invitations                        │   │     │                   │
│ venue_follows                              │   │     │                   │
│ reviews                                    │   │     │                   │
│                                            │   │     │ venue_buzz_       │
│ venue_impression_events  (sampled 10%)     │   │     │ weekly  ─────────▶│  (rank +
│  ↳ feed / map / search / profile           │ ──┘     │  ↳ per (venue,    │   delta)
│                                            │         │     ISO week)     │
└────────────────────────────────────────────┘         │                   │
                                                       │ venue_hourly_     │
                                                       │ footfall          │
                                                       │  ↳ 168 cells per  │
                                                       │     venue         │
                                                       └────────┬──────────┘
                                                                │
                                                                ▼
                                                    ┌──── 14 read endpoints ────┐
                                                    │                            │
                                                    │  /buzz                     │
                                                    │  /footfall          (Pro)  │
                                                    │  /daily                    │
                                                    │  /hangout-funnel           │
                                                    │  /leaderboard       (Pro)  │
                                                    │  /movers            (Pro)  │
                                                    │  /peer-benchmark    (Pro)  │
                                                    │  /audience/*        (Pro)  │
                                                    │  /funnel            (Pro)  │
                                                    │  /content/*                │
                                                    │                            │
                                                    └────────────────────────────┘
                                                                │
                                                                ▼
                                                       ┌─── tier gate ───┐
                                                       │ business_accounts │
                                                       │   .pro_until       │
                                                       │  > now() ⇒ allow   │
                                                       │  else  ⇒ 402       │
                                                       └────────────────────┘
```

Three scheduled jobs run the left-to-right arrows. Read endpoints just query the rollup tables — no live aggregation in the request path.

---

## 4. Data model

### 4.1 Rollup tables

#### `venue_analytics_daily`

One row per `(venue_id, date)`. Populated nightly at 02:15 UTC.

| Column | Type | Source |
|---|---|---|
| `venue_id` | UUID | PK |
| `date` | DATE | PK |
| `views` | INT | Legacy; rollup writes 0 |
| `hangouts_created` | INT | `COUNT(*)` from `hangouts WHERE venue_id = ? AND DATE(created_at) = ?` |
| `new_followers` | INT | `COUNT(*)` from `venue_follows WHERE DATE(created_at) = ?` |
| `saves_added` | INT | Legacy; rollup writes 0 |
| `ad_impressions` | INT | Legacy; rollup writes 0 |
| `review_count` | INT | `COUNT(*)` from `reviews` |
| `memory_count` | INT | VENUE-owned memories created today |
| `memory_mention_count` | INT | USER memories that mention the venue today |
| `post_count` | INT | `COUNT(*)` from `posts WHERE venue_id = ?` (venue-authored only) |
| `hangout_attendees` | INT | Accepted invitations whose `responded_at` lands today |
| `review_rating_sum` | NUMERIC | `SUM(rating_overall)` from today's reviews |
| `feed_impressions` | INT | From `venue_impression_events` of type `'feed'` |
| `map_impressions` | INT | …type `'map'` |
| `profile_views` | INT | …type `'profile'` |
| `computed_at` | TIMESTAMPTZ | When the rollup last touched this row |

**Search impressions are NOT in this table** — they're queried live from `venue_impression_events` by the funnel endpoint only. There was no Slice-2-era column to put them in, and adding one for one consumer wasn't worth a schema bump.

#### `venue_buzz_weekly`

One row per `(venue_id, week_start)` where `week_start` is a Monday. Populated every Monday at 03:30 UTC for the just-completed week.

| Column | Type | Notes |
|---|---|---|
| `venue_id` | UUID | PK |
| `week_start` | DATE | PK, always a Monday |
| `buzz_score` | NUMERIC(10,2) | Weighted sum (see formula below) |
| `rank_in_cohort` | INT | RANK() within (category, district) cohort, by buzz_score DESC |
| `cohort_size` | INT | Total venues in the cohort that week |
| `delta_from_prev` | NUMERIC(10,2) | This week's buzz_score minus last week's; NULL on first appearance |
| `computed_at` | TIMESTAMPTZ | Rollup timestamp |

**Buzz score formula** (weights as constants in `AnalyticsRollupService`):

```
buzz_score = SUM over the 7 daily rows of:
    memory_mention_count × 3.0
  + hangout_attendees    × 2.0
  + hangouts_created     × 1.5
  + post_count           × 1.0
  + new_followers        × 1.0
  + review_count         × 1.5
```

Tunable in code without a migration. If we ever promote weights to runtime config we'd also need to stamp them on each row to keep historical comparisons honest.

**Cohort**: `(venue.category_id, venue.district_id)`. Either can be NULL; the rank query uses `IS NOT DISTINCT FROM` so NULLs match NULLs (orphaned-category venues compete against each other).

#### `venue_hourly_footfall`

7 × 24 = 168 max rows per venue. Refreshed every hour at :10 past from a rolling 30-day window. Cells with zero counts are omitted (the rollup deletes-then-inserts so empty cells fall out).

| Column | Type |
|---|---|
| `venue_id` | UUID, PK |
| `day_of_week` | SMALLINT 0..6 (0 = Sunday, matches PG `EXTRACT(dow)`) |
| `hour_of_day` | SMALLINT 0..23 |
| `mention_count` | INT |
| `computed_at` | TIMESTAMPTZ |

**What counts as "footfall"**: union of USER memory mentions of the venue + accepted hangout invitations at the venue, all from the last 30 days. The hour comes from `created_at` or `responded_at` respectively.

#### `venue_impression_events`

Raw event log. Append-only, BIGSERIAL PK for cheap inserts. Aged out at 90 days by the retention sweep.

| Column | Type | Notes |
|---|---|---|
| `id` | BIGSERIAL | PK |
| `venue_id` | UUID | FK |
| `impression_type` | VARCHAR(20) | `'feed' \| 'map' \| 'search' \| 'profile'` |
| `user_id` | UUID NULL | Anonymous impressions (map, search) leave this null |
| `created_at` | TIMESTAMPTZ | |

Indexed for `(venue_id, created_at DESC)` (daily rollup scan) and `(created_at)` (retention sweep).

### 4.2 Source tables (what we aggregate FROM)

| Table | Used for |
|---|---|
| `memories` (owner_type=VENUE) | `memory_count`, top venue memories |
| `memory_mentions` (mention_type=VENUE) + `memories` (owner_type=USER) | `memory_mention_count`, footfall, loyalists, top mentioned memories |
| `posts` (venue_id NOT NULL) | `post_count`, top posts |
| `hangouts` (venue_id) | `hangouts_created`, footfall, funnel |
| `hangout_invitations` | `hangout_attendees`, hangout RSVP funnel |
| `venue_follows` | `new_followers`, demographics, audience activity |
| `reviews` | `review_count`, `review_rating_sum`, review trend |
| `business_venue_access` + `business_accounts` | tier check (`pro_until`) |
| `venue_impression_events` | impression columns + funnel's `searchImpressions` |

### 4.3 Retention

| Table | Retention | Why |
|---|---|---|
| `venue_analytics_daily` | 365 days | Year-over-year trend support |
| `venue_buzz_weekly` | 104 weeks | 2 years for "where were you in 2024?" charts |
| `venue_impression_events` | 90 days | Volume-heavy raw events |
| `venue_hourly_footfall` | (not aged) | Refreshed in place — old cells deleted by the hourly rebuild |

The retention sweep runs daily at 04:00 UTC in [AnalyticsRollupScheduler](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/scheduler/AnalyticsRollupScheduler.java). Each table sweeps in its own transaction so a failure on one doesn't block the others.

---

## 5. Scheduled jobs

All in [AnalyticsRollupScheduler](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/scheduler/AnalyticsRollupScheduler.java). UTC throughout.

| Job | Schedule | What it does |
|---|---|---|
| **Daily rollup** | `cron: 0 15 2 * * *` (02:15) | One INSERT … ON CONFLICT UPDATE per active venue for yesterday's date. Reads 8 source signals; writes 16 columns. |
| **Weekly buzz** | `cron: 0 30 3 * * MON` (Mon 03:30) | Two-pass: insert raw buzz_score, then update rank via `RANK() OVER (PARTITION BY category_id, district_id)`. |
| **Hourly footfall** | `cron: 0 10 * * * *` (every :10) | DELETE rows for venues that had activity in the last 30d, then INSERT fresh aggregates. Cells with no activity are simply absent. |
| **Retention sweep** | `cron: 0 0 4 * * *` (04:00) | Three independent DELETE queries against daily / weekly / impression tables past their windows. |

**Idempotency**: every rollup is safe to re-run. Daily/weekly use `ON CONFLICT (…) DO UPDATE`; hourly footfall is delete-then-insert. Running the daily rollup twice for the same date is a no-op.

**Failure mode**: each scheduled method swallows its exception and logs at ERROR. A failure doesn't poison subsequent runs.

---

## 6. Impression tracking

### 6.1 The service

[AnalyticsImpressionService](hangout_api/hangout-infrastructure/src/main/java/com/beestar/hangout/infrastructure/service/AnalyticsImpressionService.java) is the only writer:

```java
public enum Type { FEED, MAP, SEARCH, PROFILE }

@Async
public void record(UUID venueId, Type type, UUID userId) { ... }
```

- **Sampling**: rejects ~90% of calls before any DB work. Rate is `@Value("${analytics.impression.sample-rate:0.10}")` — tunable per environment. Bump for early data collection, drop as volume grows.
- **Async**: doesn't block the response.
- **Silent failure**: catches all exceptions and logs WARN. Analytics drift beats a 500 to the user.
- **`getSampleRate()`** is exposed so the funnel endpoint can include it in the response; clients project a "true" estimate as `count / sampleRate` when computing ratios.

### 6.2 Call sites

| Module | File | When |
|---|---|---|
| `hangout-venue` | [VenueController.getById](hangout_api/hangout-venue/src/main/java/com/beestar/hangout/venue/controller/VenueController.java) | Public profile fetch → `PROFILE`. User id passed when authenticated. |
| `hangout-map` | [MapServiceImpl](hangout_api/hangout-map/src/main/java/com/beestar/hangout/map/service/impl/MapServiceImpl.java) `getVenuePins` + `getHangoutPins` | Each returned pin → `MAP`. Anonymous (no user id). |
| `hangout-feed` | [FeedServiceImpl.recordFeedImpressions](hangout_api/hangout-feed/src/main/java/com/beestar/hangout/feed/service/impl/FeedServiceImpl.java) | After pagination on `getFollowingFeed` / `getForYouFeed`. Logs one `FEED` impression per item in the **paginated slice** (not the broader window). |
| `hangout-search` | [SearchServiceImpl.search](hangout_api/hangout-search/src/main/java/com/beestar/hangout/search/service/impl/SearchServiceImpl.java) | Each venue result → `SEARCH`. Anonymous. |

The feed integration uses a `postId → venueId` lookup map built from the entity list (PostFeedItem records don't carry venue id directly). Hangout feed items hit `hangoutRepository.findById` per item to resolve the location venue — cheap at default page size (20), revisit if pages get larger.

### 6.3 Sample-rate math

If the configured rate is `r` and the daily rollup says `feed_impressions = N`, the "true" feed reach is approximately `N / r`. Clients computing **ratios** (impression → click, impression → follow) should use either:

- **The raw N for both numerator and denominator** if the click side is also sampled.
- **`N / r` only on impression numerators** when comparing to follows or other unsampled signals — otherwise the ratio understates by ~10×.

The funnel response carries `impressionsSampleRate` precisely so clients can do this projection.

---

## 7. Tier gating (Pro / Free)

### 7.1 Storage

`business_accounts.pro_until TIMESTAMPTZ NULL`. The semantics:

```
pro_until IS NULL      → Free (never been on Pro)
pro_until <= now()     → Free (subscription lapsed; row stays as audit)
pro_until > now()      → Pro
```

One column, dynamic check. No separate boolean to keep in sync.

### 7.2 The check

[BusinessTierService](hangout_api/hangout-infrastructure/src/main/java/com/beestar/hangout/infrastructure/service/BusinessTierService.java):

```java
boolean isProForVenue(UUID venueId);
void    assertProForVenue(UUID venueId, String feature);
```

- Walks `venues → business_venue_access → business_accounts` and reads `MAX(pro_until)` across owning businesses. If multiple businesses own the same venue (rare), any Pro owner upgrades the venue.
- Throws `TierUpgradeRequiredException` if not Pro. Mapped by `GlobalExceptionHandler` to **HTTP 402 Payment Required**.

The 8 Pro endpoints call this right after `venueAccessService.assertVenueAccess(callerId, venueId)`.

### 7.3 402 response shape

```json
{
  "success": false,
  "message": "TIER_UPGRADE_REQUIRED: This feature requires the Pro tier: Footfall heatmap"
}
```

The body starts with the literal `TIER_UPGRADE_REQUIRED:` code so the client can pattern-match without inspecting just the status code. Suggested handling: catch 402 → parse the feature name after the last `: ` → route to a paywall sheet titled with that feature.

### 7.4 Admin upgrade/downgrade

Two endpoints under `/api/v1/admin/businesses/{businessId}/tier/` (gated by `admin:businesses:manage`):

| Method | Path | Body |
|---|---|---|
| `POST` | `/upgrade-pro?until=YYYY-MM-DD` | Sets `pro_until` to end-of-day UTC of the given date. Idempotent. |
| `POST` | `/downgrade` | Sets `pro_until = now()` so it reads as lapsed on the next request. |

These are the manual paths for sales / QA / comp accounts. When Stripe (or a local provider) is integrated, webhooks will write `pro_until` the same way — downstream gating doesn't change.

---

## 8. Endpoint reference

Base path for all per-venue analytics: `/api/v1/business/venues/{venueId}/analytics/`.

All endpoints require:
- Authority `venue:read`
- Venue access check (you must own the venue or have a staff role on it)
- For Pro endpoints: a current `pro_until > now()` on at least one owning business

All responses are wrapped in the standard `ApiResponse<T>` envelope.

### 8.1 `/buzz` — Free

Current week buzz score + 12-week trend.

**GET** `/buzz`

**Response shape**:
```typescript
{
  buzzScore: number,
  rankInCohort: number | null,         // null when no peers in cohort
  cohortSize: number | null,
  deltaFromPrev: number | null,        // null on venue's first appearance
  weekStart: "YYYY-MM-DD",
  trend: [
    { weekStart: "YYYY-MM-DD", buzzScore: number, rankInCohort: number | null },
    ...
  ]
}
```

**Notes**:
- Brand-new venues with no rollup row get a zeroed-shell response, not a 404.
- `trend` is oldest → newest, ready to pipe into a chart.
- Returns up to 12 weekly points.

### 8.2 `/footfall` — Pro

168-cell heatmap from the rolling 30-day window.

**GET** `/footfall`

**Response shape**:
```typescript
{
  cells: [
    { dayOfWeek: 0..6, hourOfDay: 0..23, count: number },
    ...
  ],
  maxCount: number,                    // for color-scale normalization
  privacyFloorApplied: boolean         // true iff any cells were censored
}
```

**Privacy floor**: cells with raw `count < 5` are reported as `0` (omitted from the response). When the floor was applied to at least one non-zero cell, `privacyFloorApplied = true` — render a footnote like "Buckets with fewer than 5 visits aren't shown for privacy."

**Empty cells**: cells the rollup didn't compute (genuinely zero) are also absent. Client should render a 7×24 grid with zeros for missing positions.

### 8.3 `/daily?from&to` — Free

Daily aggregates for the trend chart tab.

**GET** `/daily?from=2026-04-01&to=2026-04-30`

**Defaults**: `to = today`, `from = today - 29 days`.

**Response shape**:
```typescript
{
  from: "YYYY-MM-DD",
  to: "YYYY-MM-DD",
  points: [
    {
      date: "YYYY-MM-DD",
      memoryCount: number,
      memoryMentionCount: number,
      postCount: number,
      hangoutsCreated: number,
      hangoutAttendees: number,
      newFollowers: number,
      reviewCount: number,
      reviewRatingSum: number,
      feedImpressions: number,
      mapImpressions: number,
      profileViews: number
    }
  ]
}
```

**Notes**:
- Server omits days with no activity. Client fills zeros for missing dates.
- Impression numbers are sampled — multiply by `1 / sampleRate` (from `/funnel`) for true reach.

### 8.4 `/hangout-funnel?from&to` — Free

RSVP funnel for hangouts at the venue.

**GET** `/hangout-funnel?from=2026-04-01&to=2026-04-30`

**Response shape**:
```typescript
{
  from: "YYYY-MM-DD",
  to: "YYYY-MM-DD",
  hangoutsCreated: number,
  invited: number,
  accepted: number,
  declined: number,
  pendingNow: number,
  acceptedAfterEvent: number           // proxy for "actually attended"
}
```

**`acceptedAfterEvent`** is a proxy: count of USER memories mentioning the venue, created within ±3h of any hangout's `scheduledAt` in the period. Imperfect but the best signal we have until a real check-in feature ships.

### 8.5 `/leaderboard?size=10` — Pro

Top-N venues in the caller's cohort by current buzz score.

**GET** `/leaderboard?size=10`

**Response shape**:
```typescript
{
  weekStart: "YYYY-MM-DD",
  cohort: {
    categoryId: number | null,         // Short on the server
    categoryNameAr: string | null,
    categoryNameEn: string | null,
    districtId: number | null,         // Integer on the server
    districtNameAr: string | null,
    districtNameEn: string | null,
    size: number
  },
  entries: [
    {
      rank: number,
      venueId: string,
      venueNameAr: string,
      venueNameEn: string,
      buzzScore: number,
      isYou: boolean                   // highlight in UI
    }
  ]
}
```

**Notes**:
- The caller's venue is **always** included in `entries` — even if their rank is below the size cap. The "you're #X" tile reads off this same payload.
- `size` capped at 50 server-side.

### 8.6 `/movers?direction=risers&size=5` — Pro

Top movers (risers or fallers) in the cohort.

**GET** `/movers?direction=risers&size=5`

`direction` ∈ `{"risers", "fallers"}`. Default `"risers"`.

**Response shape**:
```typescript
{
  weekStart: "YYYY-MM-DD",
  direction: "risers" | "fallers",
  entries: [
    {
      venueId: string,
      venueNameAr: string,
      venueNameEn: string,
      buzzScore: number,
      deltaFromPrev: number,           // signed
      rankInCohort: number | null,
      isYou: boolean
    }
  ]
}
```

**Notes**:
- Venues with `delta_from_prev = null` (first-week appearances) are excluded — they aren't meaningful movers either way.
- For fallers, `deltaFromPrev` is negative.

### 8.7 `/peer-benchmark?weeks=4` — Pro

Anonymized cohort comparison across measurable metrics.

**GET** `/peer-benchmark?weeks=4`

**Response shape**:
```typescript
{
  from: "YYYY-MM-DD",
  to: "YYYY-MM-DD",
  cohort: { /* same shape as leaderboard.cohort */ },
  metrics: [
    {
      key: "memory_mentions" | "hangout_attendees" | "post_count"
         | "new_followers" | "review_count",
      you: number,
      median: number,
      p25: number,
      p75: number,
      percentileYou: number            // 0..100
    }
  ]
}
```

**Notes**:
- **Never** returns per-competitor numbers — only `median/p25/p75` aggregates. This is the deliberate anonymous flip-side to the named leaderboard.
- 5 metrics in v1; can grow.
- `key` is a stable identifier; client localizes the label.

### 8.8 `/audience/demographics` — Pro

Follower breakdown by district / city / language / gender.

**GET** `/audience/demographics`

**Response shape**:
```typescript
{
  venueId: string,
  totalFollowers: number,
  byDistrict: [{ label: string, count: number }, ...],
  byCity:     [{ label: string, count: number }, ...],
  byLanguage: [{ label: string, count: number }, ...],
  byGender:   [{ label: string, count: number }, ...],
  privacyFloorApplied: boolean
}
```

**Bucket label conventions**:
- Raw value when present (e.g. `"Karrada"`, `"ar"`, `"male"`).
- `"anonymous"` when the field is unset on the user.
- `"_other_"` when the long-tail folded into one bucket below the privacy floor.

**Privacy floor (3)** applied to **district** and **city** only — language and gender have fixed small option sets and would be useless if folded.

**No age band**: the user profile doesn't store DOB. If/when that field is added we can extend the response.

### 8.9 `/audience/activity` — Pro

"When is your audience online" — 168-cell heatmap derived from when followers create USER memories.

**GET** `/audience/activity`

**Response shape**: identical to `/footfall` but `venueId` and `totalFollowers` fields added at the top.

```typescript
{
  venueId: string,
  totalFollowers: number,
  cells: [{ dayOfWeek: 0..6, hourOfDay: 0..23, count: number }],
  maxCount: number,
  privacyFloorApplied: boolean
}
```

**Privacy floor (5)** — same convention as footfall.

**Performance**: this endpoint does a live JOIN of `memories` × `venue_follows` over a 30-day window. For very large follower bases it could get slow; if it does, the fix is the same pattern as `venue_hourly_footfall` — a dedicated rollup table refreshed hourly. Not built yet.

### 8.10 `/audience/loyalists?days=30&minMentions=3&page=0&size=20` — Pro

Paginated list of users who tagged the venue ≥`minMentions` times.

**GET** `/audience/loyalists?days=30&minMentions=3&page=0&size=20`

**Response shape**:
```typescript
{
  venueId: string,
  days: number,
  minMentions: number,
  page: number,
  size: number,
  totalElements: number,
  totalPages: number,
  items: [
    {
      userId: string,
      username: string,
      displayName: string,
      avatarUrl: string | null,
      mentionCount: number
    }
  ]
}
```

**Notes**:
- `days` capped at 90.
- This is the **only** Pro endpoint that returns identified user data. Justified because the owner can already see who tagged them via the venue mention feed — we're just sorting by intensity.
- Filters out banned / deleted / inactive users.

### 8.11 `/funnel?from&to` — Pro

Full conversion funnel.

**GET** `/funnel?from=2026-04-01&to=2026-04-30`

**Defaults**: last 30 days.

**Response shape**:
```typescript
{
  venueId: string,
  from: "YYYY-MM-DD",
  to: "YYYY-MM-DD",
  feedImpressions: number,
  mapImpressions: number,
  searchImpressions: number,           // queried live from venue_impression_events
  profileViews: number,
  newFollowers: number,
  visitIntent: number,                 // distinct users
  repeatVisitors: number,              // ≥3 mentions in window
  impressionsSampleRate: number        // e.g. 0.1 for 10%
}
```

**Funnel stages**:
1. **Impressions** = `feed + map + search`. The "reach" number.
2. **Profile views** — they clicked into the venue's profile.
3. **New followers** — they followed during the window.
4. **Visit intent** — distinct users who *either* mentioned the venue in a memory OR accepted a hangout invitation in the window. The "they actually showed interest" stage.
5. **Repeat visitors** — distinct users with ≥3 memory mentions in the window. Matches the loyalist threshold.

**Sample rate math**: the impression numbers are sampled. The response carries `impressionsSampleRate` so the client can project. The other four stages are unsampled.

### 8.12 `/content/top-posts?days=30&size=5` — Free

Top venue-authored posts, ranked by `likes + 2 × comments`.

**GET** `/content/top-posts?days=30&size=5`

**Response shape**:
```typescript
{
  venueId: string,
  from: "YYYY-MM-DD",
  to: "YYYY-MM-DD",
  posts: [
    {
      id: string,
      caption: string | null,
      thumbnailUrl: string | null,     // first sort_order media URL
      likesCount: number,
      commentsCount: number,
      createdAt: "...ISO instant..."
    }
  ]
}
```

**Notes**:
- Posts in this codebase are either user-authored OR venue-authored — never both. This endpoint is scoped to venue-authored (`posts.venue_id = :venueId`). There's no "user post tagging the venue" concept in the schema.
- Filters `is_active = true AND is_hidden = false`.
- Engagement weight (2× comments) lives in the service as a constant.

### 8.13 `/content/top-memories?size=5` — Free

Top currently-active memories about the venue, split into own + mentioned.

**GET** `/content/top-memories?size=5`

**Response shape**:
```typescript
{
  venueId: string,
  activeOnly: true,                    // always true — see retention note
  own: [TopMemory],                    // owner_type = VENUE
  mentioned: [TopMemory]               // USER memories tagging the venue
}

TopMemory = {
  id: string,
  contentType: "PHOTO" | "VIDEO" | "TEXT",
  mediaUrl: string | null,
  mediaThumbnailUrl: string | null,
  textContent: string | null,
  createdBy: string,                   // user UUID
  viewCount: number,
  uniqueViewerCount: number,
  createdAt: "...ISO instant...",
  expiresAt: "...ISO instant..."
}
```

**Crucial retention note**: memories die 24h after creation and the sweeper deletes the row. This endpoint can only ever surface memories created within the last day. `activeOnly` is always `true` — show a footnote like "Memories last 24 hours."

The "Top memories of the week" tile owners might want isn't currently buildable — we'd need to snapshot engagement before expiry (separate slice).

### 8.14 `/content/review-trend?days=30` — Free

Daily review counts + per-day average + trailing average.

**GET** `/content/review-trend?days=30`

**Response shape**:
```typescript
{
  venueId: string,
  from: "YYYY-MM-DD",
  to: "YYYY-MM-DD",
  totalReviews: number,
  trailingAverage: number,             // window-wide weighted avg
  points: [
    {
      date: "YYYY-MM-DD",
      count: number,
      averageRating: number | null     // null when count = 0 (but those rows are omitted)
    }
  ]
}
```

**Notes**:
- Server omits days with zero reviews; chart code fills gaps.
- `trailingAverage` is `Σ(rating_sum) / Σ(count)` over the window, rounded to 2 decimals.
- Sentiment via LLM is **not** in this response. Out of scope for v1; will be its own field once wired.

---

## 9. Admin endpoints

### 9.1 Tier management

| Method | Path | Auth | Body / params |
|---|---|---|---|
| `POST` | `/api/v1/admin/businesses/{businessId}/tier/upgrade-pro` | `admin:businesses:manage` | `?until=YYYY-MM-DD` |
| `POST` | `/api/v1/admin/businesses/{businessId}/tier/downgrade` | `admin:businesses:manage` | (none) |

Both return:
```json
{
  "success": true,
  "data": {
    "businessId": "...",
    "proUntil": "2026-12-31T23:59:59Z",
    "tier": "PRO"
  }
}
```

---

## 10. Error responses

Standard `ApiResponse<Void>` envelope, success=false, message present.

| Status | When |
|---|---|
| 200 | Success — including "empty" responses for venues with no rollup data yet |
| 400 | Bad request — invalid date format, etc. |
| 401 | Missing / invalid bearer token |
| 402 | **Pro feature accessed by Free caller** — body prefixed `TIER_UPGRADE_REQUIRED:` |
| 403 | Authority check failed (`venue:read` not granted) OR venue access check failed (you don't have a role on this venue) |
| 404 | Venue or business doesn't exist |
| 500 | Unhandled exception (server logs) |

### 10.1 The 402 body in detail

```
TIER_UPGRADE_REQUIRED: This feature requires the Pro tier: Footfall heatmap
```

Format: `{CODE}: {generic message}: {feature name}`.

The feature name is what you'd show in the paywall sheet. Parse with `lastIndexOf(": ")` after stripping the code prefix.

---

## 11. When does data actually appear?

Critical for UI / client testing:

| Surface | First appearance |
|---|---|
| Buzz, leaderboard, movers, peer benchmark | First Monday 03:30 UTC after launch, for the just-ended week |
| Daily series, hangout funnel, review trend | Next 02:15 UTC for yesterday's activity |
| Footfall heatmap, audience activity | Next :10 after the hour, if there's activity in the last 30 days |
| Audience demographics, loyalists | Live queries — available as soon as there's data |
| Funnel | impression columns populate after the next daily rollup |
| Top posts, top memories | Live queries — available immediately |

**Client implication**: on a brand-new venue or right after launch, expect empty/zero responses for the rollup-backed endpoints until the first scheduled run. This is "no data yet," not an error — render a "we're still collecting" empty state.

---

## 12. Privacy posture

| Endpoint | Floor | What gets censored |
|---|---|---|
| `/footfall` | 5 | Cells with raw count < 5 reported as 0 |
| `/audience/activity` | 5 | Same |
| `/audience/demographics` | 3 | Long-tail district/city buckets fold into `_other_`. Language and gender unflooed. |
| `/peer-benchmark` | n/a | Always anonymous aggregates — never per-competitor |
| `/leaderboard` | n/a | Names other venues (consenting public info — same as Instagram leaderboards) |
| `/audience/loyalists` | n/a | Names users — justified because owner already sees mentions in the venue feed |

`privacyFloorApplied` flags on response payloads let the UI show "Some buckets aren't shown for privacy" footnotes when censoring was applied.

---

## 13. Suggested dashboard layout

A natural pairing of endpoints to UI screens:

```
┌─ Overview tab ─────────────────────────────────────┐
│  Buzz score + rank tile        ◀── /buzz           │
│  This-week summary chart       ◀── /daily          │
│  Hangout RSVP card             ◀── /hangout-funnel │
└────────────────────────────────────────────────────┘

┌─ Audience tab (Pro lock) ──────────────────────────┐
│  Demographic breakdowns        ◀── /audience/demographics │
│  When-online heatmap           ◀── /audience/activity     │
│  Loyalist list                 ◀── /audience/loyalists    │
└────────────────────────────────────────────────────┘

┌─ Competition tab (Pro lock) ───────────────────────┐
│  Category leaderboard tile     ◀── /leaderboard    │
│  Risers + Fallers chips        ◀── /movers         │
│  Peer benchmark bars           ◀── /peer-benchmark │
└────────────────────────────────────────────────────┘

┌─ Content tab ──────────────────────────────────────┐
│  Top posts grid                ◀── /content/top-posts    │
│  Live memories strip           ◀── /content/top-memories │
│  Review rating trend           ◀── /content/review-trend │
└────────────────────────────────────────────────────┘

┌─ Funnel tab (Pro lock) ────────────────────────────┐
│  5-stage funnel viz            ◀── /funnel         │
│  + sample-rate footnote        ◀── /funnel.impressionsSampleRate │
│  Footfall heatmap (cross-link) ◀── /footfall       │
└────────────────────────────────────────────────────┘
```

Sticky considerations:
- **Pro lock UX**: 402 → paywall sheet. Don't gray the screen — render placeholder data with a "Unlock with Pro" overlay so users see what they'd get.
- **Empty states**: rollup-backed tiles should render a "we're collecting data" state when the response is zeros, not an error.
- **Sample-rate footnote** belongs once on the funnel screen, not on every impression number.

---

## 14. Migration history

| Version | Effect |
|---|---|
| **V11** | Initial analytics skeleton: `venue_analytics_daily`, `platform_analytics_daily`, `content_reports`. Daily table created but nothing populated it. |
| **V57** | Extended `venue_analytics_daily` with the full column set used today. Added `venue_buzz_weekly`, `venue_hourly_footfall`, `venue_impression_events`. |
| **V58** | Added `pro_until` to `business_accounts` for tier gating. |

The actual rollup logic that populates V11's skeleton landed alongside V57.

---

## 15. Configuration

`application.yml` knobs:

| Property | Default | Effect |
|---|---|---|
| `analytics.impression.sample-rate` | `0.10` | Probability of recording an impression event. Bump to 1.0 for low-traffic dev/QA so the funnel populates quickly. |

Scheduler crons are hardcoded constants in [AnalyticsRollupScheduler](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/scheduler/AnalyticsRollupScheduler.java). To override per environment, externalize them with `@Scheduled(cron = "${analytics.rollup.daily-cron}")` — not currently needed.

Buzz score weights are constants in [AnalyticsRollupService](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/analytics/AnalyticsRollupService.java) (`W_MENTION = 3.0`, etc.). Tunable in code without a migration.

Retention windows are constants in `AnalyticsRollupScheduler` (`DAILY_RETENTION_DAYS = 365`, `WEEKLY_RETENTION_WEEKS = 104`, `IMPRESSION_RETENTION_DAYS = 90`).

Privacy floors are constants in [BusinessAnalyticsServiceImpl](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/service/impl/BusinessAnalyticsServiceImpl.java) (`FOOTFALL_PRIVACY_FLOOR = 5`, `ACTIVITY_PRIVACY_FLOOR = 5`, `DEMOGRAPHICS_PRIVACY_FLOOR = 3`).

---

## 16. Common pitfalls (read before building UI)

1. **Memory expiry**. `/content/top-memories` only ever shows the last 24h of memories. Don't promise "your top memory this week" — that data is reaped before we could surface it.

2. **Sample rate skews ratios**. Impression numbers are at the configured sample rate (default 10%). If you compute "impression → click" naively, the ratio looks 10× worse than it is. Use `impressionsSampleRate` from the funnel response.

3. **Empty days are omitted**. Both `/daily` and `/content/review-trend` skip days with no activity. Client must fill zeros to render a continuous chart.

4. **`deltaFromPrev` can be null**. A venue's first appearance in the buzz rollup has no previous week to compare to. Render "—" or "new this week."

5. **NULL cohort dimensions**. A venue with `district_id = null` is in a cohort with all other null-district venues (PG `IS NOT DISTINCT FROM`). The leaderboard for that cohort might be small or unrepresentative. UI should call out "Add a district to compare against peers" for those venues.

6. **Pro check happens after access check**. A user without `venue:read` on the venue gets 403, not 402, even on a Pro endpoint. Route 403 to "you don't have permission" and 402 to the paywall.

7. **Search impressions** show up in `/funnel` but not in `/daily`. Search isn't part of the daily-series tile by design — the column doesn't exist. If you want a "search reach over time" chart, that's a small follow-up (new column + rollup line).

8. **Brand-new venues**. Buzz / leaderboard / movers return zeroed/empty shells on first launch — not errors. Render a "we're still collecting data" empty state, not an error toast.

9. **402 body parsing**. The message is `TIER_UPGRADE_REQUIRED: ...: {feature}`. Split on the *last* `": "` to extract the feature name; the middle text contains another colon.

10. **Live vs rolled-up data**. Most endpoints read rollup tables (yesterday's daily, last Monday's weekly). `/audience/demographics`, `/audience/activity`, `/audience/loyalists`, `/content/top-posts`, `/content/top-memories`, `/content/review-trend`, and the search portion of `/funnel` are **live queries**. They have no rollup lag but can be slower for large venues. If a tile feels slow, check this list first.

---

## 17. Future work (intentionally out of scope)

These are reachable but not implemented. The Flutter client should NOT assume they exist:

- **LLM sentiment** on reviews (Slice 6 polish). Same data, new field.
- **Memory engagement archive**. Snapshot engagement before the 24h reaper for a "top memories this week" tile.
- **Stripe billing**. Admin upgrade/downgrade endpoints cover comp accounts for now; real billing webhooks will write `pro_until` the same way.
- **Search impression rollup column** on `venue_analytics_daily`. Currently funnel reads live; trade-off: less query weight but no historical chart for search reach.
- **Per-staff impressions**. Right now feed/profile log a `user_id` but we don't slice by it. Future: "who's viewing your venue most" tile.
- **Age-band demographics**. Not buildable until the user profile gains a DOB or birth-year field.
- **Audience activity rollup**. Live JOIN is fine at current scale; if/when it gets slow, add a `venue_audience_activity_hourly` table on the same pattern as `venue_hourly_footfall`.

---

## 18. Quick reference card

```
14 endpoints, base: /api/v1/business/venues/{venueId}/analytics/

FREE (6):
  GET /buzz
  GET /daily?from&to
  GET /hangout-funnel?from&to
  GET /content/top-posts?days&size
  GET /content/top-memories?size
  GET /content/review-trend?days

PRO (8) → 402 if business.pro_until <= now():
  GET /footfall
  GET /leaderboard?size
  GET /movers?direction&size
  GET /peer-benchmark?weeks
  GET /audience/demographics
  GET /audience/activity
  GET /audience/loyalists?days&minMentions&page&size
  GET /funnel?from&to

ADMIN:
  POST /api/v1/admin/businesses/{id}/tier/upgrade-pro?until=YYYY-MM-DD
  POST /api/v1/admin/businesses/{id}/tier/downgrade

ALL endpoints require Authorization: Bearer {token} with venue:read authority
       + service-layer venue access check.

ERROR CODES:
  401 — bad/missing token
  402 — Pro lock; body starts "TIER_UPGRADE_REQUIRED:"
  403 — authority or venue access denied
  404 — venue or business not found

KEY DATES:
  Daily rollup    — 02:15 UTC every day
  Weekly rollup   — 03:30 UTC Mondays
  Hourly footfall — :10 past every hour
  Retention sweep — 04:00 UTC every day
```
