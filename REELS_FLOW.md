# Reels Flow

Short doc for the reels feed — a video-only post stream weighted toward venue content. Backend-only.

---

## 1. What It Is

A third tab alongside Following and For You. Same `PagedResponse<FeedItem>` envelope as the other feeds, but:

- **Posts only.** No hangouts. Reels are a swipeable video stream — date/RSVP semantics don't belong here.
- **Video-only.** Every returned post has at least one `post_media` row with `media_type = 'video'`. Image-only posts never appear.
- **Venue-weighted.** Venue-authored videos rank above user-authored ones of comparable age — but user videos are NOT excluded.
- **Same visibility rules as For You.** Block filters apply, private accounts are hidden unless the viewer follows them, `active=true AND hidden=false` only.

---

## 2. Endpoint

```
GET /api/v1/feed/reels?page=0&size=10
```

| Param | Type | Default | Notes |
|---|---|---|---|
| `page` | int | 0 | Zero-indexed |
| `size` | int | 10 | Smaller than the other feeds (20) — reels are heavier per-item to render |

Authority: `hasRole('USER')` — same as the other feeds.

Response:

```json
{
  "success": true,
  "data": {
    "items": [
      { "type": "POST", "id": "...", "authorVenueId": "...", "authorVenueName": "...",
        "mediaUrls": [{"type": "video", "url": "..."}], ... }
    ],
    "nextCursor": "1",
    "hasMore": true
  }
}
```

All items are `PostFeedItem`. No `HangoutFeedItem` will ever appear in this response.

---

## 3. Query

[`PostRepository.findVideoPostsForReels`](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/post/PostRepository.java):

```jpql
SELECT p FROM Post p
WHERE p.active = true
AND p.hidden = false
AND EXISTS (
    SELECT 1 FROM PostMedia pm
    WHERE pm.post = p AND pm.mediaType = 'video'
)
AND (
    p.user IS NULL
    OR (
        p.user.id NOT IN (... block filter A ...)
        AND p.user.id NOT IN (... block filter B ...)
        AND (
            p.user.privateAccount = false
            OR p.user.id = :viewerId
            OR p.user.id IN (SELECT followee FROM Follow ...)
        )
    )
)
ORDER BY p.createdAt DESC
```

The `EXISTS` subquery on `post_media.media_type = 'video'` is the only delta vs. `findPublicPostsForYouFeed`.

---

## 4. Scoring

[`FeedServiceImpl.reelsScore`](hangout_api/hangout-feed/src/main/java/com/beestar/hangout/feed/service/impl/FeedServiceImpl.java):

```java
recency = 1.0 / (hoursOld + 2.0)^1.5
if (venue-authored) recency *= 1.5
```

| Post age | User video | Venue video |
|---|---|---|
| 0h  | 0.177 | 0.265 |
| 6h  | 0.062 | 0.094 |
| 24h | 0.020 | 0.030 |

A 0-hour-old venue video outranks a 0-hour-old user video. A fresh user video still beats a stale venue one (e.g. a 0h user video at 0.177 beats a 6h venue video at 0.094). The `1.5` boost is the single tuning knob — change it in one place if the venue/user mix needs to shift.

---

## 5. Analytics

Every item shown on the page records a `FEED` impression on the venue ([`AnalyticsImpressionService.Type.FEED`](hangout_api/hangout-infrastructure/src/main/java/com/beestar/hangout/infrastructure/service/AnalyticsImpressionService.java)) — same fan-out as the For You feed. If reels engagement needs to be measured separately later, add a `REELS` enum value and pass it to `recordFeedImpressions`.

For user-authored posts the venue is `null` and no impression is recorded.

---

## 6. Files

| File | Role |
|---|---|
| [PostRepository.java](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/post/PostRepository.java) | `findVideoPostsForReels` query |
| [FeedService.java](hangout_api/hangout-feed/src/main/java/com/beestar/hangout/feed/service/FeedService.java) | Interface — `getReels` |
| [FeedServiceImpl.java](hangout_api/hangout-feed/src/main/java/com/beestar/hangout/feed/service/impl/FeedServiceImpl.java) | Implementation + `reelsScore` |
| [FeedController.java](hangout_api/hangout-feed/src/main/java/com/beestar/hangout/feed/controller/FeedController.java) | REST endpoint |

---

## 7. Future Tweaks (not shipped)

- **Memories in the pool.** 24h ephemeral videos would slot naturally; just union them into the source list and use the same scoring.
- **Engagement signal.** Score could blend in likes/comments velocity, not just recency.
- **Dedicated REELS impression type.** Lets analytics distinguish reels engagement from feed engagement.
- **Cursor-based pagination.** Current page/size paginates a pre-fetched window; fine for v1 but fragile if the underlying ordering shifts between pages.
