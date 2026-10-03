# Challenges — Flutter Integration Guide

Reference for wiring the challenges feature into the Dlliny mobile app. Backend is complete across Slices 1–6. Flutter DTOs + API service methods have been generated; this doc explains what they do and how to build the UI on top.

---

## 1. What the feature does

A gamified engagement loop:

```
User discovers a challenge  →  joins it  →  performs the objective(s)  →
progress updates automatically (from the Kafka listener)  →  challenge
completes  →  points get added to their score  →  they level up  →
receive a push notification.
```

**Levels**: 10 levels, with fixed thresholds:

| Level | Points to reach |
|-------|-----------------|
| 1     | 0               |
| 2     | 100             |
| 3     | 300             |
| 4     | 700             |
| 5     | 1,500           |
| 6     | 3,000           |
| 7     | 6,000           |
| 8     | 12,000          |
| 9     | 25,000          |
| 10    | 50,000          |

**Points**: earned by completing challenge objectives. Each objective has a fixed `points` value; each challenge has a `bonusPoints` awarded when the completion threshold is hit.

**Influencer flag**: users can self-serve toggle their influencer status. INFLUENCERS-audience challenges become visible after enabling; NORMAL_USERS-audience challenges become hidden.

---

## 2. Endpoints

All under `https://api.dlliny.com` — bearer-token auth via the standard `Authorization: Bearer <accessToken>` header. Wired to Retrofit methods in [api_service.dart](hangout_app/lib/data/api/api_service.dart).

### Points & Levels

| Method | Path | Retrofit method | Returns |
|---|---|---|---|
| GET  | `/api/v1/users/me/points`             | `getMyPoints()`        | `UserPointsResponse` |
| POST | `/api/v1/users/me/influencer/enable`  | `enableInfluencer()`   | `UserDto` |
| POST | `/api/v1/users/me/influencer/disable` | `disableInfluencer()`  | `UserDto` |

### Challenges (user-facing)

| Method | Path | Retrofit method | Returns |
|---|---|---|---|
| GET  | `/api/v1/challenges?cadence=…`        | `getChallenges({cadence})`  | `List<ChallengeListItemResponse>` |
| GET  | `/api/v1/challenges/me/joined`        | `getMyJoinedChallenges()`   | `List<ChallengeListItemResponse>` |
| GET  | `/api/v1/challenges/{id}`             | `getChallengeDetail(id)`    | `ChallengeDetailResponse` |
| POST | `/api/v1/challenges/{id}/join`        | `joinChallenge(id)`         | `ChallengeDetailResponse` |

### Check-in (drives VISIT_BRANCH progress)

| Method | Path | Retrofit method | Returns |
|---|---|---|---|
| POST | `/api/v1/venue-locations/{branchId}/check-in` | `checkInAtBranch(branchId, req)` | `CheckInResponse` |

---

## 3. DTO reference

Located under `lib/domain/dto/`. All are `@JsonSerializable`; run `dart run build_runner build --delete-conflicting-outputs` after pulling to generate the `.g.dart` files.

### `UserPointsResponse`

```dart
class UserPointsResponse {
  final int totalPoints;
  final int level;
  final int currentLevelThreshold;
  final int? nextLevelThreshold;   // null at max level
  final int pointsToNextLevel;     // 0 at max
  final bool isMaxLevel;
}
```

**UI usage**: level badge + progress bar. If `isMaxLevel`, render "MAX" instead of a bar.

### `ChallengeListItemResponse`

```dart
class ChallengeListItemResponse {
  final String id;
  final ChallengeKind kind;              // PLATFORM | VENUE
  final ChallengeAudience audience;      // ANY | NORMAL_USERS | INFLUENCERS
  final ChallengeCadence cadence;        // DAILY | WEEKLY | MONTHLY | SEASONAL | SPECIAL
  final String titleAr;
  final String titleEn;
  final String? descriptionAr;
  final String? descriptionEn;
  final String? iconUrl;
  final String startsAt;                 // ISO-8601
  final String? endsAt;                  // null = evergreen
  final int bonusPoints;
  final int? requiredObjectiveCount;     // null = every objective required
  final int totalObjectiveCount;

  final String? venueId;                 // populated for VENUE-kind only
  final String? venueNameAr;
  final String? venueNameEn;

  final UserChallengeProgressResponse? myProgress;  // null if not joined
}
```

**UI usage**: card in the discovery grid. `myProgress == null` → render join CTA. Otherwise render `myProgress.completedObjectiveCount / myProgress.totalObjectiveCount` as a chip.

### `ChallengeDetailResponse`

Same top-level fields as `ChallengeListItemResponse`, plus:

```dart
final List<ObjectiveWithProgressResponse> objectives;
```

### `ObjectiveWithProgressResponse`

```dart
class ObjectiveWithProgressResponse {
  final String id;
  final ChallengeObjectiveType type;
  final Map<String, dynamic> config;   // shape depends on type (see §5)
  final int points;                    // awarded on completion of THIS objective
  final int sortOrder;
  final String? titleAr;
  final String? titleEn;

  final int? progressValue;            // null when not joined
  final int target;                    // server-derived from config
  final bool completed;
  final String? completedAt;
}
```

Render each objective as an "X of Y" tile using `progressValue` / `target`.

### `UserChallengeProgressResponse`

```dart
class UserChallengeProgressResponse {
  final ChallengeProgressStatus status;    // IN_PROGRESS | COMPLETED | EXPIRED
  final int totalPointsEarned;             // includes bonus if completed
  final int completedObjectiveCount;
  final int totalObjectiveCount;
  final String? completedAt;
  final String joinedAt;
}
```

### `CheckInRequest` / `CheckInResponse`

```dart
class CheckInRequest {
  final double latitude;
  final double longitude;
}

class CheckInResponse {
  final String checkInId;
  final String venueId;
  final String branchId;
  final String checkedInAt;
  final int distanceMeters;   // measured server-side, ≤ 200
}
```

---

## 4. Enum reference

All enums are `@JsonEnum` with explicit `@JsonValue('UPPER_SNAKE_CASE')` mappings — the wire format is the backend's enum name, the Dart field uses camelCase.

| Enum | Values (Dart / wire) |
|---|---|
| `ChallengeKind`             | `platform` / `PLATFORM`, `venue` / `VENUE` |
| `ChallengeAudience`         | `any` / `ANY`, `normalUsers` / `NORMAL_USERS`, `influencers` / `INFLUENCERS` |
| `ChallengeCadence`          | `daily`, `weekly`, `monthly`, `seasonal`, `special` |
| `ChallengeObjectiveType`    | `visitBranch`, `createHangout`, `inviteFriends`, `postCount`, `memoryCount`, `followVenue`, `reviewVenue` |
| `ChallengeProgressStatus`   | `inProgress`, `completed`, `expired` |

---

## 5. Objective config shapes

`ObjectiveWithProgressResponse.config` is a `Map<String, dynamic>` whose shape depends on `type`. Use these to render human-readable objective descriptions when the challenge author didn't provide a title:

### `VISIT_BRANCH`
```
{
  "venueId": "<uuid>",           // required
  "branchIds": ["<uuid>", ...]   // optional; when set, user must visit all listed branches
}
```
- **target** = `branchIds.length` if set, else `1`.
- Trigger: server-side check-in endpoint. Rate-limited.

### `CREATE_HANGOUT`
```
{
  "count": <positive int>,       // required
  "venueId": "<uuid>"            // optional; restrict to hangouts at a specific venue
}
```
- **target** = `count`.
- Only sticky hangouts count (excludes `status='cancelled'` and soft-deleted).

### `INVITE_FRIENDS`
```
{
  "count": <positive int>,       // required
  "minAccepted": <int>           // optional; at least this many must accept for completion
}
```
- **target** = `count`.
- If `minAccepted` present, both the sent count AND the accepted count must clear their thresholds.

### `POST_COUNT`
```
{
  "count": <positive int>,       // required
  "mustMentionVenueId": "<uuid>" // optional; restrict to posts that @mention this venue
}
```
- **target** = `count`.

### `MEMORY_COUNT`
```
{
  "count": <positive int>,       // required
  "mustMentionVenueId": "<uuid>" // optional; same as POST_COUNT
}
```
- **target** = `count`.
- Note: memories self-expire after 24h. Progress over a fully-past window is best-effort.

### `FOLLOW_VENUE`
```
{
  "venueIds": ["<uuid>", ...]    // required, non-empty
}
```
- **target** = `venueIds.length`.
- State-based (not windowed) — user must currently follow all listed venues.

### `REVIEW_VENUE`
```
{
  "venueId": "<uuid>",           // required
  "minRating": <1..5>            // optional; review must be ≥ this rating
}
```
- **target** = `1`.

---

## 6. UX flows

### Discover challenges

```
homepage → "Challenges" tab
   → getChallenges() for the "For you" section
   → getChallenges(cadence: 'DAILY') for the daily strip
   → getChallenges(cadence: 'WEEKLY') for the weekly strip
```

Each card:
- Icon (from `iconUrl`, fall back to a cadence icon).
- Title (bilingual).
- "3/5 objectives" chip if joined, else "Join" CTA.
- Bonus points badge.
- Ends-in countdown if `endsAt` is set.

### Join a challenge

```
tap card → getChallengeDetail(id) to show the full breakdown
        → tap "Join" → joinChallenge(id)
        → response is the same shape as detail, but myProgress is now populated
```

The join response already reflects any pre-existing source data — e.g. if the user reviewed the venue yesterday, the REVIEW_VENUE objective is already marked complete.

### My Challenges tab

```
getMyJoinedChallenges() → newest-touched first
```

Recompute runs before returning so the counts are fresh. Group into sections:
- **In progress** (`status == inProgress`)
- **Completed** (`status == completed`) — show earned points
- **Expired** (`status == expired`) — greyed out

### Doing a check-in

For a `VISIT_BRANCH` objective:

```
tap "Check in" → request location permission → get current lat/lng
             → checkInAtBranch(branchId, CheckInRequest(lat, lng))
             → on success: show "You checked in! You were {distanceMeters}m away" toast
             → refresh challenge detail so the VISIT_BRANCH count moves
```

**Handling errors**:
- `400 "You are too far from the branch (XXXm > 200m)"` — user isn't close enough. Show the actual distance.
- `400 "You already checked in at this branch in the last 6 hours"` — cooldown active.
- `400 "Too many check-ins in the last hour"` — global 20/hr cap hit.
- `400 "This branch is inactive"` — branch was disabled; ask the venue.

### Handling the level-up push

Backend fires a `LEVEL_UP` FCM push when the user crosses a threshold. Payload extras carry `entityType=USER`, `entityId=<userId>`, deep link `hangout://profile/me/points`.

On the app:
- Show an in-app celebration overlay when the notification lands while the app is foregrounded.
- Deep link route lands on the points/profile screen — refresh `getMyPoints()` to render the new level immediately.

---

## 7. Enabling / disabling influencer mode

```dart
await apiService.enableInfluencer();   // idempotent
```

After the call:
- User's authorities don't change (JWT stays the same).
- `getChallenges()` now returns INFLUENCERS-audience challenges too.
- NORMAL_USERS-only challenges disappear.

Disabling is the reverse. Both are idempotent — call as many times as needed.

---

## 8. Rate limits & error patterns

**Check-in guards** (server-side):
- 200m radius (via PostGIS `ST_Distance`).
- 6h per (userId, branchId) cooldown (DB-authoritative).
- 20/hr per user global cap (Redis-backed rolling window).

**Challenge join guards**:
- Challenge must be active + inside its window (`startsAt <= now < endsAt`).
- Audience must match the caller's influencer flag.

All errors return the standard `ApiResponse` shape — surface `response.message` verbatim; the backend produces user-facing copy for challenge/check-in errors.

---

## 9. File map

**DTOs** — `hangout_app/lib/domain/dto/`
- `response/challenge_enums.dart`
- `response/user_points_response.dart`
- `response/user_challenge_progress_response.dart`
- `response/objective_with_progress_response.dart`
- `response/challenge_list_item_response.dart`
- `response/challenge_detail_response.dart`
- `response/check_in_response.dart`
- `request/check_in_request.dart`

Exported through the standard barrels (`response/responses.dart`, `request/requests.dart`) — importing `package:hangout/domain/dto/dto.dart` gives you everything.

**API methods** — `hangout_app/lib/data/api/api_service.dart`, appended to the end (search for "Challenges — Points & Levels" for the section).

**Post-pull step**:

```
cd hangout_app
dart run build_runner build --delete-conflicting-outputs
```

Generates the `.g.dart` files for the 7 new DTOs plus the Retrofit implementations of the 7 new API methods.
