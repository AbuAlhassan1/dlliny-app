# Hangout Attendance + Memories — Recent Changes

Four backend changes that together make hangouts behave like real social events: attendees can share memories, change their mind, and find what to upload to.

| # | Change | Endpoint(s) affected |
|---|---|---|
| 1 | Media upload now allowed for accepted attendees (7-day post-event window) | `GET/POST/DELETE /api/v1/hangouts/{id}/media/*` |
| 2 | Invite window closes 24h after `scheduledAt` | `POST /api/v1/hangouts/{id}/invite` |
| 3 | New "leave hangout" endpoint | `POST /api/v1/hangouts/{id}/leave` |
| 4 | New "my recent-attended hangouts" endpoint | `GET /api/v1/hangouts/me/recent-attended` |

---

## How they compose end-to-end

```
Day 0:  Organizer creates hangout, scheduledAt = Day 7 at 19:00
        │
        ├─ invites Alice, Bob, Carol         ← change #2: until Day 8 19:00
        │
Day 3:  Alice accepts
Day 4:  Bob accepts; Carol still pending
Day 5:  Bob has to bail — calls /leave      ← change #3: pre-event only
        │  → status flips accepted → declined
        │  → organizer gets HANGOUT_RESPONDED event
        │
Day 7 19:00: Hangout starts
        │
        ├─ Alice + Carol attend (Carol RSVPed late)
        │
Day 7 20:30: Hangout ends
        │
        ├─ Alice uploads 3 photos             ← change #1: in 7-day window
        ├─ Carol uploads 2 photos             ← change #1
        ├─ Organizer uploads cover image      ← change #1: no time cap for organizer
        │
Day 8 17:00: Organizer realizes they forgot to invite Dave
        │
        ├─ Calls /invite → ✅ accepted        ← change #2: still inside 24h grace
        │   (so Dave can also share memories within his own window)
        │
Day 8 20:00: Invite window closes (24h after Day 7 19:00)
        │
Day 10: Alice opens app, taps "Share memories"
        │
        ├─ App calls /me/recent-attended      ← change #4
        │   → returns this hangout + any others she attended ≤ 7d ago
        ├─ Alice picks this hangout, uploads 1 more photo
        │
Day 14 19:00: Upload window closes for all attendees
        │
        └─ Only the organizer can still upload after this point
```

---

## Change 1 — Media upload guard

### What changed

**Before**: Only the organizer could upload media to a hangout. No time check at all — they could upload years after the event.

**After**: Organizer + accepted invitees. Time window applies to invitees only.

### The new authorization matrix

| Caller | Time | Can upload? |
|---|---|---|
| Organizer | Anytime (pre, during, post) | ✅ |
| Accepted invitee | Before `scheduledAt` | ❌ `"can only share media after the hangout starts"` |
| Accepted invitee | `[scheduledAt, scheduledAt + 7 days)` | ✅ |
| Accepted invitee | After `scheduledAt + 7 days` | ❌ `"the 7-day window has closed"` |
| Pending / declined invitee | Anytime | ❌ `"only the organizer or accepted attendees"` |
| Random user | Anytime | ❌ same as above |

### Delete authorization

| Caller | Can delete |
|---|---|
| Organizer | Any media on the hangout |
| Anyone else | Only media they uploaded themselves (no time check) |

The 10-media-per-hangout cap (`MAX_MEDIA_PER_HANGOUT`) still applies — it now covers combined organizer + attendee uploads.

### Endpoints (unchanged URLs, new guards)

```
GET    /api/v1/hangouts/{id}/media               ← unchanged (any USER)
GET    /api/v1/hangouts/{id}/media/upload-url    ← new guards
POST   /api/v1/hangouts/{id}/media/confirm       ← new guards
DELETE /api/v1/hangouts/{id}/media/{mediaId}     ← new guards
```

### Why the organizer is exempt from the time window

They may need to set a pre-event cover image and may want to curate after the public window closes. Setting it shorter would mean the organizer can't post the hangout's hero image before the event.

If you'd rather apply the 7-day cap to everyone including the organizer, it's a one-line change.

---

## Change 2 — Invite 24h time gate

### What changed

**Before**: Organizer could invite users at any time — including years after the hangout ended. Functionally useless but allowed.

**After**: Invite window closes 24 hours after `scheduledAt`.

### Why 24 hours, not zero

It's tied to the 7-day media upload window. A late invitee (added ~12 hours after the event) still has time to RSVP, accept, and drop in some photos before the upload window closes. Setting the invite gate too tight would create a weird mismatch where a brand-new invitee couldn't share anything.

### Endpoint (unchanged URL, new guard)

```
POST /api/v1/hangouts/{id}/invite

→ 400 "Can no longer invite users — the invite window closed 24 hours
       after the hangout's scheduled time"
```

### Pre-existing guards still apply

- Only the organizer can invite (`"Only the organizer can invite users"`)
- Already-invited users are silently skipped
- Inactive / banned / deleted users are silently skipped

---

## Change 3 — Leave hangout (new endpoint)

### The gap this fixes

The original code had this in `respondToInvitation`:

```java
if (!"pending".equals(invitation.getStatus())) {
    throw new BusinessException("Invitation already responded to");
}
```

Once a user accepted, they were locked in. No "leave," no "withdraw," no way to change their mind. This meant:

- Inflated attendee counts (ghost attendees stuck as accepted)
- Confusing notifications (event reminders to people not coming)
- Organizers couldn't chase RSVPs (everyone marked as accepted)

### The new endpoint

```
POST /api/v1/hangouts/{id}/leave
Auth: hasRole('USER')
Body: none
Response: ApiResponse<void>
```

### Behavior matrix

| Caller state | Result |
|---|---|
| Has `accepted` invitation, hangout not started | ✅ flips to `declined`, fires `HANGOUT_RESPONDED` event |
| Has `pending` invitation, hangout not started | ✅ flips to `declined`, fires event |
| Has `declined` invitation | ✅ idempotent no-op |
| No invitation at all | ❌ **404** `"You don't have an invitation to this hangout"` |
| Is the organizer | ❌ **400** `"Organizers cannot leave their own hangout — cancel it instead"` |
| Hangout has already started (`now >= scheduledAt`) | ❌ **400** `"Cannot leave a hangout that has already started"` |

### Kafka event difference vs `respondToInvitation`

The original `respondToInvitation` fires `HANGOUT_RESPONDED` **only** when `status == 'accepted'`. Declines have always been silent.

The new `leave` endpoint fires `HANGOUT_RESPONDED` with `status='declined'` regardless — because going from `accepted → declined` is meaningful (the organizer was already planning around this person).

So downstream consumers (notifications, analytics rollups) will see decline events fire for the first time. Be aware when wiring up that surface.

### Flutter button gating

```dart
bool canLeave({
  required HangoutResponse h,
  required UUID currentUserId,
  required MyInvitation? myInv,
}) {
  if (h.organizerId == currentUserId) return false;  // must cancel, not leave
  if (myInv == null) return false;                    // need an invitation row
  return DateTime.now().isBefore(DateTime.parse(h.scheduledAt));
}
```

---

## Change 4 — Recent-attended hangouts (new endpoint)

### What it solves

After change 1, accepted attendees can upload media for 7 days post-event. But how does the user discover what they can still upload to? This endpoint backs the "share your memories" surface.

### The endpoint

```
GET /api/v1/hangouts/me/recent-attended
Auth: hasRole('USER')
Response: ApiResponse<List<HangoutResponse>>
```

### Selection rule (matches upload window exactly)

A hangout appears in this list iff:

- `scheduledAt <= now` (it already happened)
- `scheduledAt >= now - 7 days` (still in the upload window)
- `status != 'cancelled'`
- `hidden = false`
- Caller has an `accepted` `HangoutInvitation` row

Ordered most-recent first.

### Deliberately NOT included

| Excluded | Why |
|---|---|
| Organized hangouts (caller is organizer) | They have no time gate; already returned by `getMyHangouts` |
| Pending invitations | Pending invitees can't upload — they'd 403 if they tried |
| Hangouts older than 7 days | Upload window has closed even for attendees |
| Cancelled / hidden hangouts | Logically out of scope |

### The 7-day constant is shared with the media upload guard

Both `HangoutMediaServiceImpl.ATTENDEE_UPLOAD_WINDOW_DAYS = 7` and `HangoutServiceImpl.RECENT_ATTENDED_WINDOW_DAYS = 7` are kept in sync deliberately. If you change one without the other, the list endpoint will return hangouts the upload endpoint then 403s on — or vice versa. Both have explanatory comments pointing at each other.

If you want this configurable later, both can read from one `app.hangout.*` property.

### Flutter UI flow

```dart
// 1. Load the "share your memories" list
final r = await apiService.getMyRecentAttendedHangouts();
final hangouts = r.data ?? [];

// 2. User picks one, then route into the existing upload flow:
final upload = await apiService.getHangoutMediaUploadUrl(hangoutId, 'image/jpeg');
// PUT bytes to upload.data.uploadUrl
await apiService.confirmHangoutMedia(
  hangoutId,
  ConfirmHangoutMediaRequest(key: upload.data!.key, mediaType: 'image', /* … */),
);
```

No new DTOs. The whole feature reuses what's already there.

---

## Summary — files touched

### Backend (4 files, 1 new method per area)

| File | Change |
|---|---|
| [HangoutRepository.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/hangout/HangoutRepository.java) | New `findRecentAttended` query |
| [HangoutInvitationRepository.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/hangout/HangoutInvitationRepository.java) | New `existsByHangoutIdAndInviteeIdAndStatus` derived query |
| [HangoutMediaServiceImpl.java](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/service/impl/HangoutMediaServiceImpl.java) | Replaced `checkIsOrganizer` with `assertCanUpload` + `assertCanDelete`; injected invitation repo; added `ATTENDEE_UPLOAD_WINDOW_DAYS = 7` |
| [HangoutService.java](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/service/HangoutService.java) | Added `leaveHangout` + `getMyRecentAttendedHangouts` to interface |
| [HangoutServiceImpl.java](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/service/impl/HangoutServiceImpl.java) | Implemented both new service methods + added 24h gate to `invite()` + added `RECENT_ATTENDED_WINDOW_DAYS = 7` |
| [HangoutController.java](hangout_api/hangout-hangout/src/main/java/com/beestar/hangout/hangout/controller/HangoutController.java) | New `POST /{id}/leave` + `GET /me/recent-attended` endpoints |

### Flutter (1 file)

| File | Change |
|---|---|
| [api_service.dart](../hangout_app/lib/data/api/api_service.dart) | New `leaveHangout(hangoutId)` + `getMyRecentAttendedHangouts()` methods |

### What did NOT need to change

- No new database migrations — existing `hangout_invitations.status` column already supports `'declined'` for the leave path
- No new DTOs — both new endpoints reuse `HangoutResponse` / `void`
- No new Kafka topics — leave fires the existing `HANGOUT_RESPONDED` topic
- No new permissions — all four changes use the existing `hasRole('USER')` gate

---

## Behavioral cheat sheet for the Flutter team

| Question | Answer (post-change) |
|---|---|
| Can an accepted invitee upload media after the hangout? | ✅ Yes, within 7 days of `scheduledAt` |
| Can the organizer delete an attendee's photo? | ✅ Yes, always |
| Can an attendee delete their own photo? | ✅ Yes, no time limit |
| Can an attendee delete someone else's photo? | ❌ No, 400 |
| Can the organizer invite more users after the hangout starts? | ✅ Yes, up to 24h after `scheduledAt` |
| Can the organizer invite after `scheduledAt + 24h`? | ❌ No, 400 |
| Can an accepted user leave before the hangout starts? | ✅ Yes, new `/leave` endpoint |
| Can an accepted user leave after the hangout starts? | ❌ No, 400 |
| Can the organizer "leave" their own hangout? | ❌ No, must cancel instead |
| How do I show users which hangouts they can still upload media to? | `GET /me/recent-attended` |
