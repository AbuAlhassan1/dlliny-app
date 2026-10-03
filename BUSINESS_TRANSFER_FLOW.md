# Business / Venue Ownership Transfer Flow

A complete walkthrough of how the two-phase ownership-transfer feature works on the Spring Boot backend (`hangout_api/`). Covers the data model, state machine, REST surface, authority model, accept-side state mutations, Kafka events, push notifications, and the expiry sweep.

> **Scope.** Backend only. Flutter consumption is not covered here.

---

## 1. Concept

Two distinct flavors share one mechanism:

| Type | What moves | What stays | Accept-side mutation |
|---|---|---|---|
| **`BUSINESS`** | The entire `business_account` — and everything that hangs off it via FK (venues, staff, content, posts, memories) | Nothing — content travels for free because it's attached to the business/venue, not the owner user | One row update: `business_accounts.user_id ← targetUser.id` |
| **`VENUE`** | A single venue moves out of the sender's business into one of the recipient's businesses | Content stays attached to the venue and follows it; **all** existing `user_venue_roles` for that venue are **wiped** (the new owner reassigns staff) | DELETE + INSERT on `business_venue_access` (composite PK rules out an UPDATE) |

Both flavors are **two-phase**: every offer is a row in `business_transfer_requests` in status `pending` until the recipient explicitly **accepts** or **declines** (or the sender cancels, or it expires). No silent ownership flips.

The row stays in the table forever after it resolves — accepted/declined/cancelled/expired rows are the audit trail.

---

## 2. Data Model

### 2.1 Migration

[`V56__business_transfer_requests.sql`](hangout_api/hangout-gateway/src/main/resources/db/migration/V56__business_transfer_requests.sql)

```sql
CREATE TABLE business_transfer_requests (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transfer_type       VARCHAR(20) NOT NULL,         -- 'BUSINESS' | 'VENUE'
    sender_user_id      UUID NOT NULL REFERENCES users(id),
    target_user_id      UUID NOT NULL REFERENCES users(id),

    -- BUSINESS: the business being handed over
    -- VENUE:    the source business that currently owns the venue
    business_id         UUID NOT NULL REFERENCES business_accounts(id) ON DELETE CASCADE,

    -- VENUE only
    venue_id            UUID REFERENCES venues(id) ON DELETE CASCADE,

    -- VENUE only: which of the target's businesses receives the venue.
    -- NULL at create; set when recipient accepts.
    target_business_id  UUID REFERENCES business_accounts(id),

    status              VARCHAR(20) NOT NULL,         -- pending|accepted|declined|cancelled|expired
    message             TEXT,

    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    responded_at        TIMESTAMPTZ,
    expires_at          TIMESTAMPTZ NOT NULL,

    CONSTRAINT business_transfer_self CHECK (sender_user_id <> target_user_id),
    CONSTRAINT business_transfer_type CHECK (transfer_type IN ('BUSINESS', 'VENUE')),
    CONSTRAINT business_transfer_status CHECK (
        status IN ('pending', 'accepted', 'declined', 'cancelled', 'expired')
    ),
    CONSTRAINT business_transfer_venue_shape CHECK (
        (transfer_type = 'VENUE'    AND venue_id IS NOT NULL)
     OR (transfer_type = 'BUSINESS' AND venue_id IS NULL)
    )
);
```

### 2.2 Indexes

| Index | Purpose |
|---|---|
| `uq_pending_business_transfer (business_id) WHERE status='pending' AND transfer_type='BUSINESS'` | Stops a sender from spamming two pending offers for the same business to different recipients. Partial — non-pending rows free the slot. |
| `uq_pending_venue_transfer (venue_id) WHERE status='pending' AND transfer_type='VENUE'` | Same idea, per venue. |
| `idx_business_transfer_target (target_user_id, status, created_at DESC)` | Inbox listing. |
| `idx_business_transfer_sender (sender_user_id, status, created_at DESC)` | Outbox listing. |
| `idx_business_transfer_expiry (expires_at) WHERE status='pending'` | Drives the hourly expiry sweep. |

> **Why partial unique on (business_id) / (venue_id) instead of full unique?** The row needs to live forever for audit, so multiple historical rows for the same asset are normal — only the in-flight ones can clash.

### 2.3 Entity

[`BusinessTransferRequest.java`](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/business/BusinessTransferRequest.java)

Lazy `@ManyToOne` on sender / target / business / venue / targetBusiness. Status and transferType are `String` (not enums) so the DB CHECK constraint is the source of truth and nobody has to keep two enums in sync.

```java
@Entity
@Table(name = "business_transfer_requests")
public class BusinessTransferRequest {
    @Id @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    private String transferType;            // 'BUSINESS' | 'VENUE'
    private User sender;
    private User target;
    private BusinessAccount business;        // BUSINESS: handed-over; VENUE: source
    private Venue venue;                     // VENUE only
    private BusinessAccount targetBusiness;  // VENUE only, set on accept

    private String status;                   // pending|accepted|declined|cancelled|expired
    private String message;
    private Instant createdAt;
    private Instant respondedAt;
    private Instant expiresAt;
}
```

---

## 3. State Machine

```
                     ┌──────────────┐
                     │              │
                     │   pending    │
                     │              │
                     └──────┬───────┘
                            │
        ┌───────────────────┼───────────────────┬───────────────┐
        │                   │                   │               │
        ▼                   ▼                   ▼               ▼
 ┌────────────┐      ┌────────────┐      ┌────────────┐  ┌────────────┐
 │  accepted  │      │  declined  │      │ cancelled  │  │  expired   │
 │ (recipient)│      │ (recipient)│      │  (sender)  │  │  (sweep)   │
 └────────────┘      └────────────┘      └────────────┘  └────────────┘
```

| Transition | Who | Side-effects |
|---|---|---|
| `created` → `pending` | Sender (POST `/transfers`) | Row inserted with `expires_at = now() + 7 days`. `BUSINESS_TRANSFER_REQUESTED` event emitted. |
| `pending` → `accepted` | Recipient (POST `/transfers/{id}/accept`) | Ownership mutation (see §6). `BUSINESS_TRANSFER_ACCEPTED` event emitted. |
| `pending` → `declined` | Recipient (POST `/transfers/{id}/decline`) | No ownership change. `BUSINESS_TRANSFER_DECLINED` event emitted. |
| `pending` → `cancelled` | Sender (DELETE `/transfers/{id}`) | No ownership change. **No event** — sender already knows, target hadn't acted. |
| `pending` → `expired` | Scheduled sweep | Hourly job flips rows whose `expires_at < now()`. **No event** — silent. |

All terminal states free the partial-unique-index slot, so the sender can re-initiate a new offer for the same asset.

---

## 4. REST Surface

All endpoints live under `/api/v1/business/transfers` and require `@PreAuthorize("hasRole('USER')")`. **Fine-grained authorization is enforced inside the service**, not via authorities — business ownership lives in row data (`business_accounts.user_id`), not granted roles.

[`BusinessTransferController.java`](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/controller/BusinessTransferController.java)

| Method | Path | Body | Description |
|---|---|---|---|
| `POST` | `/transfers` | `CreateBusinessTransferRequest` | Create a pending offer. **Sender must own** `businessId`. |
| `GET` | `/transfers/incoming?status=pending&page=0&size=20` | — | Inbox: offers addressed to the caller. |
| `GET` | `/transfers/outgoing?status=pending&page=0&size=20` | — | Outbox: offers the caller sent. |
| `POST` | `/transfers/{transferId}/accept` | `AcceptBusinessTransferRequest` (optional; required for VENUE) | Recipient accepts. Triggers the ownership mutation. |
| `POST` | `/transfers/{transferId}/decline` | — | Recipient declines. |
| `DELETE` | `/transfers/{transferId}` | — | Sender cancels. |

### 4.1 Request DTOs

[`CreateBusinessTransferRequest`](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/dto/request/CreateBusinessTransferRequest.java)

```java
public record CreateBusinessTransferRequest(
        @NotBlank @Pattern(regexp = "BUSINESS|VENUE") String transferType,
        @NotNull UUID targetUserId,
        @NotNull UUID businessId,
        UUID venueId,                              // required iff transferType=VENUE
        @Size(max = 1000) String message) {}
```

[`AcceptBusinessTransferRequest`](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/dto/request/AcceptBusinessTransferRequest.java)

```java
public record AcceptBusinessTransferRequest(
        UUID targetBusinessId) {}   // required for VENUE; ignored for BUSINESS
```

> **Why `targetBusinessId` is recipient-supplied, not sender-supplied:** the sender doesn't have visibility into the recipient's internal business list. If the recipient has exactly one business the client can auto-fill; if they have several it surfaces a picker.

### 4.2 Response DTO

[`BusinessTransferResponse`](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/dto/response/BusinessTransferResponse.java) — server-side projection used by create / listings / accept / decline / cancel responses so the client always gets the final row state in one round-trip.

```java
public record BusinessTransferResponse(
        UUID id,
        String transferType, String status,
        UUID senderUserId, String senderUsername,
        UUID targetUserId, String targetUsername,
        UUID businessId,   String businessName,
        UUID venueId,      String venueNameAr, String venueNameEn,   // VENUE only
        UUID targetBusinessId, String targetBusinessName,            // VENUE, post-accept only
        String message,
        Instant createdAt, Instant respondedAt, Instant expiresAt) {}
```

---

## 5. Authority & Guards

Endpoint-level: `hasRole('USER')` only — broad and intentional.

Service-level guards (in [`BusinessTransferServiceImpl`](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/service/impl/BusinessTransferServiceImpl.java)):

| Action | Guard |
|---|---|
| `create` | `senderUserId ≠ targetUserId`; target must be active, not banned, not deleted; sender must currently own `business.user_id`; for VENUE the venue must currently sit in `business_venue_access` under the source business; no other `pending` row exists for this asset by this sender |
| `accept` | Row exists, status is `pending`, `expires_at > now()`, caller is `row.target` |
| `accept` (VENUE) | `targetBusinessId` is non-null and owned by `row.target`; source business still owns the venue (re-validated under lock) |
| `accept` (BUSINESS) | Sender **still** owns the business (re-validated under lock — they could have moved it during the pending window) |
| `decline` | Status pending, not expired, caller is `row.target` |
| `cancel` | Status pending, not expired, caller is `row.sender` |

The double pending-check in `create` (in-app filter + partial unique index) is intentional: the index is the safety net, the in-app check produces a friendlier 409 with a human message instead of a constraint-violation 500.

---

## 6. Accept-Side Mechanics

This is the only mutating path — every other transition only flips the row's `status` + `responded_at`. Both branches run inside one `@Transactional` method, behind a `PESSIMISTIC_WRITE` lock on the transfer row ([`findByIdForUpdate`](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/business/BusinessTransferRequestRepository.java)) so two concurrent accepts on the same offer can't both apply.

### 6.1 BUSINESS branch — `applyBusinessTransfer`

```java
// Re-validate the sender still owns the business — they could have
// transferred it elsewhere during the pending window.
if (!business.getUser().getId().equals(row.getSender().getId())) {
    throw new BusinessException("The sender no longer owns this business");
}
business.setUser(row.getTarget());
businessRepository.save(business);
return List.of();                  // no fired-staff list for BUSINESS
```

That's the entire mutation — one column update. Everything that hangs off the business (venues via `business_venue_access`, content on those venues, etc.) follows automatically because nothing else references the previous owner's user id.

Staff carry over with the business owner change — `user_venue_roles` rows are not touched.

### 6.2 VENUE branch — `applyVenueTransfer`

The venue moves between two `business_accounts` rows. Since `business_venue_access` has a composite primary key `(business_id, venue_id)`, an UPDATE of `business_id` is off the table — we **DELETE + INSERT**.

```java
// 1. Validate the target business actually belongs to the recipient.
BusinessAccount targetBusiness = businessRepository.findById(request.targetBusinessId())
        .orElseThrow(...);
if (!targetBusiness.getUser().getId().equals(row.getTarget().getId())) {
    throw new BusinessException("You do not own the target business");
}

// 2. Re-validate the venue still sits in the source business — it could
//    have moved or the source business itself could have changed hands.
BusinessVenueAccess oldAccess = businessVenueAccessRepository
        .findById(new BusinessVenueId(sourceBusiness.getId(), venue.getId()))
        .orElseThrow(() -> new BusinessException(
                "This venue no longer belongs to the source business"));

// 3. Capture all staff with roles on this venue, then nuke their roles.
List<UUID> firedStaffIds = userVenueRoleRepository.findAllByVenueId(venue.getId())
        .stream().map(uvr -> uvr.getUser().getId()).distinct().toList();
userVenueRoleRepository.deleteAllByVenueId(venue.getId());

// 4. DELETE + INSERT on business_venue_access (composite PK rules out UPDATE).
businessVenueAccessRepository.delete(oldAccess);
businessVenueAccessRepository.flush();
businessVenueAccessRepository.save(BusinessVenueAccess.builder()
        .id(new BusinessVenueId(targetBusiness.getId(), venue.getId()))
        .business(targetBusiness)
        .venue(venue)
        .role(oldAccess.getRole())   // preserve the role that the access row carried
        .build());

row.setTargetBusiness(targetBusiness);
return firedStaffIds;                 // returned upstream so the event can fan out
```

Why the `flush()` between delete and save: same composite PK, same transaction — without an explicit flush, Hibernate could reorder the insert before the delete and the new row would collide with the still-resident old row.

After this:
- The venue's content (posts, memories, hangouts, reviews) is untouched — those rows reference `venue_id`, not the business.
- Existing staff lose access silently from a permissions standpoint, but they get an explicit `BUSINESS_TRANSFER_STAFF_REVOKED` push so the drop isn't mysterious (see §8).
- The new owner inherits an empty staff slate and reassigns from their own people.

---

## 7. Kafka Events

[`KafkaConfig`](hangout_api/hangout-infrastructure/src/main/java/com/beestar/hangout/infrastructure/config/KafkaConfig.java) defines three topics, 3 partitions, 1 replica:

| Constant | Topic |
|---|---|
| `BUSINESS_TRANSFER_REQUESTED` | `hangout.business.transfer.requested` |
| `BUSINESS_TRANSFER_ACCEPTED`  | `hangout.business.transfer.accepted` |
| `BUSINESS_TRANSFER_DECLINED`  | `hangout.business.transfer.declined` |

> **No event on `cancelled` or `expired`.** Sender already knows they cancelled; target never acted; nobody needs a push.

All events are published via `OutboxEventPublisher` (Kafka outbox pattern) so a slow broker can't roll back the DB transaction.

### 7.1 Requested

```java
BusinessTransferRequestedEvent(
    UUID transferId, String transferType,
    UUID senderUserId, UUID targetUserId,
    UUID businessId,  String businessName,
    UUID venueId, String venueNameAr, String venueNameEn)   // venue fields null for BUSINESS
```

### 7.2 Accepted

```java
BusinessTransferAcceptedEvent(
    UUID transferId, String transferType,
    UUID oldOwnerId, UUID newOwnerId,
    UUID businessId, String businessName,
    UUID venueId,    String venueNameAr, String venueNameEn,
    List<UUID> firedStaffUserIds)    // always empty for BUSINESS
```

`firedStaffUserIds` is the workhorse — captured inside the same transaction that wiped the roles, so the notification consumer can fan out a "your access was revoked" push to each affected user without re-querying the (now-deleted) role rows.

### 7.3 Declined

```java
BusinessTransferDeclinedEvent(
    UUID transferId, String transferType,
    UUID senderUserId, UUID targetUserId,
    UUID businessId, String businessName,
    UUID venueId,    String venueNameAr, String venueNameEn)
```

---

## 8. Push Notifications

Consumed by [`KafkaNotificationConsumer`](hangout_api/hangout-notification/src/main/java/com/beestar/hangout/notification/consumer/KafkaNotificationConsumer.java) (3 @KafkaListener methods, ~lines 845–982). Every push also writes a `Notification` row (in-app inbox).

| Event | Recipient(s) | `type` | Deep link |
|---|---|---|---|
| `BUSINESS_TRANSFER_REQUESTED` | `target` (the offered-to user) | `BUSINESS_TRANSFER_REQUESTED` | `hangout://business/transfers/incoming` |
| `BUSINESS_TRANSFER_ACCEPTED` | `oldOwner` (sender) | `BUSINESS_TRANSFER_ACCEPTED` | `hangout://business/transfers/outgoing` |
| `BUSINESS_TRANSFER_ACCEPTED` (VENUE only) | each `firedStaffUserIds` (except old/new owner) | `BUSINESS_TRANSFER_STAFF_REVOKED` | `hangout://home` |
| `BUSINESS_TRANSFER_DECLINED` | `sender` | `BUSINESS_TRANSFER_DECLINED` | `hangout://business/transfers/outgoing` |

Push titles/bodies are AR + EN. The label used in the body is the venue name (VENUE) or business `companyName` (BUSINESS) so the recipient knows which asset is at stake without opening the app.

Fired-staff exclusions: if the staff user id happens to be either `oldOwner` or `newOwner` they don't get the staff-revoked push — old owner already got the accept ack; new owner doesn't need a "you lost access" push for a venue they just received.

---

## 9. Expiry Sweep

[`BusinessTransferExpirySweeper`](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/scheduler/BusinessTransferExpirySweeper.java) runs **hourly** (`@Scheduled(fixedRate = 3_600_000L)`) and bulk-flips past-expiry pending rows:

```java
@Modifying
@Query("""
        UPDATE BusinessTransferRequest t
        SET t.status = 'expired',
            t.respondedAt = :now
        WHERE t.status = 'pending'
          AND t.expiresAt < :now
        """)
int expirePending(@Param("now") Instant now);
```

**Why the sweep exists at all** — couldn't the inbox just filter past-expiry rows client-side? The partial unique indexes on `(business_id)` / `(venue_id)` only treat `status = 'pending'` rows as in-flight. A stale pending row past its expiry would block the sender from re-initiating a new transfer for the same asset. The sweep frees the slot.

EXPIRY_DAYS = 7 (constant in service impl).

No event is emitted on expiry — neither side acted, and the asset state is unchanged.

---

## 10. Concurrency & Race Conditions

| Race | How it's handled |
|---|---|
| Two concurrent accepts on the same offer | `PESSIMISTIC_WRITE` lock on the transfer row via `findByIdForUpdate`. Loser sees `status='accepted'` on its re-read and errors cleanly with "Transfer is not pending". |
| Sender creates two pending offers for the same business/venue to different recipients | In-app check (friendlier 409) backed by partial unique index (hard guarantee). |
| Sender transfers the business elsewhere while a pending offer is in flight | Accept-side re-validates `business.user == sender`. If broken, the accept fails with "The sender no longer owns this business". |
| Source business moves the venue away while a pending VENUE offer is in flight | Accept-side re-validates `business_venue_access(sourceBusiness, venue)` exists. If gone, accept fails with "This venue no longer belongs to the source business". |
| Recipient tries to accept into a business they don't own | `targetBusiness.user == row.target` re-checked at accept time. |
| Expiry crosses the boundary during an in-flight accept | `assertPending` checks `expiresAt > now()` after acquiring the lock; if the row aged out it errors with "Transfer has expired" — the sweep can be a no-op for this row, no double mutation. |
| `business_venue_access` composite-PK collision on DELETE + INSERT | Explicit `flush()` between delete and save forces Hibernate to flush the delete to the DB before the insert is buffered. |

---

## 11. Error Responses

| Condition | HTTP | Message |
|---|---|---|
| `transferType` not BUSINESS/VENUE | 400 | "transferType must be BUSINESS or VENUE" |
| VENUE without `venueId` | 400 | "venueId is required for VENUE transfers" |
| BUSINESS with `venueId` | 400 | "venueId must be null for BUSINESS transfers" |
| Self-transfer | 400 | "Cannot transfer to yourself" |
| Target inactive/banned/deleted | 400 | "Target user cannot receive transfers" |
| Sender doesn't own the business | 400 | "You do not own this business" |
| Venue isn't in the source business | 400 | "This venue does not belong to the source business" |
| Pending offer already exists for asset | 409 | "A pending transfer already exists for this business/venue" |
| Transfer not found | 404 | "Transfer not found" |
| Wrong caller for action | 400 | "This transfer is not addressed to you" / "Only the sender can cancel this transfer" |
| Already resolved | 400 | "Transfer is not pending (status: …)" |
| Past expiry | 400 | "Transfer has expired" |
| Accept VENUE without `targetBusinessId` | 400 | "targetBusinessId is required for VENUE transfers" |
| Accept VENUE into someone else's business | 400 | "You do not own the target business" |
| Sender lost ownership during pending window | 400 | "The sender no longer owns this business" |
| Venue moved during pending window | 400 | "This venue no longer belongs to the source business" |

---

## 12. Admin Override (Force Transfer)

Super-admins can bypass the two-phase request flow entirely and rewrite ownership immediately. The mutation, audit log, and notification fan-out all happen in one `@Transactional` boundary — no row in `business_transfer_requests` is involved.

### 12.1 When to use

Operator-driven scenarios where consent isn't available or appropriate:
- Owner account is banned/locked and the business needs to be reassigned.
- Resolving a dispute where the rightful owner can't access the originating account.
- Bulk migrations during a platform restructure.
- Internal QA / parked ownership before review.

### 12.2 Endpoints

| Method | Path | Authority | Body |
|---|---|---|---|
| `POST` | `/api/v1/admin/businesses/{businessId}/force-transfer` | `admin:businesses:manage` | `ForceBusinessTransferRequest` |
| `POST` | `/api/v1/admin/venues/{venueId}/force-transfer` | `admin:venues:manage` | `ForceVenueTransferRequest` |

No new permissions were introduced — these reuse the existing operator-level authorities that already gate tier flips and similar business/venue mutations.

### 12.3 Request DTOs

[`ForceBusinessTransferRequest`](hangout_api/hangout-admin/src/main/java/com/beestar/hangout/admin/dto/request/ForceBusinessTransferRequest.java)

```java
public record ForceBusinessTransferRequest(
        @NotNull UUID targetUserId,
        @NotBlank @Size(max = 500) String reason) {}
```

[`ForceVenueTransferRequest`](hangout_api/hangout-admin/src/main/java/com/beestar/hangout/admin/dto/request/ForceVenueTransferRequest.java)

```java
public record ForceVenueTransferRequest(
        @NotNull UUID targetBusinessId,
        @NotBlank @Size(max = 500) String reason) {}
```

`reason` is required on both — it lands in `admin_audit_log.details` and is also included on the outgoing Kafka event. Every force transfer leaves a written justification behind.

For VENUE, the admin specifies the **target business** (not target user). The new owner is implicitly whoever currently owns that business. This keeps the API symmetrical with the user-driven `accept` flow (where the recipient picks one of *their* businesses) and avoids the admin needing to know the recipient's internal business list.

### 12.4 Mutation Logic

Implemented in [`AdminBusinessTransferServiceImpl`](hangout_api/hangout-admin/src/main/java/com/beestar/hangout/admin/service/impl/AdminBusinessTransferServiceImpl.java) — mirrors the user-driven accept path step-for-step:

| Flavor | Mutation |
|---|---|
| **BUSINESS** | `business.user ← targetUser`; one row update. No staff role changes. |
| **VENUE** | Snapshot `user_venue_roles` for the venue → `deleteAllByVenueId(venue.id)` → delete `business_venue_access(sourceBusiness, venue)` → flush → insert `business_venue_access(targetBusiness, venue)` preserving the original role. |

Differences from the user-driven path:

- **No re-validation of sender ownership.** The admin is the actor; they don't need to currently own the asset (which is the whole point — the original owner may be locked out).
- **No target-user active/banned check.** Operators sometimes need to park ownership onto a deliberately inactive account before review.
- **No row in `business_transfer_requests`.** The audit trail lives in `admin_audit_log` instead, so admin-driven changes don't pollute users' inboxes/outboxes with offers they never created.

### 12.5 Audit Log

Every force transfer writes one [`AdminAuditLog`](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/admin/AdminAuditLog.java) row:

| Column | Value |
|---|---|
| `admin_id` | The acting admin (from `AdminPrincipal.adminId`) |
| `action` | `BUSINESS_TRANSFER_FORCE` or `VENUE_TRANSFER_FORCE` |
| `entity_type` | `BUSINESS_ACCOUNT` or `VENUE` |
| `entity_id` | The business or venue id |
| `details` (jsonb) | `{transferType, oldOwnerId, newOwnerId, sourceBusinessId, targetBusinessId, firedStaffUserIds, reason, ...}` |
| `created_at` | Auto |

This is the **only** persistent record of an admin-forced transfer — no row in `business_transfer_requests` is created.

### 12.6 Kafka Event & Notifications

Topic: [`hangout.business.transfer.forced`](hangout_api/hangout-infrastructure/src/main/java/com/beestar/hangout/infrastructure/config/KafkaConfig.java) (3 partitions, 1 replica). Event: [`BusinessTransferForcedEvent`](hangout_api/hangout-common/src/main/java/com/beestar/hangout/common/event/BusinessTransferForcedEvent.java)

```java
public record BusinessTransferForcedEvent(
        UUID adminId,
        String transferType,
        UUID oldOwnerId, UUID newOwnerId,
        UUID businessId, String businessName,
        UUID venueId, String venueNameAr, String venueNameEn,
        List<UUID> firedStaffUserIds,
        String reason) {}
```

Consumed by [`KafkaNotificationConsumer.onBusinessTransferForced`](hangout_api/hangout-notification/src/main/java/com/beestar/hangout/notification/consumer/KafkaNotificationConsumer.java). Three potential pushes per event:

| Recipient | Type | Push body (EN) |
|---|---|---|
| Old owner | `BUSINESS_TRANSFER_FORCED_OUT` | "X was transferred to a new owner by an administrator" |
| New owner | `BUSINESS_TRANSFER_FORCED_IN` | "X was transferred to you by an administrator" |
| Each former staff (VENUE only) | `BUSINESS_TRANSFER_STAFF_REVOKED` | "X was transferred to a new owner and you no longer have access" |

The admin-flavored copy is intentional — "transferred by an administrator" is different from "X accepted your transfer", and users deserve to know the difference. Same `BUSINESS_TRANSFER_STAFF_REVOKED` type is reused for fired staff since the user-facing effect is identical.

### 12.7 Error Responses

| Condition | HTTP | Message |
|---|---|---|
| Admin not found | 404 | "Admin not found" |
| Business not found | 404 | "Business not found" |
| Venue not found | 404 | "Venue not found" |
| Target user not found | 404 | "Target user not found" |
| Target business not found | 404 | "Target business not found" |
| BUSINESS: target already owns it | 400 | "Target user already owns this business" |
| VENUE: target business already owns it | 400 | "Target business already owns this venue" |
| VENUE: venue not attached to any business | 400 | "Venue is not attached to any business" |
| Missing `reason` | 400 | Bean-validation message |

### 12.8 Concurrency

A force transfer holds no explicit row lock on the asset, but it runs inside a single `@Transactional` boundary so:
- A concurrent user-driven accept on the same asset can race with the force — the loser sees a stale ownership read on commit and one of the two transactions rolls back at FK / unique-constraint level.
- In practice this race is vanishingly rare (admin tooling is operator-driven, not high-throughput) and the audit log + event still record whichever mutation won.

If serializability becomes a concern later, add a pessimistic-write lock on the `business_accounts` (or `business_venue_access`) row at the top of each method.

---

## 13. File Index

| File | Role |
|---|---|
| [V56__business_transfer_requests.sql](hangout_api/hangout-gateway/src/main/resources/db/migration/V56__business_transfer_requests.sql) | Schema, CHECK constraints, partial unique indexes |
| [BusinessTransferRequest.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/entity/business/BusinessTransferRequest.java) | JPA entity |
| [BusinessTransferRequestRepository.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/business/BusinessTransferRequestRepository.java) | Inbox/outbox queries, `findByIdForUpdate`, `expirePending` |
| [CreateBusinessTransferRequest.java](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/dto/request/CreateBusinessTransferRequest.java) | Create payload |
| [AcceptBusinessTransferRequest.java](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/dto/request/AcceptBusinessTransferRequest.java) | Accept payload |
| [BusinessTransferResponse.java](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/dto/response/BusinessTransferResponse.java) | Response projection |
| [BusinessTransferService.java](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/service/BusinessTransferService.java) | Interface |
| [BusinessTransferServiceImpl.java](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/service/impl/BusinessTransferServiceImpl.java) | Create / accept / decline / cancel / listings — all guards and mutations |
| [BusinessTransferController.java](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/controller/BusinessTransferController.java) | REST surface |
| [BusinessTransferExpirySweeper.java](hangout_api/hangout-business/src/main/java/com/beestar/hangout/business/scheduler/BusinessTransferExpirySweeper.java) | Hourly expiry job |
| [BusinessTransferRequestedEvent.java](hangout_api/hangout-common/src/main/java/com/beestar/hangout/common/event/BusinessTransferRequestedEvent.java) | Kafka event — create |
| [BusinessTransferAcceptedEvent.java](hangout_api/hangout-common/src/main/java/com/beestar/hangout/common/event/BusinessTransferAcceptedEvent.java) | Kafka event — accept (carries `firedStaffUserIds`) |
| [BusinessTransferDeclinedEvent.java](hangout_api/hangout-common/src/main/java/com/beestar/hangout/common/event/BusinessTransferDeclinedEvent.java) | Kafka event — decline |
| [BusinessTransferForcedEvent.java](hangout_api/hangout-common/src/main/java/com/beestar/hangout/common/event/BusinessTransferForcedEvent.java) | Kafka event — admin force |
| [KafkaConfig.java](hangout_api/hangout-infrastructure/src/main/java/com/beestar/hangout/infrastructure/config/KafkaConfig.java) | Topic registrations (3 partitions, 1 replica each) |
| [KafkaNotificationConsumer.java](hangout_api/hangout-notification/src/main/java/com/beestar/hangout/notification/consumer/KafkaNotificationConsumer.java) | Four @KafkaListener methods that turn transfer events into Notification rows + FCM pushes |
| [ForceBusinessTransferRequest.java](hangout_api/hangout-admin/src/main/java/com/beestar/hangout/admin/dto/request/ForceBusinessTransferRequest.java) | Admin BUSINESS force payload |
| [ForceVenueTransferRequest.java](hangout_api/hangout-admin/src/main/java/com/beestar/hangout/admin/dto/request/ForceVenueTransferRequest.java) | Admin VENUE force payload |
| [ForceTransferResponse.java](hangout_api/hangout-admin/src/main/java/com/beestar/hangout/admin/dto/response/ForceTransferResponse.java) | Admin force response |
| [AdminBusinessTransferService.java](hangout_api/hangout-admin/src/main/java/com/beestar/hangout/admin/service/AdminBusinessTransferService.java) | Admin override interface |
| [AdminBusinessTransferServiceImpl.java](hangout_api/hangout-admin/src/main/java/com/beestar/hangout/admin/service/impl/AdminBusinessTransferServiceImpl.java) | Admin override impl — mutation + audit + event |
| [AdminBusinessTransferController.java](hangout_api/hangout-admin/src/main/java/com/beestar/hangout/admin/controller/AdminBusinessTransferController.java) | Admin REST surface |

---

## 14. Quick Reference: End-to-End BUSINESS Transfer

1. Owner A holds business `B1`. Owner B has account but no relationship to `B1`.
2. **A** → `POST /api/v1/business/transfers` `{transferType: "BUSINESS", targetUserId: B, businessId: B1, message: "yours"}`. Row inserted `pending`, expires in 7d.
3. Kafka → notification → **B** gets push "A offered to transfer B1 to you" → tap → inbox.
4. **B** → `POST /api/v1/business/transfers/{id}/accept` (no body needed). Inside the transaction: row locked, sender re-validated as owner, `business_accounts.user_id ← B`, row → `accepted`.
5. Kafka → notification → **A** gets push "B accepted the transfer of B1".
6. Done — every venue/staff/post under `B1` is now under **B**'s account.

## 15. Quick Reference: End-to-End VENUE Transfer

1. Owner A has business `B1` with venue `V1` (and staff with roles on `V1`). Owner B has businesses `B2`, `B3`.
2. **A** → `POST /api/v1/business/transfers` `{transferType: "VENUE", targetUserId: B, businessId: B1, venueId: V1}`.
3. Kafka → **B** gets push → opens inbox.
4. **B** picks `B2` as the receiving business → `POST .../accept {targetBusinessId: B2}`. Inside the transaction: row locked → re-validate V1 still in B1 → snapshot `user_venue_roles` for V1 → delete those rows → delete `business_venue_access(B1, V1)` → flush → insert `business_venue_access(B2, V1)` with the same role → row → `accepted`.
5. Kafka → **A** gets push "B accepted the transfer of V1"; every former staff member of V1 gets "Access Revoked: V1 was transferred".
6. V1 now sits under B2; its posts/memories/hangouts/reviews are untouched; **B** assigns fresh staff.
