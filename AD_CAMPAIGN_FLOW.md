# Ad Campaign Flow — Conceptual Walkthrough

## Two sides of the system

There's an **advertiser side** (the business owner running ads) and a **consumer side** (the user who sees them). The platform mediates the two via admin approval, automated lifecycle, and budget enforcement.

```
Advertiser           Platform              Consumer
─────────            ────────              ────────
business owner ──→  admin review  ──→  served at scale
                         ↓
                    auto-scheduler
                         ↓
                  serving + billing
```

---

## Part 1 — Three creative types, three intents

When a business creates a campaign, they pick **what** they're promoting:

| Type | What it shows | Use case |
|---|---|---|
| **POST** | Boost an existing venue post | "Our new dessert post is doing well organically — let's pay to show it wider" |
| **HANGOUT** | Boost a hangout event | "We're hosting a poetry night on Friday — get more attendees" |
| **CUSTOM** | Fresh image/video + caption + CTA button | "Run a brand campaign with content that isn't in the feed" |

And they pick **where** it shows (placement):

| Placement | Surface |
|---|---|
| `feed_card` | Sponsored post slot in the main feed |
| `reels_placement` | Sponsored slot in the reels surface |
| `map_pin` | Sponsored pin on the map (only for physical venues — online-only venues can't run map_pin campaigns) |

They also set a **budget** (total spend cap), a **CPM** (cost per 1000 impressions — their bid), a **time window** (`startsAt` / `endsAt`), and **targeting** (which districts and venue categories to reach).

---

## Part 2 — The state machine

Every campaign moves through this lifecycle:

```
        pending  ──→  approved  ──→  active  ──→  completed
           │             │              │
           │             │              └──→  completed  (budget exhausted)
           ↓             ↓
        rejected     (admin can also pause later — feature exists in schema)
```

| State | Meaning | How you get there |
|---|---|---|
| `pending` | Just created, waiting for admin review | Business POSTs to `/api/v1/business/campaigns` |
| `approved` | Admin said yes, but not yet live | Admin POSTs `/api/v1/admin/campaigns/{id}/approve` |
| `active` | Live — being served to users | Lifecycle scheduler flips when `startsAt <= now` |
| `completed` | Done — either time window ended or budget ran out | Scheduler (time-based) or serving service (budget-based) |
| `rejected` | Admin denied with reason | Admin POSTs `/reject` with a rejection reason |
| `paused` | Reserved for future "pause this campaign" admin action | Not yet wired |

**The state transitions are protected**:
- Once a campaign is `approved` or `active`, the underlying post/hangout it boosts becomes **uneditable and undeletable**. Prevents bait-and-switch — an advertiser can't approve a clean post and then edit it to something offensive. The lock releases automatically when the campaign reaches `completed` / `rejected`.

---

## Part 3 — How a user gets an ad

When the Flutter app needs a sponsored slot for the feed, map, or reels, it calls `GET /api/v1/ads?placement=…`. Server-side, here's what happens — all inside one transaction:

### Step A: Resolve the user's targeting context
The server looks up the user's **district** from the user profile. That's the geo dimension.

### Step B: Find candidate campaigns
A single indexed query pulls up to 50 candidates that match:
- Status is `active`
- Current time is within `[startsAt, endsAt)`
- `spent < budget` (haven't exhausted budget)
- Placement (`type`) matches what was requested
- Either targets no districts (empty list = nation-wide) OR includes this user's district

### Step C: Rank by weighted CPM (the auction)
This is the interesting part. Naively sorting by CPM would let the single highest bidder dominate every slot. Instead, the server uses **A-Res reservoir sampling**:

- Each candidate gets a random key, raised to the power of `1/CPM`
- Top N keys win

What this means in practice:
- An advertiser bidding 500 CPM has a higher *probability* of being picked than one bidding 100, but not a *guarantee*
- Two campaigns at the same CPM have equal chances every shake
- Across many serves, the share of impressions each campaign wins is roughly proportional to its CPM

It's the simplest "fair auction" that beats both pure-random (advertisers can't differentiate) and pure-top-CPM (only whales ever win).

### Step D: Record the impression and charge for it
For each winning campaign, the server runs an **atomic conditional UPDATE**:

```sql
UPDATE ad_campaigns
   SET spent = spent + (cpm / 1000)
 WHERE id = X
   AND spent + (cpm / 1000) <= budget
```

This single SQL statement is the entire billing engine. Two important properties:

1. **Atomic per-row** — Postgres guarantees no two concurrent impressions can over-draw the budget. The second one's UPDATE silently no-ops.
2. **Self-policing** — if a parallel request just exhausted the budget, this impression is **dropped** (not returned to the user, not charged for, no free ride).

After the UPDATE succeeds:
- An `ad_impressions` row is inserted (campaign + user + placement + timestamp)
- A second tiny UPDATE checks if the campaign just hit budget and flips status to `completed` if so

### Step E: Hydrate and return
The winning campaigns' creatives (post snapshot, hangout description, or custom media) are bulk-loaded in one query. The server flattens everything into a `ServedAdItem` (ad ID, venue context, creative content, optional CTA) and returns the batch.

---

## Part 4 — When the user taps

The Flutter client tracks each `adId` it rendered. When the user taps the CTA:

1. Flutter calls `POST /api/v1/ads/{adId}/click`
2. Server runs a single atomic `UPDATE click_count = click_count + 1`
3. Server returns success
4. Flutter navigates to the `ctaUrl` (https web link, `hangout://` deep link, `tel:`, or `whatsapp:`)

**Clicks don't affect billing** — only impressions cost money. Clicks are pure attribution / reporting. A CTR (click-through rate) for the business owner is `click_count / impression_count`.

---

## Part 5 — Two paths close a campaign

Campaigns end the moment **either** condition trips:

| Path | Where it lives | Cadence |
|---|---|---|
| **Time exhausted** (`endsAt <= now`) | `AdCampaignLifecycleScheduler` cron | every 60 seconds |
| **Budget exhausted** (`spent >= budget`) | Inline in the serving path | per impression |

The time-based path is the scheduler — it sweeps every minute, finds active campaigns past their end window, and closes them. The budget-based path closes inline: the moment the impression that drained the budget commits, the next conditional UPDATE flips status to `completed`. No advertiser ever gets a free impression past their budget.

---

## Part 6 — The admin loop (already worked before; now actually functional)

The original schema had a CHECK constraint missing the `'approved'` value, so the existing approve code path silently broke if anyone tried it. V75 fixed that. The admin flow now works end-to-end:

1. Admin lists pending campaigns: `GET /api/v1/admin/campaigns/pending`
2. Reviews the creative (the source post / hangout / custom media + caption + CTA)
3. Either:
   - **Approves**: `POST /api/v1/admin/campaigns/{id}/approve` → status flips to `approved`, scheduler picks it up at `startsAt`
   - **Rejects**: `POST /api/v1/admin/campaigns/{id}/reject` with a reason → status `rejected`, business owner sees the rejection reason

---

## Part 7 — The trust boundary

Worth highlighting: the platform makes **two independent guarantees** that protect against the obvious failure modes:

1. **No over-spending** — the conditional UPDATE on `spent` is mathematically airtight. An advertiser can't be billed past their budget even under heavy concurrent load.

2. **No content drift** — once a campaign is approved, the underlying post/hangout is locked. The advertiser can't edit "Half-off lunch!" into "Click here for free crypto." The lock releases only when the campaign reaches a terminal state (`completed` / `rejected`).

These two guards are what let you safely sell ads without a human watching every impression.

---

## Part 8 — End-to-end timeline (a concrete example)

Imagine a coffee shop in Karrada runs a 7-day feed campaign:

```
Day 0, 14:00 — Owner submits campaign         → status: pending
                budget: 50,000 IQD
                CPM: 200 IQD per 1k impressions
                placement: feed_card
                target_districts: ["Karrada"]
                startsAt: tomorrow 09:00
                endsAt: 7 days later 21:00

Day 0, 16:30 — Admin reviews + approves        → status: approved
                                                  (post + hangout locks engage)

Day 1, 09:00 — Scheduler ticks, startsAt hit   → status: active
                                                  (ad enters the auction)

Day 1, 09:00 onward —
   For every user in Karrada whose feed loads:
     → server pulls candidate ads (this one is in the pool)
     → ranker picks N winners
     → if this campaign wins a slot:
         spent += 0.20 IQD
         ad_impressions row inserted
         ad rendered in user's feed
     → user may tap → click_count += 1, navigate to CTA

Day 4, 03:42 — spent passes 50,000 IQD         → status: completed
   (the impression that pushed it over commits;
    the next conditional UPDATE flips status)
                                                  (locks release)

OR if budget never exhausts:
Day 7, 21:00 — endsAt hit                       → status: completed
                                                  (scheduler closes within 60s)
                                                  (locks release)

Owner inspects performance:
   spent:        50,000.00 IQD
   impressions:  250,000   (50,000 / 0.20)
   clicks:       3,840
   CTR:          1.53%
```

That's the whole loop — submission, approval, automated activation, fair auction, atomic billing, automated closure.
