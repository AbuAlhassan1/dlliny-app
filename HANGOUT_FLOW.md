# Hangout Flow — End-to-End Guide

A complete walkthrough of how the hangout feature works on the Spring Boot backend (`hangout_api/`). This covers the data model, lifecycle, REST surface, visibility rules, Kafka events, push notifications, and the new initial-invitees flow.

---

## 1. Concept

A **hangout** is a scheduled in-person event tied to a **venue**, owned by an **organizer**. It has two distinct visibility phases:

| Phase | Field that controls it | Allowed values | What it gates |
|---|---|---|---|
| **Pre-event** (before `scheduledAt`) | `join_policy` | `OPEN` / `INVITE_ONLY` | Who can discover/access the hangout before it happens |
| **Post-event** (after `scheduledAt`) | `post_visibility` | `PUBLIC` / `FOLLOWERS` / `INVITEES` | Who can still view the hangout (and its media/comments) afterwards |

The split is intentional: a creator might run an **invite-only** dinner but make it **public** afterwards (so the photos show up on their profile feed), or run an **open** meet-up and lock the recap down to **invitees only**.

There are two organizer flavors:

- **User-organized** — a regular user creates a hangout for themselves. `organizer_id` set, `venue_organizer_id` NULL.
- **Venue-organized** — venue staff create a hangout on behalf of a venue (e.g. "Beestar Cafe presents Open Mic Night"). Both `organizer_id` (the staff member who clicked Create) and `venue_organizer_id` (the venue itself) are set. Gated by RBAC permission `venue:hangouts:create`.

---

## 2. Data Model

### 2.1 Tables

```
hangouts
├── id                  UUID PK
├── organizer_id        FK users(id)              — required
├── venue_id            FK venues(id)             — required (where it happens)
├── venue_organizer_id  FK venues(id) NULLABLE    — set when staff created on behalf of venue
├── title               VARCHAR(80)
├── description         TEXT
├── scheduled_at        TIMESTAMPTZ               — when it happens
├── max_attendees       SMALLINT                  — 2..100, includes the organizer
├── status              VARCHAR(20)               — 'confirmed' | 'cancelled'
├── join_policy         VARCHAR(20) NOT NULL      — OPEN | INVITE_ONLY
├── post_visibility     VARCHAR(20) NOT NULL      — PUBLIC | FOLLOWERS | INVITEES
├── whatsapp_link       VARCHAR(500)
├── invite_link         VARCHAR(200) UNIQUE       — random 32-hex, shareable URL token
├── likes_count         INT  NOT NULL DEFAULT 0   — denormalized; ++ on like, -- on unlike
├── comments_count      INT  NOT NULL DEFAULT 0   — denormalized; ++ on insert, -- on soft-delete
├── is_hidden           BOOLEAN NOT NULL DEFAULT FALSE  — admin moderation flag
├── created_at          TIMESTAMPTZ
└── updated_at          TIMESTAMPTZ                — last server-side write (any field). No edit
                                                    endpoint exists today; stamp is auto-updated
                                                    by Hibernate on any mutation (cancel, count
                                                    bump, status change). Treat as a freshness
                                                    signal for cache/ETag, not as a user-edit marker.

hangout_invitations
├── id              UUID PK
├── hangout_id      FK hangouts(id) ON DELETE CASCADE
├── invitee_id      FK users(id)
├── invited_by      FK users(id)
├── status          VARCHAR(20)   — 'pending' | 'accepted' | 'declined'
├── message         TEXT
├── responded_at    TIMESTAMPTZ
├── created_at      TIMESTAMPTZ
└── UNIQUE (hangout_id, invitee_id)

hangout_media
├── id           UUID PK
├── hangout_id   FK hangouts(id) ON DELETE CASCADE
├── url          TEXT
├── media_type   VARCHAR(10)   — 'image' | 'video'
├── uploaded_by  FK users(id)
├── sort_order   SMALLINT       — render order
└── created_at   TIMESTAMPTZ

hangout_likes
├── user_id      FK users(id)
├── hangout_id   FK hangouts(id) ON DELETE CASCADE
├── created_at   TIMESTAMPTZ
└── PRIMARY KEY (user_id, hangout_id)

hangout_comments
├── id                UUID PK
├── hangout_id        FK hangouts(id) ON DELETE CASCADE
├── user_id           FK users(id)
├── parent_comment_id FK hangout_comments(id) ON DELETE CASCADE NULL
│                                          — non-null on replies; one-level
│                                            depth enforced by the service
├── body              TEXT
├── is_active         BOOLEAN DEFAULT TRUE   — soft-delete flag
└── created_at        TIMESTAMPTZ
```

Hangout comments support one-level reply threading (Instagram model) since V54 — a comment may reply to a top-level comment, but a reply cannot itself have replies. The service enforces the depth invariant; the DB only carries the FK + cascade. `reply_count` is computed live at response time from active rows (no stored counter), matching the post-side policy in V53.

### 2.2 Migration history (relevant slice)

| Version | Effect |
|---|---|
| **V3** | Initial schema — `hangouts`, `hangout_invitations`, `hangout_media`, indexes. |
| **V19** | Replaced the original `is_public` boolean with the two-axis model: `join_policy` + `post_visibility`. Added `sort_order` to `hangout_media`. |
| **V22** | `is_hidden BOOLEAN DEFAULT FALSE` for admin moderation (applies to both posts and hangouts). |
| **V23** | `hangout_likes` + `hangout_comments` tables; denormalized `likes_count` and `comments_count` on `hangouts`. |
| **V54** | `hangout_comments.parent_comment_id` (nullable FK to `hangout_comments(id)` with `ON DELETE CASCADE`) + partial index on `(parent_comment_id, created_at ASC) WHERE parent_comment_id IS NOT NULL`. Brings hangout comments to parity with `post_comments` (V53) — one-level reply threading. |

### 2.3 JPA entities

- [Hangout.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/hangout/Hangout.java) — aggregate root.
- [HangoutInvitation.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/hangout/HangoutInvitation.java) — `@ManyToOne` to hangout / invitee / invitedBy.
- [HangoutMedia.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/hangout/HangoutMedia.java)
- [HangoutLike.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/hangout/HangoutLike.java) + [HangoutLikeId.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/hangout/HangoutLikeId.java) — composite-key like row.
- [HangoutComment.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/hangout/HangoutComment.java)

---

## 3. Lifecycle

```
┌────────────────────────────────────────────────────────────────────────┐
│                                                                        │
│   POST /api/v1/hangouts                                                │
│   ├── validate request                                                 │
│   ├── restrictionService.assertAllowed(userId, "hangout:create")       │
│   ├── INSERT hangout (status='confirmed', invite_link=random hex)      │
│   ├── publish HANGOUT_CREATED  ──── kafka ────► fan-out push to        │
│   │                                              organizer's followers │
│   ├── bulkInvite(inviteeUserIds, inviteMessage)  [if list non-empty]   │
│   │   ├── filter unknown / banned / soft-deleted / self / duplicate    │
│   │   ├── trim to remainingCapacity(hangout)                           │
│   │   ├── INSERT hangout_invitations rows (status='pending',           │
│   │   │                                    message=inviteMessage)      │
│   │   └── publish HANGOUT_INVITATION_SENT  ──── kafka ──► push per     │
│   │                                                       invitee     │
│   └── return HangoutResponse                                           │
│                                                                        │
│   ─── time passes ───                                                  │
│                                                                        │
│   POST  /api/v1/hangouts/{id}/invite     (more invitees, capacity-     │
│                                           checked + filtered, same    │
│                                           partial-success contract)   │
│   POST  /api/v1/hangouts/{id}/join       (OPEN only — self-join,      │
│                                           idempotent; pessimistic     │
│                                           lock matches /invite)       │
│         └── publish HANGOUT_RESPONDED → push to organizer              │
│   PATCH /api/v1/hangouts/invitations/{id}/respond                      │
│         └── accepted → publish HANGOUT_RESPONDED → push to organizer   │
│         └── declined → frees its capacity slot                         │
│   POST  /api/v1/hangouts/{id}/likes                                    │
│   POST  /api/v1/hangouts/{id}/comments                                 │
│   POST  /api/v1/hangouts/{id}/media/upload-url   →   PUT to S3         │
│   POST  /api/v1/hangouts/{id}/media/confirm                            │
│                                                                        │
│   ─── scheduledAt arrives ───                                          │
│                                                                        │
│   Visibility crosses over from join_policy → post_visibility.          │
│   No background job — `checkVisibility()` reads scheduledAt < now()    │
│   per-request.                                                         │
│                                                                        │
│   DELETE /api/v1/hangouts/{id}    →   status='cancelled'               │
│                                       publish HANGOUT_CANCELLED        │
│                                       ──► push to pending + accepted   │
│                                           invitees                     │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

Cancellation is a soft state change (`status='cancelled'`). The row stays so attendees keep their history; the discovery queries filter `status != 'cancelled'` to hide it from listings.

`is_hidden=true` is the admin moderation switch. Hidden hangouts are treated as if they don't exist for everyone except the organizer (404 from `getById` and `getByInviteLink`).

---

## 4. Creating a Hangout

### 4.1 Endpoints

| Endpoint | Caller | Notes |
|---|---|---|
| `POST /api/v1/hangouts` | Any user (`hasRole('USER')`) | Self-organized. |
| `POST /api/v1/business/venues/{venueId}/hangouts` | Venue staff (`venue:hangouts:create`) | Records caller as `organizer`, venue as `venue_organizer`. |

Both routes share the same request DTO and end up in `HangoutServiceImpl.doCreate(...)`.

### 4.2 Request body

[CreateHangoutRequest.java](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/dto/request/CreateHangoutRequest.java):

```java
public record CreateHangoutRequest(
    @NotNull UUID venueId,
    @NotBlank @Size(min = 3, max = 80) String title,
    @Size(max = 1000) String description,
    @NotNull @Future Instant scheduledAt,
    @Min(2) @Max(100) Short maxAttendees,
    @NotBlank @Pattern(regexp = "OPEN|INVITE_ONLY") String joinPolicy,
    @NotBlank @Pattern(regexp = "PUBLIC|FOLLOWERS|INVITEES") String postVisibility,
    String whatsappLink,
    @Size(max = 99) List<UUID> inviteeUserIds,   // optional — see §4.4
    @Size(max = 1000) String inviteMessage       // optional — applied to every initial invitee
) {}
```

### 4.3 Service-side validation

[HangoutServiceImpl.doCreate](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/service/impl/HangoutServiceImpl.java):

1. `RestrictionService.assertAllowed(organizerId, "hangout:create")` — throws if the user is currently restricted from creating hangouts (admin moderation tool).
2. Look up the organizer and the venue. 404 on either failure.
3. Build the entity, generate a random 32-hex `invite_link`, persist, flush so the FK chain (`hangouts.invite_link`) is visible to dependent saves.
4. Publish `HANGOUT_CREATED` through the outbox.
5. Call `bulkInvite(...)` for the initial invitee list.

### 4.4 Initial invitees (the recently added Option B)

Before this change, the only way to invite anyone was a second round-trip: `POST /hangouts` → `POST /hangouts/{id}/invite`. That was two transactions, two potential failure points, and an awkward composer UX.

Now `CreateHangoutRequest.inviteeUserIds` lets the composer pass the picker selection in the same body. The service handles it inside the same `@Transactional` block:

```java
private int bulkInvite(Hangout hangout, User inviter,
                       List<UUID> requestedIds, String message) {
    if (requestedIds == null || requestedIds.isEmpty()) return 0;

    LinkedHashSet<UUID> unique = new LinkedHashSet<>(requestedIds);
    unique.remove(inviter.getId());          // organizer can't invite self
    if (unique.isEmpty()) return 0;

    int capacity = remainingCapacity(hangout);   // see §4.5 for the rule
    if (capacity == 0) return 0;

    List<User> resolved = userRepository.findAllById(unique).stream()
        .filter(u -> u.isActive() && !u.isBanned() && u.getDeletedAt() == null)
        .toList();

    List<User> invitees = resolved.size() > capacity
        ? resolved.subList(0, capacity)
        : resolved;

    invitationRepository.saveAll(
        invitees.stream().map(u -> HangoutInvitation.builder()
            .hangout(hangout)
            .invitee(u)
            .invitedBy(inviter)
            .status("pending")
            .message(message)
            .build()).toList()
    );

    invitees.forEach(u -> publish(KafkaConfig.HANGOUT_INVITATION_SENT,
        new HangoutInvitationEvent(hangout.getId(), hangout.getTitle(),
            u.getId(), inviter.getId())));
    return invitees.size();
}
```

**Partial-success contract** (matches the existing `invite()` endpoint):

- Unknown / banned / soft-deleted / duplicate ids are silently dropped, **not** an error.
- The organizer's own id is dropped.
- If the picker selection exceeds the remaining capacity, the tail is trimmed silently.
- No event fires for dropped ids.

Why partial success? The picker UI can race the user's selection against backend state. If the user picks someone who got banned between picking and pressing Create, we'd rather create the hangout with the rest than 400 the whole request. The composer never has to pre-validate.

### 4.5 Capacity rule

```java
private int remainingCapacity(Hangout hangout) {
    long taken = invitationRepository.countByHangoutIdAndStatusIn(
        hangout.getId(), List.of("pending", "accepted"));
    return Math.max(0, hangout.getMaxAttendees() - 1 - (int) taken);
}
```

- The organizer is always counted as 1 occupied slot (hence `-1`).
- **Pending** invitations occupy a slot. The invitee hasn't said yes, but the seat is held until they decline or the organizer revokes.
- **Accepted** invitations occupy a slot (obviously).
- **Declined** invitations free their slot — `respondToInvitation` doesn't delete the row (we keep history), but the row no longer counts.

The same helper is consulted by both the at-create `bulkInvite` and the post-create `POST /hangouts/{id}/invite` endpoint, so capacity is enforced consistently across both call sites. Going over capacity (in either path) silently trims the tail of the supplied id list — same partial-success philosophy.

**Concurrency.** The post-create `invite()` path acquires a `PESSIMISTIC_WRITE` lock on the hangout row via [HangoutRepository.findByIdForUpdate](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/hangout/HangoutRepository.java) before computing capacity. Without it, two in-flight invite requests (e.g. user double-tap, mobile-retry storm, duplicate browser tab, or a future multi-staff invite endpoint) could both read the same remaining-capacity number and collectively overshoot `maxAttendees`. The lock serializes them; the slower request reads the updated count after the first commits. `bulkInvite` at create time doesn't need the lock — the hangout row was just inserted in the same transaction and no other inviter can hold it yet.

The self-join path (`joinHangout`) uses the same lock. It serializes simultaneous self-joins on a popular OPEN hangout and gates the future capacity check the same way `invite()` does today.

### 4.6 Mid-flight + later invites

`POST /api/v1/hangouts/{id}/invite` (after creation, organizer-only) uses [InviteRequest](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/dto/request/InviteRequest.java) `{ userIds, message }`. Same per-invitee Kafka emission, capacity check, banned/deleted filtering, and partial-success contract as `bulkInvite`.

Use the post-create endpoint if you need different messages for different cohorts. The at-create `inviteMessage` is shared across the whole initial batch by design — one message, one transaction.

---

## 5. Visibility Rules

[HangoutServiceImpl.checkVisibility](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/service/impl/HangoutServiceImpl.java) is the single source of truth. Called from `getById(...)`. The invite-link route (`getByInviteLink`) bypasses it but enforces `is_hidden=false` separately — the whole point of an invite link is to grant access regardless of join_policy.

```
1. Organizer always passes.
2. If is_hidden=true and caller != organizer  → 404.
3. If scheduledAt is still in the future (pre-event):
     - join_policy = OPEN          → pass
     - join_policy = INVITE_ONLY   → pass iff caller has a hangout_invitation row
                                     (any status; pending counts — the invite alone grants visibility)
4. If scheduledAt is in the past (post-event):
     - post_visibility = PUBLIC    → pass
     - post_visibility = FOLLOWERS → pass iff follows(caller → organizer) exists
     - post_visibility = INVITEES  → pass iff caller has a hangout_invitation row
```

**Cancelled hangouts.** `checkVisibility` does **not** consult `status='cancelled'`. A cancelled hangout is still resolvable by anyone the live rules above admit — by design. Cancellation is a history-preserving state change: invitees and accepted attendees who push-tapped a cancellation notification need to land on a "this was cancelled" screen, not a 404. Discovery queries already filter `status != 'cancelled'`, so a cancelled hangout never appears in a feed or listing; the only way to hit `getById` is via a direct link or a stored deep-link. In those cases, "it was cancelled" is the useful signal.

The invite-link route (`getByInviteLink`) follows the same philosophy — only `is_hidden=true` produces a 404 there.

Discovery queries are stricter. The listing endpoints don't go through `checkVisibility` — instead, the repository query itself filters:

- [getUserHangouts](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/service/impl/HangoutServiceImpl.java) (profile page) wraps with `ContentVisibilityService.canViewContent(viewerId, profileOwnerId)` — returns `Page.empty(pageable)` if the viewer can't see the profile owner (private account + not following, or mutual block).
- `getPublicVenueHangouts` returns only `status != 'cancelled' AND is_hidden = false`.
- `getMyHangouts` returns everything you organize regardless of state — you always see your own.

`ContentVisibilityService.canViewContent(viewerId, ownerId)` resolves to:
1. False if either side has blocked the other.
2. True if `viewer == owner`.
3. True if the owner is public.
4. True iff the viewer has an `accepted` follow on the (private) owner.

---

## 6. REST Surface

### 6.1 User-facing — `HangoutController` (`/api/v1/hangouts`)

| Method | Path | Description |
|---|---|---|
| `POST` | `/` | Create a hangout. Optional `inviteeUserIds` + shared `inviteMessage` invite people in the same transaction. |
| `GET` | `/{id}` | Fetch by id — runs `checkVisibility`. Cancelled hangouts still resolve for everyone the live rules admit (see §5). |
| `GET` | `/invite/{inviteLink}` | Fetch by share token. Public, only blocks `is_hidden`. |
| `GET` | `/me` | All hangouts I organize (incl. cancelled / hidden). |
| `GET` | `/users/{userId}?page&size` | Hangouts on a user's profile page, page-able. Respects privacy. |
| `DELETE` | `/{id}` | Cancel — organizer only. Sets `status='cancelled'` and fans out push to pending + accepted invitees. |
| `POST` | `/{id}/invite` | Add more invitees after creation. Organizer only. Capacity-checked + banned/deleted filtered. |
| `POST` | `/{id}/join` | Self-join for `OPEN` hangouts. Creates or flips the caller's invitation row to `accepted`. Idempotent. Rejects invite-only / cancelled / past hangouts. Publishes `HANGOUT_RESPONDED` to the organizer. |
| `GET` | `/invitations` | My pending invitations. |
| `PATCH` | `/invitations/{invitationId}/respond` | `{ status: 'accepted' \| 'declined' }`. |
| `POST` | `/{id}/likes` | Like — increments `likes_count`. |
| `DELETE` | `/{id}/likes` | Unlike. |
| `POST` | `/{id}/comments` | Add comment or reply (`parentCommentId` optional). Increments `comments_count`. |
| `GET` | `/{id}/comments?page&size` | List **top-level** comments only. Each row carries `replyCount` so the client can decide whether to fetch replies. |
| `GET` | `/{id}/comments/{commentId}/replies?page&size` | Paginated replies under one parent. Replies always carry `replyCount = 0` (one-level depth). |
| `DELETE` | `/{id}/comments/{commentId}` | Soft-delete (`is_active=false`) — author or organizer only. Works on both top-level rows and replies. |
| `POST` | `/{id}/reports` | Report content for moderation. |
| `GET` | `/{id}/media` | List media in `sort_order` ASC. |
| `GET` | `/{id}/media/upload-url?contentType=...` | Presigned S3 PUT URL. |
| `POST` | `/{id}/media/confirm` | Register an uploaded object in `hangout_media`. |
| `DELETE` | `/{id}/media/{mediaId}` | Remove a media row (and delete the underlying S3 object). |

All endpoints require `hasRole('USER')` except the invite-link one (anonymous read by design).

### 6.2 Venue staff — `BusinessHangoutController` (`/api/v1/business/venues/{venueId}/hangouts`)

| Method | Path | RBAC permission | Description |
|---|---|---|---|
| `POST` | `/` | `venue:hangouts:create` | Venue-organized creation. |
| `GET` | `/` | `venue:hangouts:create` OR `venue:hangouts:cancel` OR `venue:read` | Venue's hangout list (all statuses). |
| `DELETE` | `/{hangoutId}` | `venue:hangouts:cancel` | Cancel a venue's hangout. |

[VenueAccessService.assertVenueAccess](hangout_api/hangout-infrastructure/src/main/java/com/beestar/hangout/infrastructure/service/VenueAccessService.java) is the second-layer check — confirms the caller actually has a role on that specific venue (or its parent business), independent of the RBAC permission grant.

### 6.3 Public venue listing — `PublicVenueHangoutController` (`/api/v1/venues/{venueId}/hangouts`)

| Method | Path | Description |
|---|---|---|
| `GET` | `/?page&size` | Public, anonymous-readable. Filters cancelled + hidden. |

This is what shows up on a venue's public profile in the app.

---

## 7. Discovery Queries

[HangoutRepository](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/hangout/HangoutRepository.java) carries several specialized finders feeding home, discover, and the map:

| Method | Used by |
|---|---|
| `findOpenConfirmedBetween(viewerId, from, to, pageable)` | Authenticated discover feed. Respects privacy + blocks. |
| `findPublicOpenConfirmedBetween(from, to, pageable)` | Anonymous map view. |
| `findOpenFutureHangoutsByOrganizers(organizerIds, now, pageable)` | "Hangouts from people you follow" rail. |
| `findUpcomingInvitedHangouts(userId, now)` | The pre-event urgency strip on home. |
| `findPastHangoutsByOrganizers(organizerIds, now, pageable)` | Memories feed source. |
| `findByOrganizerIdAndStatusNotAndHiddenFalseOrderByScheduledAtDesc(...)` | Profile-page listing. |
| `findByVenueOrganizerIdAndStatusNotAndHiddenFalseOrderByScheduledAtDesc(...)` | Public venue page listing. |

These all filter on `status != 'cancelled'` and `is_hidden = false`. Discovery feeds only surface `join_policy = 'OPEN'` (so `INVITE_ONLY` hangouts never leak into a feed).

---

## 8. Interactions

### 8.1 Likes

[HangoutInteractionServiceImpl](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/service/impl/HangoutInteractionServiceImpl.java) wraps the composite-key `hangout_likes` table:

- `likeHangout` — `INSERT ... ON CONFLICT DO NOTHING` semantics; bumps `hangouts.likes_count` atomically.
- `unlikeHangout` — `DELETE`; decrements `likes_count` (clamped at 0).
- `findLikedHangoutIds(userId, hangoutIds)` — batch check used to hydrate the heart state on feed cards.

### 8.2 Comments

One-level reply threading (Instagram model), matching `post_comments` since V54. A comment is either top-level (`parent_comment_id IS NULL`) or a reply pointing at a top-level. **Replies cannot have replies** — the service rejects with `BusinessException("Replies cannot have replies")`.

`is_active=false` soft-delete. `comments_count` is kept consistent with the visible set: **incremented on insert and decremented on soft-delete** (clamped at 0). The counter increments for both top-level rows and replies, so it reflects total visible comments in the thread. Same policy as `posts.comments_count`. `replyCount` on each top-level response is computed live from active rows (no stored counter) via a single batched `COUNT(*) GROUP BY parent_comment_id` per page — no N+1.

The repo filters `is_active=true` on read so soft-deleted rows are invisible to clients. Soft-deleting a top-level row does **not** cascade soft-delete its replies; the replies become unreachable from the API (the parent is no longer in the top-level listing and the replies endpoint still requires an active parent). Hard-delete (rare — happens only when a hangout itself is hard-deleted) cascades to replies via the `ON DELETE CASCADE` on the self-FK.

`POST /{id}/comments` accepts an optional `parentCommentId` on the body. When non-null, the service validates the parent is active, is in the same hangout, and is itself top-level (one-level depth).

Delete authority: comment author OR hangout organizer (applies to both top-level rows and replies).

### 8.3 Media

Two-step S3 upload (standard pattern):

1. `GET /{id}/media/upload-url?contentType=image/jpeg` → backend mints a presigned S3 PUT URL + the resulting object key.
2. Client `PUT`s the bytes to the presigned URL.
3. `POST /{id}/media/confirm` with `{ key, mediaType, sortOrder }` registers the row in `hangout_media`. The backend constructs the public URL and persists.

Delete (`DELETE /{id}/media/{mediaId}`) removes both the DB row and the S3 object. Organizer or the original uploader can delete.

### 8.4 Reports

Lightweight: writes a `content_reports` row with `{ targetType: 'hangout', targetId, reporterId, reason }`. Routed to the admin dashboard for moderation.

---

## 9. Kafka Events & Push Notifications

### 9.1 Topics

[KafkaConfig.java](hangout_api/hangout-infrastructure/src/main/java/com/beestar/hangout/infrastructure/config/KafkaConfig.java):

| Constant | Topic | Partitions |
|---|---|---|
| `HANGOUT_CREATED` | `hangout.hangout.created` | 6 |
| `HANGOUT_INVITATION_SENT` | `hangout.hangout.invitation.sent` | 6 |
| `HANGOUT_RESPONDED` | `hangout.hangout.responded` | 6 |
| `HANGOUT_CANCELLED` | `hangout.hangout.cancelled` | 3 |
| `HANGOUT_REMINDER` | `hangout.hangout.reminder` | 3 |

### 9.2 Event payloads

```java
record HangoutCreatedEvent(UUID hangoutId, UUID organizerId, String title) {}
record HangoutInvitationEvent(UUID hangoutId, String hangoutTitle, UUID inviteeId, UUID invitedById) {}
record HangoutRespondedEvent(UUID hangoutId, String hangoutTitle, UUID responderId,
                             String responderUsername, UUID organizerId, String status) {}
record HangoutCancelledEvent(UUID hangoutId, String hangoutTitle, UUID organizerId) {}
```

### 9.3 Outbox pattern

The service never sends to Kafka directly. It calls `OutboxEventPublisher.publish(topic, event)`, which writes an outbox row in the same DB transaction as the hangout/invitation mutation. A background dispatcher polls the outbox and forwards to Kafka with at-least-once semantics. This means an invite is either fully created **and** the push is on its way, or neither — no half-state where the row exists but the notification never fires.

### 9.4 Consumer fan-out

[KafkaNotificationConsumer](hangout_api/hangout-notification/src/main/java/com/beestar/hangout/notification/consumer/KafkaNotificationConsumer.java) has dedicated `@KafkaListener` methods for each topic. Each one:

1. Builds a `Notification` row (so the in-app inbox lists it).
2. Sends an FCM push via `FcmService` to the recipient's stored `fcm_token`, with a `hangout://hangout/{id}` deep link in the data extras.

| Event | Recipient | In-app notification type | Push title |
|---|---|---|---|
| `HANGOUT_CREATED` | every follower of the organizer **minus initial invitees** | `HANGOUT_CREATED` | "{organizer} created a hangout" |
| `HANGOUT_INVITATION_SENT` | the invitee | `HANGOUT_INVITATION` | "{inviter} invited you to {title}" |
| `HANGOUT_RESPONDED` (status=accepted) | the organizer | `HANGOUT_ACCEPTED` | "{username} accepted your invite to {title}" |
| `HANGOUT_CANCELLED` | every invitee whose status is `pending` or `accepted` | `HANGOUT_CANCELLED` | "Hangout cancelled: {title}" |

Declined invitees are deliberately skipped from the cancellation fan-out — they already opted out and don't need a follow-up. Pending invitees do get notified: they may have been planning to attend even without explicitly accepting, so silently dropping the event off their calendar would be a worse outcome than one extra push.

**Follower / invitee dedup.** A user who follows the organizer **and** was on the initial-invitee list of a new hangout would otherwise receive two pushes about the same thing (one CREATED, one INVITATION). `onHangoutCreated` queries the hangout's invitation rows and skips followers already in that set — they get the more specific INVITATION push and nothing else. Followers who aren't invitees still receive the CREATED push as before. Post-create `invite()` calls fire INVITATION events only (no second CREATED is emitted), so no dedup is needed there.

`HANGOUT_REMINDER` is a reserved topic constant. No producer or consumer is wired today — it's a placeholder for a future scheduled-reminder job. Not promised to clients.

---

## 10. RBAC Summary

| Action | Required |
|---|---|
| Create user-organized hangout | `ROLE_USER` + `RestrictionService.assertAllowed(userId, "hangout:create")` |
| Create venue-organized hangout | `venue:hangouts:create` permission + `VenueAccessService.assertVenueAccess(userId, venueId)` |
| Cancel own hangout | Organizer match |
| Cancel venue hangout | `venue:hangouts:cancel` + venue access |
| Invite (post-create) | Organizer match |
| Respond to invitation | Invitee match |
| Delete comment | Comment author OR hangout organizer |
| Delete media | Media uploader OR hangout organizer |
| View hidden hangout | Organizer only (anyone else gets 404) |

---

## 11. Common Failure Modes & Their Handling

| Scenario | Behavior |
|---|---|
| Trying to `getById` an `INVITE_ONLY` hangout you weren't invited to (pre-event) | 404 — deliberately indistinguishable from "doesn't exist" so private events aren't enumerable. |
| Trying to `getById` after scheduledAt with `post_visibility=INVITEES` and you weren't invited | 404. |
| Picking 50 invitees when only 9 slots remain | Backend silently trims to the first 9 of the filtered list. No 400. Capacity = `maxAttendees - 1 - count(pending+accepted)`. |
| Inviting yourself | Silently dropped. |
| Inviting a soft-deleted/banned user | Silently dropped — composer doesn't need to check. Applies to both at-create `bulkInvite` and post-create `invite()`. |
| Invitee declines, then organizer invites someone new | Slot is free — declined rows don't count toward capacity. The new invite goes through. |
| Cancelling already cancelled | Idempotent (`status='cancelled'` set again). Cancellation fan-out re-fires, so don't double-cancel as a poke. |
| Liking twice from the same user | Idempotent — `hangout_likes` PK absorbs the second insert; service rejects with `ConflictException("Already liked")`. `likes_count` only goes up once. |
| Two different users like at the exact same instant | Both inserts succeed (different PKs), but the read-modify-write on `likes_count` is racy — a lost update can leave the stored count behind the row count. Same structural issue applies to `unlikeHangout`, `addComment`, and `deleteComment`. Not unique to hangouts; same pattern across the codebase's denormalized counters. The `Math.max(0, ...)` clamp in `unlikeHangout` is defensive — it does **not** protect against this race (it guards a scenario the upstream `existsById` check makes impossible). Fix is `UPDATE … SET likes_count = likes_count + 1` SQL, not a service-layer change; out of scope here. |
| Double-tap on Invite (user fires two requests for the same hangout/list) | Both pass the organizer check; the pessimistic lock on the hangout row serializes them. The second request reads the updated capacity after the first commits, so capacity is honored. Duplicate `(hangout_id, invitee_id)` pairs are caught by the unique constraint and skipped by `existsByHangoutIdAndInviteeId`. |
| Comment soft-deleted | `comments_count` decrements with the row; the visible count and the stored count agree. |
| Comment author deleted their account | Soft-deletion anonymizes the user row (`deleted_user_*`); comments stay with the placeholder author. |
| Cancelled hangout opened via push-tap deep-link | Resolves normally — caller lands on the cancelled-state UI. Only hidden hangouts 404. |
| Hangout deleted (rare — usually cancelled instead) | `ON DELETE CASCADE` wipes invitations, media, likes, comments. |

---

## 12. What's Not Built Yet

- **Scheduled reminders**: the `HANGOUT_REMINDER` topic constant exists but no producer or consumer is wired. When/if we add a reminder scheduler, the doc and any client-facing surfaces should be updated together — don't promise it from the client side until both ends are real.
- **Hangout edit endpoint**: there is no `PATCH /hangouts/{id}` for rescheduling, retitling, or changing the visibility model. Today the policy is cancel-and-recreate. The auto-stamped `updated_at` column survives this gap in case we add it later — currently it just tracks server-side mutations (count bumps, cancellations).
- **Comment reply push notifications**: the post side fires a `COMMENT_REPLIED` Kafka event when a reply is added (pushes the parent author). Hangouts have no comment-related Kafka topics today — neither top-level adds nor replies trigger pushes. If we want notification parity on this surface, that's a separate add: new topic constants, outbox publish in `addComment`, consumer fan-out, and an entry in §9 of this doc.
- **Atomic counters**: `likes_count` and `comments_count` are maintained via read-modify-write in service code. Concurrent same-counter writes can lose updates. Real but small drift; fixable with SQL-level atomic increments. Tracked as a cross-cutting concern, not a hangout-specific one.
- **Multi-staff invite**: `POST /hangouts/{id}/invite` is gated to the original organizer (the single staff member who created the hangout). If/when we open it to any staffer with `venue:hangouts:create` on the venue, the pessimistic lock in §4.5 already covers the resulting concurrency.
