# Reels Flow

Short doc for the reels feed — a 9:16-aspect-ratio post stream weighted toward venue content. Backend-only.

---

## 1. What It Is

A third tab alongside Following and For You. Same `PagedResponse<FeedItem>` envelope as the other feeds, but:

- **Posts only.** No hangouts. Reels are a swipeable vertical stream — date/RSVP semantics don't belong here.
- **9:16-shape.** A post qualifies if **at least one** of its media items has an aspect ratio in the 9:16 band (`0.55 ≤ aspectRatio ≤ 0.58`). Video and image media both count — what defines a "reel" is the vertical shape, not the media type.
- **Full post returned.** A qualifying post ships **all** its media, not just the 9:16 items. A mixed carousel (one 9:16 cover + several 4:5 images) renders as the entire post; the client decides how to display the non-vertical items.
- **Venue-weighted.** Venue-authored reels rank above user-authored ones of comparable age — but user reels are NOT excluded.
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

All items are `PostFeedItem`. No `HangoutFeedItem` will ever appear in this response. Each `PostFeedItem.mediaUrls` carries every media item belonging to the post, in `sort_order`, with `aspectRatio` so the client can size each one.

---

## 3. Query

[`PostRepository.findReelsPosts`](hangout_api/hangout-domain/src/main/java/com/beestar/hangout/domain/repository/post/PostRepository.java):

```jpql
SELECT p FROM Post p
LEFT JOIN p.user u
WHERE p.active = true
AND p.hidden = false
AND EXISTS (
    SELECT 1 FROM PostMedia pm
    WHERE pm.post = p
      AND pm.aspectRatio IS NOT NULL
      AND pm.aspectRatio BETWEEN 0.55 AND 0.58
)
AND (
    u IS NULL
    OR (
        u.id NOT IN (... block filter A ...)
        AND u.id NOT IN (... block filter B ...)
        AND (
            u.privateAccount = false
            OR u.id = :viewerId
            OR u.id IN (SELECT followee FROM Follow ...)
        )
    )
)
ORDER BY p.createdAt DESC
```

The `EXISTS` subquery on `post_media.aspect_ratio` in the 9:16 band is the only delta vs. `findPublicPostsForYouFeed`. 9:16 = 0.5625 exactly; the `0.55–0.58` band catches client-measured ratios that round slightly (1080/1920 vs. 720/1280 etc.) without spilling into adjacent vertical ratios like 4:5 (0.8) or 2:3 (0.667). `LEFT JOIN p.user u` is the same Hibernate workaround the For You query uses — without it, venue-only posts (with `user_id IS NULL`) get silently filtered out by an implicit INNER JOIN.

---

## 4. Scoring

[`FeedServiceImpl.reelsScore`](hangout_api/hangout-feed/src/main/java/com/beestar/hangout/feed/service/impl/FeedServiceImpl.java):

```java
recency = 1.0 / (hoursOld + 2.0)^1.5
if (venue-authored) recency *= 1.5
```

| Post age | User reel | Venue reel |
|---|---|---|
| 0h  | 0.177 | 0.265 |
| 6h  | 0.062 | 0.094 |
| 24h | 0.020 | 0.030 |

A 0-hour-old venue reel outranks a 0-hour-old user reel. A fresh user reel still beats a stale venue one (e.g. a 0h user reel at 0.177 beats a 6h venue reel at 0.094). The `1.5` boost is the single tuning knob — change it in one place if the venue/user mix needs to shift.

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

- **Memories in the pool.** 24h ephemeral 9:16 content would slot naturally; just union them into the source list and use the same scoring.
- **Engagement signal.** Score could blend in likes/comments velocity, not just recency.
- **Dedicated REELS impression type.** Lets analytics distinguish reels engagement from feed engagement.
- **Cursor-based pagination.** Current page/size paginates a pre-fetched window; fine for v1 but fragile if the underlying ordering shifts between pages.
- **Cover-media flag.** A `PostFeedItem.mediaUrls[i].isReelCover` boolean (or just sort the 9:16 media item to position 0) so the client knows which media to autoplay when the post is a mixed carousel. Today the client has to scan for the first 9:16 item itself.
