# Product Orders Flow — End-to-End Guide

A complete walkthrough of the product-post + ordering feature on the Spring Boot backend (`hangout_api/`) and the Flutter client (`hangout_app/`). Covers the data model, lifecycle, REST surface, Kafka events, push notifications, and client integration.

---

## 1. Concept

A **product post** is a venue-authored post that's marked purchasable and given a price. Users see an **Order** CTA in feed; tapping it places an **order** against that product. Orders ride through a small state machine, and every order carries a scoped **inquiry chat** that locks (read-only) when the order closes.

Two distinct things were added:

| Thing | What it is | Lives in |
|---|---|---|
| **Product post** | A regular venue-authored post with `is_product=true` and a `price`. Still appears in feeds, reels, search. | `posts.is_product`, `posts.price` |
| **Order** | A user's request to buy one unit of a product post. Has a lifecycle, snapshotted price, and an inquiry thread. | `product_orders`, `order_messages` |

Currency is always **IQD** (Iraqi Dinar). The currency code ships in every response (`priceCurrency: "IQD"`) so clients don't infer it by region.

There is **no payment integration** — money changes hands off-platform. The order is an *intent + acknowledgement* surface. The venue marks **delivered** once the customer has received the product and paid.

---

## 2. Data Model

### 2.1 Tables (V72 migration)

```
posts (existing — additions only)
├── is_product   BOOLEAN NOT NULL DEFAULT false
├── price        NUMERIC(12, 2)        — IQD; required iff is_product
└── CHECK posts_price_required_when_product   (NOT is_product OR price IS NOT NULL)
    CHECK posts_no_price_when_not_product     (is_product OR price IS NULL)

product_orders                               (one row per order)
├── id                       UUID PK
├── user_id                  FK users(id) ON DELETE CASCADE
├── venue_id                 FK venues(id) ON DELETE CASCADE
├── post_id                  FK posts(id) ON DELETE CASCADE
├── price_snapshot           NUMERIC(12, 2) NOT NULL   — frozen at creation
├── status                   VARCHAR(20) NOT NULL DEFAULT 'PENDING'
│                            CHECK status IN ('PENDING','ACCEPTED','REJECTED','CANCELLED','DELIVERED')
├── created_at               TIMESTAMPTZ NOT NULL
├── responded_at             TIMESTAMPTZ              — when venue ACCEPTED/REJECTED
├── responded_by_user_id     FK users(id)
├── delivered_at             TIMESTAMPTZ
├── delivered_by_user_id     FK users(id)
├── cancelled_at             TIMESTAMPTZ
└── cancelled_by_user_id     FK users(id)             — tells customer-cancel from venue-cancel

order_messages                               (inquiry thread, one row per message)
├── id              UUID PK
├── order_id        FK product_orders(id) ON DELETE CASCADE
├── sender_user_id  FK users(id)
├── sender_role     VARCHAR(20) NOT NULL    — 'CUSTOMER' | 'VENUE'
├── body            TEXT NOT NULL           — CHECK LENGTH BETWEEN 1 AND 1000
├── created_at      TIMESTAMPTZ NOT NULL
└── read_at         TIMESTAMPTZ             — when the OTHER party first opened/marked read
```

### 2.2 Indexes (cost of each query)

| Index | Use case |
|---|---|
| `idx_product_orders_venue_status_created (venue_id, status, created_at DESC)` | Venue inbox by status |
| `idx_product_orders_user_created (user_id, created_at DESC)` | "My orders" history |
| `idx_product_orders_post_created (post_id, created_at DESC)` | Per-post analytics |
| `uq_product_orders_open_per_user_post (user_id, post_id) WHERE status IN ('PENDING','ACCEPTED')` | Anti-double-order — partial unique |
| `idx_order_messages_order_created (order_id, created_at)` | Thread render |
| `idx_order_messages_order_unread (order_id) WHERE read_at IS NULL` | Unread badge |

### 2.3 Why `sender_role` is stored

We store it explicitly rather than deriving from `users → venue_access` at read time. Two reasons:

1. **Stable history** — if venue staff lose their role later, their old messages still render as "from the venue."
2. **No join per message** — render queries don't have to consult `business_venue_access` to label each row.

### 2.4 Why `price_snapshot` is frozen

A venue editing the post's `price` after an order is placed shouldn't change the agreed amount. The snapshot is the contract; the post's current price is just the default for new orders.

---

## 3. Lifecycle

```
                    ┌──────────────┐
                    │   PENDING    │  ← user created
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
      venue accepts   venue rejects   user cancels
              │            │            │
              ▼            ▼            ▼
      ┌──────────────┐  ┌──────────────┐
      │   ACCEPTED   │  │   REJECTED   │  ← terminal; chat locks
      └──────┬───────┘  └──────────────┘
             │
   ┌─────────┼──────────┐
   ▼         ▼          ▼
venue     either    venue
delivers  cancels   cancels
   │         │          │
   ▼         ▼          ▼
┌──────────────┐  ┌──────────────┐
│  DELIVERED   │  │  CANCELLED   │  ← terminal; chat locks
└──────────────┘  └──────────────┘
```

**Terminal states** (`DELIVERED`, `REJECTED`, `CANCELLED`): no further transitions; inquiry chat is read-only.

**Open states** (`PENDING`, `ACCEPTED`): chat accepts new messages; transitions still allowed.

**Cancellation rules:**
- `PENDING`: either side can cancel/reject freely.
- `ACCEPTED`: either side can cancel — audited via `cancelled_by_user_id`.
- `DELIVERED`: no cancellation. (Support handles disputes off-platform.)

**Who marks DELIVERED:** the **venue**. They're the ones receiving payment and handing over the product. The customer cannot mark delivered on-platform in v1.

---

## 4. Permissions (RBAC)

V72 adds one new permission:

```
venue:orders:manage   "View and respond to product orders for a venue"
```

Granted to:
- **owner** role
- **manager** role
- **staff** role  ← front-of-house customer service

Users (customers) don't need a special permission to *place* orders — the `@PreAuthorize("hasRole('USER')")` check on the customer-side endpoints is sufficient. The "you can't order from your own venue" rule is enforced in service code via `venueAccessService.hasVenueAccess(callerId, venueId)`.

---

## 5. Backend REST Surface

### 5.1 Customer side — `/api/v1/orders`

All require an authenticated `USER` JWT.

| Method | Path | Action |
|---|---|---|
| POST | `/api/v1/orders` | Create order `{postId, note?}` — returns 201 + `OrderResponse` |
| GET | `/api/v1/orders/me?status=...&page=...&size=...` | My orders, newest first, paginated |
| GET | `/api/v1/orders/{id}` | Order detail + full inquiry thread |
| POST | `/api/v1/orders/{id}/cancel` | Cancel my own — only while PENDING/ACCEPTED |
| POST | `/api/v1/orders/{id}/messages` | Send inquiry `{body}` — 400 if chat is locked |
| POST | `/api/v1/orders/{id}/messages/read` | Mark thread read; returns 204 |

The detail endpoint (`GET /api/v1/orders/{id}`) is **auth-aware** — the same path serves the venue side too. The controller delegates to `OrderService.getOrder(callerId, orderId)`, which returns the order iff the caller is the customer OR has venue access. Foreign callers get **404** (not 403) so existence isn't leaked.

### 5.2 Venue side — `/api/v1/business/venues/{venueId}/orders`

All require `venue:orders:manage` + venue access verified internally.

| Method | Path | Action |
|---|---|---|
| GET | `.../orders?status=...&page=...&size=...` | Venue inbox |
| GET | `.../orders/{orderId}` | Order detail |
| POST | `.../orders/{orderId}/accept` | PENDING → ACCEPTED |
| POST | `.../orders/{orderId}/reject` | PENDING → REJECTED (terminal) |
| POST | `.../orders/{orderId}/deliver` | ACCEPTED → DELIVERED (terminal; locks chat) |
| POST | `.../orders/{orderId}/cancel` | Cancel from venue side |
| POST | `.../orders/{orderId}/messages` | Send inquiry as venue |
| POST | `.../orders/{orderId}/messages/read` | Mark thread read; returns 204 |

### 5.3 Validation rules enforced server-side

| Rule | Where |
|---|---|
| Only venue-authored posts can be products | `PostServiceImpl.createPost` — rejects user posts with `isProduct=true` |
| `price` required iff `isProduct=true` | Java + DB CHECK |
| Can only order an `is_product=true && active && !hidden` post | `OrderServiceImpl.createOrder` |
| Can't order from a venue where you have staff access | `OrderServiceImpl.createOrder` (anti-self-order) |
| One open order per `(user, post)` | Partial unique index + service-level pre-check |
| State transitions strictly enforced | Each `*Order` service method gates by current status |
| Chat read-only when order is terminal | `OrderServiceImpl.sendMessage` |

### 5.4 Response shapes

**`PostResponse`** (existing — additions): `isProduct: bool`, `price: BigDecimal?`, `priceCurrency: "IQD"?`.

**`OrderResponse`** — full detail:
```
{
  id, status, inquiryLocked,
  price, priceCurrency,
  product: { postId, caption, mediaUrl, mediaType, currentPrice },
  venue:   { id, handle, nameAr, nameEn, logoUrl, phone },
  customer:{ id, username, displayName, avatarUrl },
  createdAt, respondedAt, deliveredAt, cancelledAt,
  messages: [ OrderMessageResponse... ],
  unreadMessageCount
}
```

**`OrderMessageResponse`** — `{ id, senderUserId, senderRole, body, createdAt, readAt }`.

**`OrderSummaryResponse`** — lean shape for list views; omits `messages` and the nested product/venue/customer objects in favor of flat fields the list cell renders directly.

---

## 6. Kafka Events + Push Notifications

### 6.1 Topics

| Topic | When fired | Payload |
|---|---|---|
| `hangout.order.created` | After `createOrder` persists | `OrderCreatedEvent(orderId, venueId, postId, customerId)` |
| `hangout.order.status.changed` | After any transition (ACCEPTED/REJECTED/DELIVERED/CANCELLED) | `OrderStatusChangedEvent(orderId, venueId, customerId, newStatus, actorUserId)` |
| `hangout.order.message.sent` | After `sendMessage` persists | `OrderMessageSentEvent(messageId, orderId, venueId, customerId, senderUserId, senderRole)` |

All published via the existing `OutboxEventPublisher` (transactional outbox pattern — events fire only after the surrounding tx commits).

### 6.2 Consumer routing (KafkaNotificationConsumer)

The notification consumer creates a `Notification` row and sends an FCM push:

| Event | Recipient | Notification type |
|---|---|---|
| `ORDER_CREATED` | Venue owner | `ORDER_CREATED` |
| `ORDER_STATUS_CHANGED` (ACCEPTED) | Customer | `ORDER_ACCEPTED` |
| `ORDER_STATUS_CHANGED` (REJECTED) | Customer | `ORDER_REJECTED` |
| `ORDER_STATUS_CHANGED` (DELIVERED) | Customer | `ORDER_DELIVERED` |
| `ORDER_STATUS_CHANGED` (CANCELLED) | The side that **didn't** cancel | `ORDER_CANCELLED` |
| `ORDER_MESSAGE_SENT` (sender=CUSTOMER) | Venue owner | `ORDER_MESSAGE` |
| `ORDER_MESSAGE_SENT` (sender=VENUE) | Customer | `ORDER_MESSAGE` |

Notification text is bilingual (Ar + En). Deep links:
- Customer-side notifications: `hangout://orders/{orderId}`
- Venue-side notifications: `hangout://business/orders/{orderId}`

### 6.3 Venue notifications fan-out

Today the venue-side handlers route to the **business owner** (matches the existing `VENUE_FOLLOWED` pattern). Fan-out to all staff with `venue:orders:manage` is straightforward when there's a UX need — change `accesses.get(0).getBusiness().getUser()` to a list iteration in `KafkaNotificationConsumer.onOrderCreated` / `onOrderStatusChanged` / `onOrderMessageSent`.

---

## 7. Flutter Integration

### 7.1 New DTOs (`hangout_app/lib/domain/dto/`)

**Requests:**
- [`create_order_request.dart`](hangout_app/lib/domain/dto/request/create_order_request.dart) — `CreateOrderRequest { postId, note? }`
- [`send_order_message_request.dart`](hangout_app/lib/domain/dto/request/send_order_message_request.dart) — `SendOrderMessageRequest { body }`

**Responses (one file):**
- [`order_response.dart`](hangout_app/lib/domain/dto/response/order_response.dart) — contains:
  - `OrderStatus` enum (`pending`, `accepted`, `rejected`, `cancelled`, `delivered`) with `@JsonValue` mapping to uppercase strings
  - `OrderSenderRole` enum (`customer`, `venue`)
  - `OrderResponse`, `OrderSummaryResponse`, `OrderMessageResponse`
  - `OrderProductSummaryDto`, `OrderVenueSummaryDto`, `OrderCustomerSummaryDto`

**Existing DTOs updated:**
- [`post_response.dart`](hangout_app/lib/domain/dto/response/post_response.dart): added `isProduct`, `price`, `priceCurrency`
- [`create_post_request.dart`](hangout_app/lib/domain/dto/request/create_post_request.dart): added `isProduct`, `price` (both nullable; `includeIfNull: false`)

Both barrels updated:
- `requests.dart` exports the two new request files
- `responses.dart` exports `order_response.dart`

### 7.2 New API methods (`hangout_app/lib/data/api/api_service.dart`)

13 new methods grouped under two sections:

**Customer (`/api/v1/orders`):**
- `createOrder(CreateOrderRequest)`
- `getMyOrders({status?, page?, size?})`
- `getOrder(orderId)`
- `cancelOrder(orderId)`
- `sendOrderMessage(orderId, SendOrderMessageRequest)`
- `markOrderMessagesRead(orderId)` — returns `Future<void>` (204 No Content)

**Venue (`/api/v1/business/venues/{venueId}/orders`):**
- `listVenueOrders(venueId, {status?, page?, size?})`
- `getVenueOrder(venueId, orderId)`
- `acceptOrder(venueId, orderId)`
- `rejectOrder(venueId, orderId)`
- `deliverOrder(venueId, orderId)`
- `cancelVenueOrder(venueId, orderId)`
- `sendVenueOrderMessage(venueId, orderId, SendOrderMessageRequest)`
- `markVenueOrderMessagesRead(venueId, orderId)`

### 7.3 Codegen step

After pulling these changes, run:

```sh
cd /Users/hassan/Desktop/development/hangout_app
flutter pub run build_runner build --delete-conflicting-outputs
```

That regenerates:
- `.g.dart` for the 3 new DTO files and the 2 updated post DTOs
- `api_service.g.dart` with the 13 new method implementations

### 7.4 UI flow (per the original spec)

```
[Feed sees product post]
        │
        │ user taps "Order"
        ▼
[Order page]
   ├─ product info (caption, media, current price)
   ├─ venue info (logo, name, phone)
   ├─ status badge
   ├─ inquiry chat ─── enabled when status is open
   │                    disabled when status is terminal
   └─ actions:
        - Cancel (if open + caller is customer)
```

The same order detail endpoint serves the venue dashboard with the same shape — the dashboard adds `Accept` / `Reject` / `Deliver` / `Cancel` buttons gated by status.

---

## 8. Operational Notes

### 8.1 Deploy

1. Push to Coolify — Flyway runs **V72** on startup (adds columns, table, permission grant, all idempotent).
2. App boots normally. No manual steps.
3. Existing venue staff inherit `venue:orders:manage` via their `owner` / `manager` / `staff` role grants.

### 8.2 What was deliberately scoped out of v1

| Not built | Why |
|---|---|
| Payment integration (Stripe etc.) | Money is off-platform; the feature is intent + acknowledgement |
| Stock / quantity | Every order is 1 unit. Add a `quantity` column later if needed; existing rows default to 1. |
| Pickup vs delivery field | Sorted out via the inquiry chat. Add `fulfillment_type` if it becomes a real friction. |
| Variants (sizes, colors) | Each variant = a separate product post for now. |
| Disputes / refunds | Off-platform support handles. |
| Anonymous orders | Must be logged in. |
| Per-venue currency | Always IQD. The `priceCurrency` field is shipped now so adding it later is non-breaking. |
| Fan-out to all venue staff | Owner only on the notification side. Trivial to expand. |

### 8.3 Anti-abuse measures already in place

- One open order per `(user, post)` — partial unique index.
- Anti-self-order — service-level check via `VenueAccessService`.
- Inquiry chat hard-capped at 1000 chars per message (DB CHECK).
- Chat locks once order is terminal — no zombie threads on closed orders.
- All transitions logged (`responded_by_user_id`, `delivered_by_user_id`, `cancelled_by_user_id`) so fraud / no-show analytics can run later without schema changes.

### 8.4 Where each thing lives

| Thing | Module / file |
|---|---|
| Migration | `hangout_api/hangout-gateway/src/main/resources/db/migration/V72__product_orders.sql` |
| Entities | `hangout_api/hangout-domain/.../entity/order/` (`ProductOrder.java`, `OrderMessage.java`) |
| Repositories | `hangout_api/hangout-domain/.../repository/order/` |
| Service | `hangout_api/hangout-feed/.../service/OrderService.java` + `impl/OrderServiceImpl.java` |
| Customer controller | `hangout_api/hangout-feed/.../controller/OrderController.java` |
| Venue controller | `hangout_api/hangout-feed/.../controller/BusinessOrderController.java` |
| DTOs (request) | `hangout_api/hangout-feed/.../dto/request/CreateOrderRequest.java`, `SendOrderMessageRequest.java` |
| DTOs (response) | `hangout_api/hangout-feed/.../dto/response/OrderResponse.java`, `OrderMessageResponse.java`, `OrderSummaryResponse.java` |
| Kafka events | `hangout_api/hangout-common/.../event/OrderCreatedEvent.java`, `OrderStatusChangedEvent.java`, `OrderMessageSentEvent.java` |
| Kafka topic constants | `hangout_api/hangout-infrastructure/.../config/KafkaConfig.java` |
| Notification handlers | `hangout_api/hangout-notification/.../consumer/KafkaNotificationConsumer.java` (bottom of file) |
| Post entity / DTO changes | `hangout-domain/.../entity/post/Post.java`, `hangout-feed/.../dto/{request,response}/` |

---

## 9. Quick Reference — Status Decoder

| Status | What it means | Who sees it | What's possible |
|---|---|---|---|
| `PENDING` | User placed it; venue hasn't responded | Both | Venue: accept / reject. Customer: cancel. Chat: open. |
| `ACCEPTED` | Venue committed to fulfill | Both | Venue: deliver / cancel. Customer: cancel. Chat: open. |
| `REJECTED` | Venue declined (terminal) | Both | Read-only. Chat locked. |
| `CANCELLED` | Either side dropped out (terminal) | Both | Read-only. Chat locked. `cancelled_by_user_id` tells which side. |
| `DELIVERED` | Customer received + paid (terminal — happy path) | Both | Read-only. Chat locked. Customer can re-order the same product. |

---

*Generated 2026-05-29 alongside the V72 migration.*
