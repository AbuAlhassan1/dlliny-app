# Memories Feature — Flutter Usage Guide

Everything below assumes the DTOs and `api_service.dart` endpoints from Session 4 are already in place. This guide walks you through how to actually build the UI.

---

## 1. Folder structure

Mirror the chat layout from earlier:

- `lib/data/repositories/memory_repository.dart` — wraps `apiService`, hides retrofit + typed errors
- `lib/data/repositories/memory_upload_repository.dart` — handles the 2-step S3 upload separately (separate Dio without auth interceptor, same pattern as voice notes)
- `lib/presentation/memories/bloc/` — one folder per bloc
- `lib/presentation/memories/screens/` — full-screen widgets
- `lib/presentation/memories/widgets/` — composer pieces, viewer pieces, share preview cards
- `lib/presentation/memories/composer/` — the create-memory editor flow

---

## 2. Repository layer

**`MemoryRepository`** — thin facade over `apiService`. One method per endpoint, unwraps `ApiResponse<T>` to the inner type, throws typed errors. Common ones to define:

- `MemoryExpiredException` — 404 with "Memory not found" (could be expired)
- `MemoryForbiddenException` — 403 from privacy gate
- `EngagementInvalidException` — 400 with payload-shape error from the server
- `MemoryRetentionInvalidException` — 400 from constraint violations

**`MemoryUploadRepository`** — orchestrates the 3 upload slots:
- `uploadImage(File file, String mime) → String key`
- `uploadVideo(File file, String mime) → String key`
- `uploadAudio(File file, String mime) → String key`

Each calls the relevant `getMemory*UploadUrl` endpoint, then PUTs to S3 using a **separate Dio instance with no auth interceptor** (S3 rejects bearer tokens), and returns the key on success.

---

## 3. Blocs you'll need

### `MemoryTrayBloc` (app-root level)
- Drives the horizontal tray at the top of the home feed
- State: `List<MemoryTrayBucket>` + loading/refreshing flags
- Events: `TrayRequested`, `TrayRefreshed`, `BucketWatchedLocally(ownerType, ownerId)` — flips `hasUnwatched` to false locally after viewing the whole stack, without a server roundtrip

### `MemoryViewerBloc(initialBucketIndex)`
- Created when the user taps a tray bubble
- State: the active list of buckets to scroll through, the current bucket index, the current memory index within that bucket, playback progress
- Events: `ViewerOpened`, `NextMemory`, `PreviousMemory`, `NextBucket`, `PreviousBucket`, `ViewRecorded(memoryId)`, `MemoryDeletedLocally(id)` (after own-unsend)
- Disposes when the viewer closes

### `MemoryComposerBloc`
- Created when the user opens the create-memory flow
- State: the picked media (file path or text card config), the selected engagement, the mentions overlay positions, the audio overlay, upload progress
- Events: `MediaPicked`, `TextCardConfigured`, `AudioOverlayPicked`, `MentionAdded/Removed`, `EngagementConfigured`, `PostRequested`
- On post: orchestrates uploads (parallel where possible) then calls `createMemory` / `createVenueMemory`

### `OwnerMemoriesBloc(MemoryOwnerType type, String id)`
- For "open someone's profile → tap their memory ring" outside the tray (i.e., navigating to a stack directly)
- State: a single bucket's memories + their owner summary
- Lighter than the viewer bloc; can be merged into it if you prefer

### `MemoryViewersBloc(String memoryId)` — owner only
- Paginated list of viewers
- Bottom-sheet style — created when the owner swipes up on their own memory

Use **Option A** (BlocListener at the screen level) for cross-bloc communication, same as we did for chat. When a memory is deleted or expires, the viewer bloc emits a "removed" state that the tray bloc listens to and updates its bucket.

---

## 4. Screens / Navigation

**Five primary screens / surfaces**:

1. **Tray on the home feed** — horizontal scroll at the top, NOT a separate screen. Each bubble is `(avatar with gradient ring) + (display name truncated)`. Tap → open Viewer screen. First bubble is "Your memory" + plus icon for the composer.

2. **Memory viewer** — full-screen modal route. Vertical pager between buckets (swipe up/down); horizontal pager within a bucket (tap left half = previous, tap right half = next). Progress bars at top (one segment per memory in the current bucket).

3. **Memory composer** — full-screen route. Three tabs: Photo (camera + gallery), Video (camera + gallery), Text Card. After media selection, you go to the editor screen.

4. **Memory editor** — overlay on top of the composer surface. User adds text overlays, mentions, stickers, optional engagement widget. "Done" triggers the post flow.

5. **Viewers list** (owner) — bottom sheet that slides up from the viewer when owner swipes up. Shows the paginated list of who watched the memory.

6. **Engagement results sheet** (owner) — bottom sheet triggered from the viewer when the owner long-presses their engagement widget. Renders type-specific aggregate (poll counts / quiz correctness / slider histogram / question feed) plus the paginated respondent list. See §9b.

7. **Mentions inbox** — a tab or screen in the user's archive listing active memories where they're tagged. Backed by `getMyMemoryMentions`. Each row is a memory thumbnail + owner avatar + relative timestamp; tap → open the viewer pointed at that memory.

Plus auxiliary surfaces:
- **Venue dashboard "Memory metrics"** — inside the existing business dashboard, render `getVenueMemoryMetrics` per active memory

---

## 5. The tray widget — top of home feed

This is the entry point. Build it as a horizontal `ListView.builder` at the top of your existing home feed (or as a sticky header above the post feed).

**Each bubble**:
- 64×64 circle, owner avatar inside a colored ring
- Ring color: gradient (pink/orange/purple, Instagram-style) if `hasUnwatched`, grey otherwise
- Below: owner display name, truncated to ~10 chars
- Special first bubble: "Your memory" — shows your avatar with a "+" badge if you have no active memories, or your avatar with the ring + tap-to-view if you do

**Behavior**:
- Tap → push the Viewer screen with the tapped bucket's index
- Long-press your own bubble → action sheet ("View viewers", "Delete")
- Pull-to-refresh OR refresh on home feed focus

The tray bloc fetches `getMemoriesTray()` on app start and refreshes on focus. Keep state alive — don't re-fetch every time the home feed mounts.

---

## 6. The viewer — the most complex piece

This is the heart of the feature. Build it in layers.

### Layer A — Bucket pager
A `PageView` with `scrollDirection: Axis.vertical` containing one full-screen page per bucket. Swiping up/down moves between buckets (Instagram-style; you can disable this and only swipe via tap-edges if you prefer simpler UX).

### Layer B — Memory pager (per bucket)
Inside each bucket page, a `PageView` with `scrollDirection: Axis.horizontal` containing one full-screen page per memory in that owner's stack. **But the swipe is fake** — the user actually navigates by:
- Tapping the right half of the screen → next memory
- Tapping the left half of the screen → previous memory
- Long-pressing anywhere → pause progress bar

### Layer C — Per-memory rendering
For the active memory, render based on `contentType`:

- **PHOTO** — full-bleed image with `cached_network_image`, `BoxFit.cover`. The pre-composited overlays (stickers, mentions, text) are baked in.
- **VIDEO** — `video_player` package, autoplay muted (or unmuted depending on system mute state), loop = false. Poster from `mediaThumbnailUrl` shown until video buffers.
- **TEXT** — full-screen container with `backgroundColor` as the solid background and `textContent` rendered large + centered in `textColor`.

If `audioUrl` is non-null, play it in parallel with whatever the visual layer is (one global audio player, same singleton rule as voice notes).

### Layer D — Chrome overlay
On top of every memory:
- **Top**: segmented progress bar — one segment per memory in the bucket, current one animating, prior ones full, future ones empty
- **Top-left**: owner avatar + display name + relative timestamp ("3h")
- **Top-right**: "X" close button, "..." options (delete, mute, report)
- **Bottom**: reaction row + reply bar (if not own memory) OR viewer count + "Seen by X" tap target (if own memory)
- **Mentions overlay**: invisible tappable hit-rects positioned from each `mention.position` field. Server returns `{x, y, scale, rotation}` normalized 0..1 to the rendered canvas — see §16a for the contract. Tap → deep-link to the mentioned user/venue profile.
- **Engagement widget** (if present): rendered as a draggable card the user can move out of the way

### Layer E — Auto-advance
Each memory plays for a fixed duration (5s for PHOTO/TEXT, video's actual duration for VIDEO, capped at 60s). When the progress bar fills, advance to the next memory. At the end of a bucket, advance to the next bucket. At the end of all buckets, close the viewer.

Hold-to-pause stops the progress bar; releasing resumes.

### Layer F — Fire view events
The moment a memory lands on screen (after any debounce — usually ~500ms to avoid recording flick-throughs), dispatch `recordMemoryView(memoryId)`. Server handles the rest (denormalized counters, "viewed by" list, unique-vs-repeat distinction). Throttle so rapid back-and-forth doesn't spam the server.

---

## 7. Reactions

The 6-emoji bar (`👍 ❤️ 😂 😮 😢 🔥`) lives at the bottom of the viewer for non-own memories.

**Behavior**:
- Tap an emoji → optimistically highlight it + dispatch `reactToMemory`. On 4xx, revert and show a snackbar.
- Tap your own current emoji → dispatch `removeMemoryReaction`, revert highlight
- Long-press the emoji bar → an expanded picker (animation polish, defer to v1.1)

**Rendering "my reaction" highlight**: read `memory.reactions.myEmoji`. The matching button gets a glow / pulse animation.

**Rendering aggregate counts**: hidden by default in the viewer (matches Instagram). If you want, show on long-press OR in the owner's viewers list. For v1, just don't display them.

---

## 8. Reply via DM

This is where the chat ↔ memory bridge pays off.

**Behavior**:
- Below the reaction bar (for non-own memories), a text input "Send message" or a paper-plane icon
- Tap → opens a small input overlay or pushes the conversation screen with a pre-filled SHARE message
- On send: `apiService.sendMessage(conversationId, SendMessageRequest.share(resourceType: MEMORY, resourceId: memoryId, caption: typedText))`

**If no conversation with the owner exists yet**: call `createConversation` first with the owner as the peer, then send the share into the returned conversation. (For VENUE owners, same — the conversation is DIRECT with the venue.)

The recipient sees a normal SHARE message in their chat, with a preview card showing the memory's owner + thumbnail. Tapping the card deep-links to the memory (if still active) or shows the grey tombstone.

---

## 9. Engagement widgets — the four types

When `memory.engagement` is non-null, render an interactive widget overlay. The widget's draggable so the user can move it off the photo to interact with it.

### POLL
- Question text at top
- 2-4 option buttons, each showing the option text
- Until the user answers: tap an option → call `respondToMemoryEngagement` with `{optionIndex}` → the option flips to a horizontal bar showing the % of total responses
- After answering: render all options as bars

### QUESTION
- Prompt text at top
- Text input below
- User types and submits → `respondToMemoryEngagement` with `{text}`
- Owner sees responses in the "Results" screen (no endpoint exposed yet — see §16); non-owners see only their own

### SLIDER
- Question text at top
- Horizontal slider 0..100 with the emoji thumb dragging along it
- On release, dispatch the response. UI animation: thumb bounces back to center + average position shows as a faded ghost thumb (if the server returns it; defer aggregation for v1)

### QUIZ
- Question text + options like a poll
- Tap an option → submit
- For non-owner viewers: server scrubs `correctIndex` from `payload` until they respond, then exposes it on the next fetch. After response, render the correct option green, the user's wrong pick (if any) red, others grey.
- For owners: `correctIndex` is always present in the payload (they need it for the results screen and obviously already know the answer). Owner view should still grey out the response buttons since owners can't answer their own quiz.

### Common rules
- **Once submitted, `myResponse` is non-null** — render the post-submit state
- **Owner can't respond** — hide the widget interaction layer when `memory.mine == true`. Show a "View results" button instead that opens the results sheet (§9b).
- **Disable widgets on expired memories** — the viewer will throw 404 on submit anyway, but UX is better if the buttons grey out as the memory nears expiry

---

## 9b. Engagement results sheet (owner)

When the owner long-presses their own engagement widget — or taps "View results" — open a bottom sheet that fetches `getMemoryEngagementResults(memoryId, page, size)`.

Response shape is discriminated by `type` (poll/quiz/slider/question). All variants include:
- `totalResponses` — header count
- `responses` — paginated raw responses with respondent identity (userId, displayName, avatarUrl, verified, their submission, timestamp)

Plus type-specific aggregates:

- **POLL**: `optionCounts: [{optionIndex, count, percentage}]` — render horizontal bars sorted by percentage, longest on top
- **QUIZ**: same as POLL + `correctOptionIndex` + `correctCount` — highlight the correct option, show "X of N got it right" header
- **SLIDER**: `sliderAverage` (float 0..100) + `sliderDistribution` (array of 10 longs, buckets 0-10%, 10-20%, …, 90-100%) — render as a histogram with the average as a marker line
- **QUESTION**: no aggregate; render the paginated responses list as a "Q&A" feed (avatar + name + text + timestamp)

For all types, the `responses` page is independent of the aggregate — you can show "top voters", let the owner tap a respondent to view their profile, etc. Aggregates are computed server-side from ALL responses (not just the page); pagination only affects the list view.

Empty state: `totalResponses == 0` → show "No responses yet" instead of an empty bar chart.

---

## 10. Composer — creating a memory

This is the second-most-complex piece after the viewer.

### Step 1: Source picker
Bottom sheet with three options:
- "Take photo" → camera (image picker)
- "Take video" → camera (max 60s clip)
- "Gallery" → photo OR short video
- "Text card" → directly to the text editor

If they pick text, skip step 2 and go to step 3.

### Step 2: Capture / select
Standard `image_picker` + `image_picker` (video mode) workflow. Capture, get the local file path.

### Step 3: Editor
Full-screen overlay over the media (or solid color for text card). Available tools (build incrementally):
- **Text overlay** — typed text with font picker + color picker. Position is draggable.
- **Mentions** — @username search → dropdown → place the mention as a draggable chip. **Capture the final chip position** (after the user finishes dragging/scaling/rotating) and convert to normalized `{x, y, scale, rotation}` per the §16a contract; this gets sent in the request so the viewer can overlay a tappable hit-rect at the same spot.
- **Music** — picker that uploads an audio file (uses the audio upload-url endpoint), trim UI to pick a 60s slice
- **Engagement widget** — picker: Poll / Question / Slider / Quiz → fill in the config → place the widget on the canvas
- **Stickers** — defer to v1.1 (lots of asset management)
- **Drawing** — defer to v1.1

The editor is local-only state until "Post". The mention chip's visual is composited into the final image alongside everything else; the position blob is what makes it tappable post-post.

### Step 4: Render the final media (PHOTO/VIDEO only)
Before upload, composite all overlays into the image/video. Use `screenshot` package for photos. For videos, you'll need `ffmpeg_kit_flutter` to bake overlays into a re-encoded MP4. **This is the hardest single piece of the feature** — budget 2 days for video composition alone.

For text cards: no compositing needed, just send the textContent + backgroundColor + textColor.

### Step 5: Post
1. Upload composited media via `MemoryUploadRepository.uploadImage` or `.uploadVideo`. Get the key.
2. If music attached, upload audio in parallel via `.uploadAudio`.
3. If video, also generate a poster frame (first frame or thumb) and upload via `.uploadImage`.
4. Once all uploads complete, call `createMemory` (or `createVenueMemory` for venue posts) with all the keys + mentions + engagement.
5. On success: pop back to home, show the user's tray bubble freshly added.

Show a progress bar during uploads. The user can swipe away and your bloc keeps uploading in the background — show a small "Posting..." pill at the top of the home feed until done.

---

## 11. Venue posting

If the user has venue access:

- The composer screen gets a "Post as" picker at the top — choose between "You" (personal) and any venue you have `venue:memories:create` for
- On post, route to `createVenueMemory(venueId, ...)` instead of `createMemory(...)`
- The resulting memory's `owner.type` will be VENUE on the next tray refresh

For the "which venues can I post as" question — use the existing `getMyAccess()` endpoint that returns the user's venue access graph. Filter for venues where the effective permission set includes `venue:memories:create`.

---

## 12. Long-press / options menu

Behavior matrix:

**On your own memory**:
- See viewers (opens bottom sheet with `getMemoryViewers` paginated)
- See metrics (only for venue memories — opens dashboard or inline view of `getVenueMemoryMetrics`)
- Delete (confirms, calls `deleteMemory` or `deleteVenueMemory`)
- Save to gallery (download the media URL — client-only feature)

**On someone else's memory**:
- Mute owner (no endpoint yet — defer)
- Report (use the existing report system once we wire it for memories)
- Save (download — client-only)

---

## 13. Push notifications integration

Backend wires two FCM event types for memories:

- **`MEMORY_MENTIONED`** — fires once per (memory × mentioned user/venue) on post. Title: "Memory Mention" / "ذكر في ذكرى". Body: "{actor} mentioned you in a memory".
- **`MEMORY_REACTED`** — fires only on a viewer's *first* reaction to a memory (emoji changes and removals are silent). For USER-owned memories the push goes to the owner; for VENUE-owned, it routes to the venue's business owner via `business_venue_access`. Title: "New Reaction". Body: "{actor} reacted {emoji} to your memory".

Self-reactions and self-mentions are skipped server-side — you never get pushes from yourself.

In the Flutter notification handler:
- Detect `type: MEMORY_MENTIONED` or `type: MEMORY_REACTED` in the FCM data payload
- Both deep-link to `hangout://memory/{memoryId}` → push the viewer screen pointed at that single memory (single-memory mode — no bucket scroll). Just call `getMemory(memoryId)` and show it solo.
- For `MEMORY_REACTED`, you may want to auto-scroll the viewer to the reactions row so the user sees the new reaction highlighted

If the memory has expired between the push and the tap, the GET returns 404 — show a graceful "This memory is no longer available" snackbar.

---

## 14. State management around expiry

Memories die after 24 hours. UX implications:

- **Tray buckets**: filter out empty buckets on read. The server doesn't return any for owners with zero active memories.
- **Open viewer**: if a memory expires while you're watching its bucket, the response on the next `recordMemoryView` will be 404 — gracefully advance to the next memory.
- **Pending sends**: if a user starts composing and walks away for hours, your local "Posting..." pill can become stale. Hide it after ~30 min of no progress.
- **Chat share cards** pointing to memories: when the memory expires, the SHARE bubble's preview card shows `available: false` and renders a grey tombstone automatically — no client logic needed beyond rendering the flag.

---

## 15. Performance / battery considerations

- **Tray rendering**: 20-50 buckets is normal. Each bucket carries 1-N memories with full hydration. The first response is heavy (≈5-20KB per bucket). Cache the response in the bloc and trust the unwatched count for delta decisions.
- **Video memory cleanup**: the video controller holds RAM. Dispose between buckets. Use `cached_network_image` for poster frames, never preload videos beyond the next memory in the current bucket.
- **Audio overlays**: one global audio player; mute when the screen backgrounds.
- **Auto-advance timer**: pause when the app goes to background — Flutter's lifecycle observer handles this.

---

## 16. Things deferred

These are reachable from the backend but no Flutter UI yet:
- **"My past memories" archive** — by design (no highlights, no archive in v1).
- **Music library** — only user-uploaded audio is supported. No licensed-music library.
- **Animated stickers / drawing tools** — v1.1.

These now have backend endpoints — build the UI when you're ready:
- ✅ **Engagement results sheet** → `getMemoryEngagementResults` (covered in §9b)
- ✅ **Mentions inbox tab** → `getMyMemoryMentions` — paginated active memories tagging you. Renders as a vertical list with the standard memory thumbnails + owner row; tap → opens the viewer pointed at that memory.
- ✅ **Reaction push notifications** → backend fires `MEMORY_REACTED`; handler in §13.

---

## 16a. Mention position contract

When you place a mention chip in the composer, send its final transform alongside the user/venue id. Shape sent in `MemoryMentionInput.position`:

```
{
  "x":        0.0..1.0,   // left-edge of chip, normalized to canvas width
  "y":        0.0..1.0,   // top-edge of chip, normalized to canvas height
  "scale":    0.1..3.0,   // chip size multiplier (1.0 = default)
  "rotation": -180..180   // degrees, clockwise
}
```

Normalization is to the **rendered canvas** (longest edge), not to device pixels — same chip works on every screen size.

If you set `position: null`, the mention is still persisted and still fires a notification, but the viewer can't render a tappable hit-rect (it shows a non-positional "Mentioned" chip somewhere generic instead). Default to always sending position when the user actually places a chip.

When rendering the viewer:
- For each `mention` in `memory.mentions` where `position != null`, overlay a transparent `GestureDetector` at the computed pixel rect. Tap → deep-link to the mentioned user/venue.
- For `position == null` entries, optionally render a small "Mentioned: @sara, @ali" chip at the bottom of the viewer (or drop entirely — your UX call).

---

## 17. Suggested build order

If you have 2 weeks for Flutter:

| Day | Output |
|---|---|
| 1 | `MemoryRepository` + `MemoryUploadRepository` + `MemoryTrayBloc` + tray widget on home feed |
| 2 | `MemoryViewerBloc` + viewer screen scaffolding + PHOTO rendering + view recording |
| 3 | VIDEO rendering + TEXT card rendering + auto-advance + progress bars |
| 4 | Reactions bar + reply-via-DM flow |
| 5 | Composer: source picker + media capture + basic photo/text post (no overlays) |
| 6 | Composer: text overlay + mention picker + final compositing (photo only) |
| 7 | Composer: VIDEO compositing with ffmpeg_kit |
| 8 | Composer: audio overlay + engagement widget config |
| 9 | Engagement widget rendering in viewer (all four types) |
| 10 | Venue posting flow + venue dashboard metrics |
| 11 | Owner viewers list + engagement results sheet + delete + long-press menu |
| 12 | Mentions inbox tab + tappable mention overlays in viewer |
| 13 | Polish + edge cases + expired-memory handling |
| 14 | Push notification deep links (mention + reaction) |
| 15 | Buffer for the unexpected |

After day 14 you have a usable v1. Polish, drawing, stickers, and engagement-results screen come in v1.1.

---

## 18. Things you DON'T need to handle

- **24h expiry locally** — server enforces. Local clocks lie; trust the server.
- **View counts** — server returns `viewCount` and `uniqueViewerCount` on `MemoryResponse`. Don't recompute.
- **Tray ordering** — server sorts: mine first, then unwatched-first, then chronological.
- **Privacy gates** — server enforces. If you get 403, the user can't see this owner's content; surface gracefully.
- **Engagement payload validation** — server enforces. Just send what the user typed.
- **Mention text** — bake into the composited image client-side; server stores only IDs for notification fanout, not positions.
- **Composite preview** — what you see in the editor IS what gets posted. No server transformation.

---

That's the entire picture. Whenever you're ready to start, **Day 1 (tray + repos)** is the smallest milestone that gets something on screen — pretty bubbles, hooked to real data, no viewer logic yet.
