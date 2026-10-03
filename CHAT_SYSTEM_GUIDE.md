# Hangout Chat — Backend State & Flutter Usage Guide

---

## Part 1: What's ready in the backend

### Core data model (Postgres, V47 migration)

- **`chat_conversations`** — DIRECT (1-on-1) or GROUP. Stores title, avatar, creator, denormalized last-message pointers (for inbox sort), per-thread retention override.
- **`chat_conversation_members`** — polymorphic membership (USER or VENUE). Tracks role (MEMBER/ADMIN), request state (PENDING/ACCEPTED for the Message Requests inbox flow), last-read pointer, mute flag, soft-leave timestamp.
- **`chat_messages`** — TEXT, VOICE, or SHARE messages. Carries content, audio metadata (URL/duration/waveform), shared-resource pointer, reply pointer, edited-at, deleted-for-everyone tombstone flag.
- **`chat_message_deletions`** — per-user "delete for me" hidden rows (distinct from global tombstone).

### REST endpoints — 18 in total under `/api/v1/chat/*`

**Conversations**
- Create or fetch-existing DIRECT/GROUP thread
- List inbox (ACCEPTED conversations)
- List message requests (PENDING conversations)
- Get single conversation
- Accept / reject request (reject hard-deletes the conversation)
- Leave (soft-leave for self)
- Update conversation (title / avatar / retention — partial PATCH, admin-gated where appropriate)
- Mute toggle (per-member)

**Group admin**
- Add members (up to 250 total, bulk per request)
- Remove member (hard-delete, admin only)
- Promote/demote role (cannot demote the last admin)

**Messages**
- Paginated history (newest-first)
- Send TEXT / VOICE / SHARE
- Mark conversation read (advances last-read pointer)
- Edit (TEXT only, 15-minute window)
- Delete with scope: `me` (hide for caller) or `everyone` (global tombstone)

**Voice upload**
- Two-step S3 presigned PUT. Allowed MIME types whitelisted on the backend.

### Permission gates baked in

- **DM permission**: if the recipient is private and the sender isn't an accepted follower, the new thread lands in the recipient's Message Requests inbox automatically. Public recipients (and all venues) skip this and go straight to ACCEPTED.
- **Block check**: both at conversation creation AND on every message send. Either-way block = 403.
- **Membership**: every action that touches a conversation verifies the caller is an active accepted member; PENDING members can't send (only accept/reject).
- **Group admin**: title/avatar/retention/add/remove/role changes are admin-gated.

### Sharing (Instagram "Send" feature)

- A SHARE message carries a typed pointer (`POST`, `HANGOUT`, `VENUE`, `USER`, `STORY`) + the resource ID.
- Backend hydrates a preview (title + subtitle + thumbnail) on read by batch-fetching from each source repository.
- Visibility-respecting: if you share a post by someone who's now private + the viewer doesn't follow them, the preview returns `available: false` and the client renders a grey "unavailable" tombstone.
- STORY shares are reserved — the enum value exists, but send-time validation rejects them with 400 until the Story feature ships. No future migration needed.

### Real-time layer — WebSocket + STOMP

- **Endpoint**: `wss://api.dlliny.com/ws` (or `ws://localhost:8080/ws` in dev)
- **Auth**: JWT passed as a STOMP `Authorization: Bearer ...` native header on CONNECT (not in the URL — survives proxy log-stripping)
- **Subscription topics**:
  - `/topic/conversations/{id}` — all events for an open thread
  - `/topic/users/{userId}/inbox` — refresh hint when a fresh conversation arrives
  - `/topic/users/{userId}/presence` — that user's online/offline events
- **Client → server send destination**:
  - `/app/conversations/{id}/typing` — typing indicator (boolean body)
- **Event types** (all flowing into one payload envelope with a `type` discriminator):
  - `MESSAGE_CREATED`, `MESSAGE_EDITED`, `MESSAGE_DELETED`
  - `READ_RECEIPT`
  - `TYPING`
  - `REQUEST_ACCEPTED`
  - `MEMBER_ADDED`, `MEMBER_REMOVED`, `MEMBER_ROLE_CHANGED`
  - `CONVERSATION_UPDATED`

### Presence

- Redis-backed: per-user TTL key (online while present) + ZSET tracking last-seen timestamps.
- Bulk-online lookup available for inbox rendering.
- Connect/disconnect events fire fanouts on `/topic/users/{id}/presence`.
- Last-seen survives offline so the client can render "last seen 5 min ago" after disconnect.

### What backend events fire on each user action

| User action | DB write | Realtime fanout | Kafka event (outbox) |
|---|---|---|---|
| Create DM with public peer | new conv + 2 ACCEPTED members | Inbox refresh hint to peer | — |
| Create DM with private peer (no follow) | new conv + sender ACCEPTED + recipient PENDING | Inbox refresh hint | `CHAT_MESSAGE_REQUEST` |
| Send message | new message + conv last-message updated | `MESSAGE_CREATED` | `CHAT_MESSAGE_SENT` |
| Edit message | message updated + edited_at | `MESSAGE_EDITED` | — |
| Unsend (delete everyone) | message tombstoned + payload nulled | `MESSAGE_DELETED` | — |
| Delete for me | row in `chat_message_deletions` | (nothing — personal) | — |
| Mark read | member's last-read pointer | `READ_RECEIPT` | — |
| Accept request | member PENDING → ACCEPTED | `REQUEST_ACCEPTED` | — |
| Reject request | conversation hard-deleted | (nothing) | — |
| Leave conversation | member soft-leave (`left_at`) | (nothing — quiet leave) | — |
| Admin adds member(s) | new member rows | `MEMBER_ADDED` + inbox hint per added user | — |
| Admin removes member | member row deleted | `MEMBER_REMOVED` + inbox hint to removed user | — |
| Admin changes role | member role updated | `MEMBER_ROLE_CHANGED` | — |
| Update conversation | conv title/avatar/retention | `CONVERSATION_UPDATED` | — |
| Mute toggle | member.muted flipped | (nothing — personal) | — |

### What's NOT in the backend (still missing)

- FCM consumer for `CHAT_MESSAGE_SENT` / `CHAT_MESSAGE_REQUEST` — Kafka events publish, no listener wired, no pushes leave the server yet
- Retention sweeper job — messages live forever until per-thread retention expires, but no purge runs
- Multi-instance WebSocket fanout — single in-memory broker; broadcasts don't cross pods
- Message reactions, forward, search, transcription — all future features

---

## Part 2: How to use it from Flutter

### What's already wired Flutter-side

- All chat DTOs (enums + 5 response classes + 8 request classes)
- All 18 chat endpoints on `api_service.dart`
- Build runner clean, analyzer clean

### The conceptual flow — three phases of any conversation

**Phase 1 — Opening or starting a conversation**

Call create-conversation with a peer (USER or VENUE) for DIRECT, or a list of users + title for GROUP. The server is idempotent for DIRECT: if a thread between you two already exists, you get the same conversation back instead of a duplicate. Either way you get a `ConversationResponse` — push the conversation screen with its ID.

**Phase 2 — Listing inbox / requests**

Two paginated endpoints. Inbox lists conversations where you're ACCEPTED. Message requests lists conversations where you're PENDING (someone DM'd you but you haven't accepted yet). Same DTO shape — your screen renders both with the same row widget, just routed to different tabs.

Each conversation row already carries everything you need to render it: last message, unread count, viewer's request state, mute flag, members list with display names and avatars. No second fetch per row.

**Phase 3 — Inside a conversation**

History is paginated newest-first. As the user scrolls up, request the next page (older messages). Map each `MessageResponse` to a bubble based on `contentType`:
- TEXT → just text
- VOICE → waveform + audio playback
- SHARE → preview card with deep-link to the underlying resource
- `deletedForEveryone: true` → tombstone

When the user opens the screen or scrolls past unread messages, call mark-conversation-read with the latest message ID. This advances the read pointer and fires a realtime event to the other side.

### How sending works for each content type

**Text** — straight `sendMessage` with `contentType: TEXT` and the body. Optionally include `replyToMessageId` to thread under another message.

**Voice** — two-step:
1. Call get-voice-upload-url with the audio MIME type. You get back a presigned S3 PUT URL plus a key.
2. PUT the raw audio bytes directly to that URL using a **separate Dio instance** with NO auth interceptor (S3 rejects bearer tokens). Use the same content-type header you requested.
3. Once S3 returns 200, call `sendMessage` with `contentType: VOICE`, the returned key as `audioKey`, the duration in seconds, and a JSON-encoded array of normalized waveform amplitudes.

Render a local optimistic placeholder during steps 1-3 so the user sees the bubble immediately. Replace the placeholder when the server returns the real message.

**Share** — call `sendMessage` with `contentType: SHARE`, `sharedResourceType` (POST/HANGOUT/VENUE/USER), `sharedResourceId`, and optionally a caption in `content`. The server hydrates the preview and returns it in the response — no separate fetch needed.

### The Message Requests flow (private accounts)

This is automatic — you don't do anything special when sending. The behavior:

1. You DM a private user you don't follow → backend creates the conversation, your side is ACCEPTED, peer's side is PENDING.
2. You see the conversation in your normal Chats inbox immediately.
3. The peer doesn't see it in their Chats — it lives in their Message Requests tab. They get a silent or low-priority push (when FCM is wired).
4. The peer accepts → realtime `REQUEST_ACCEPTED` fires on the conversation topic. Now both sides see it as a normal thread.
5. Or the peer rejects → the entire conversation is hard-deleted server-side. Your side suddenly loses the conversation on next refresh (or via inbox-refresh hint when WebSocket is wired).

On the receiving side, your UI checks `viewerRequestState`:
- `ACCEPTED` → show the composer
- `PENDING` → hide the composer, show Accept/Reject banner instead

### Editing, deleting, unsending

- **Edit**: PATCH a message ID with new content. Only works on TEXT, only by sender, only within 15 minutes. Server returns 400 if you're out of window — handle it as "Edit time expired" snackbar.
- **Delete for me**: DELETE with `scope=me`. Hides only for you. Server returns 204; remove from local list.
- **Unsend (delete for everyone)**: DELETE with `scope=everyone`. Server tombstones the message globally. Other clients receive `MESSAGE_DELETED` event. Don't remove the row locally — replace it with a tombstone bubble.

### Group admin actions

Once a conversation has type GROUP and you're an ADMIN (check `members` list against your own user ID):
- **Add members**: bulk endpoint, takes a list of user IDs. Missing/banned users silently dropped — trust the response's final member list.
- **Remove member**: pass a user ID. Backend rejects if you try to remove yourself (use leave for that).
- **Change role**: promote to ADMIN or demote to MEMBER. Server rejects demoting the last admin — handle that as a "There must be at least one admin" snackbar.
- **Update title / avatar / retention**: partial PATCH. Send only the fields you want to change.

For DIRECT conversations, only retention is editable via the update endpoint.

### Mute

Per-member toggle. Mute is your personal preference — the other side never learns about it. The backend won't push FCM notifications to muted recipients (when FCM is wired). No realtime event fires.

### Pulling presence + online status

Two ways:
- **Inbox rendering** (when needed): you'd need a bulk-online REST endpoint. **This doesn't exist yet** — when the inbox needs to render online dots, we add a `GET /chat/presence?userIds=...`. For now, just don't render dots in v1.
- **Inside a conversation**: subscribe to `/topic/users/{peerId}/presence` over WebSocket. You'll receive `{ online, lastSeenAt? }` events whenever they connect or disconnect. Render their header status from that.

### WebSocket integration — what you'll need to do

Until WebSocket is wired Flutter-side, you're on pure REST. Behaviors:
- New messages from others only appear when you refresh
- Read receipts from the other side don't show
- Typing indicators don't show
- Online status doesn't show

When you add `stomp_dart_client`:

1. **Connect on app start** after login. Pass `Authorization: Bearer <jwt>` in the CONNECT headers (NOT in the URL). Set heartbeats to ~10 seconds.
2. **Subscribe to your inbox-refresh topic** (`/topic/users/{myUserId}/inbox`) immediately after connect. Use it to refresh the inbox list when fresh conversations land.
3. **Subscribe to a conversation topic** when the user opens that conversation. Unsubscribe when they leave.
4. **Subscribe to a peer's presence topic** when rendering a 1-on-1 conversation header.
5. **Emit typing events** when the user types in the composer. Debounce: send `true` on first keystroke, then `false` after 3 seconds of inactivity or on send/blur. Server fans this out as a `TYPING` event.
6. **Handle every incoming event** by switching on `type`:
   - MESSAGE_CREATED → append to conversation list + bump inbox row to top + increment unread (if not currently viewing it)
   - MESSAGE_EDITED → find by ID, replace content + show "edited" badge
   - MESSAGE_DELETED → find by ID, replace with tombstone
   - READ_RECEIPT → update local "seen" indicator on your sent messages
   - TYPING → toggle a transient "typing..." indicator in the header (auto-clear after 5 seconds if no follow-up)
   - REQUEST_ACCEPTED → if you're viewing this conversation, swap the request banner for the composer
   - MEMBER_ADDED / MEMBER_REMOVED / MEMBER_ROLE_CHANGED → update the local conversation's member list, render a system bubble ("Sara was added to the group")
   - CONVERSATION_UPDATED → update local conversation header (title/avatar/retention)
7. **Reconnect on disconnect**. The library handles this automatically; you must re-subscribe to all topics on reconnect.
8. **Drop the WebSocket on logout / token expiry**. Disconnect cleanly, reconnect with the new token after refresh.

### Error handling — what to expect

- **400 Bad Request**: usually a business rule violation. Common: edit window expired, group cap exceeded, story share attempted, demoting last admin. Surface as snackbar with the server message.
- **403 Forbidden**: permission gate. Common: trying to message a blocked user, sending while PENDING, non-admin trying admin actions, action on a conversation you've left.
- **404 Not Found**: conversation/message/member missing — refresh the affected screen.
- **409 Conflict**: rare, mostly DB-level constraint. Treat as transient.
- **500**: surface a generic "Something went wrong, try again" with retry button.

The repository layer should map these `DioException`s to typed exceptions so blocs/cubits can pattern-match instead of inspecting status codes.

### What you should build first (Flutter)

In order of value:

1. **Repository layer** — `ChatRepository` (REST) + `VoiceUploadRepository` (S3). Unwrap `ApiResponse`, throw typed errors.
2. **Inbox bloc + screen** — paginated list, pull-to-refresh, message-requests tab. Pure REST, no WebSocket needed.
3. **Conversation bloc + screen** — paginated history, TEXT bubbles, send + mark read.
4. **Bubble types** — VOICE rendering + playback, SHARE preview card.
5. **Long-press menu** — reply, edit, delete-for-me, unsend, copy, forward.
6. **Voice recording** — 2-step upload flow with optimistic placeholder.
7. **Share sheet** — "Send" button on Post/Hangout/Venue/User detail screens.
8. **Group create + admin** — multi-user picker, group settings screen.
9. **WebSocket integration** — `stomp_dart_client`, event dispatch into existing blocs.
10. **Presence + typing UI** — wires into WS topics.

Steps 1-8 are pure REST and work without any WebSocket. The app is fully usable after step 8. Step 9 elevates it to "instant" and step 10 polishes.

### Things you DON'T need to handle

- Unread counts → server returns them
- Server-generated IDs → use the response's `id`, your client-side UUIDs are only for optimistic placeholders
- Shared resource previews → already hydrated in the response
- 15-minute edit window → server enforces (just hide the menu after 15 min for UX)
- Computing "is the message mine" → compare `senderId` with your own user ID
- Last-message ordering in inbox → server returns sorted

---

## Bottom line

The backend is fully usable today for REST flows — full conversation CRUD, messaging, sharing, group admin, mute, message requests, voice upload. WebSocket fanout fires for every state-changing action but no Flutter client consumes it yet. FCM pushes don't leave the server yet.

You can ship a v1 client right now with no real-time and no push. Both gaps are next-up but neither blocks shipping.
