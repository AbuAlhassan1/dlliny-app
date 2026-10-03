# Subscriptions — Backend Follow-Ups + Flutter Counterparts

Companion to `FLUTTER_SUBSCRIPTIONS.md`. That doc describes how the Flutter app consumes the subscription system as it exists today. This doc lists the **un-solved risks** in the current contract and the **backend changes** that would close them, paired with the **Flutter changes** that would land once each backend item ships.

Scope: the Flutter app gates UI on subscription permissions returned from `/api/v1/subscriptions/me`. Today the only gated feature is `business:create:multiple`, but the infrastructure is positioned to gate more. The risks below become material as more features hook in.

---

## Why this doc exists

`FLUTTER_SUBSCRIPTIONS.md` flags four risks and proposes mitigations. Two of them are solved cleanly by following the recommended path; two are "documented but not mechanically enforced". This doc focuses on the two un-solved risks plus two un-mentioned ones, and lists what the backend can do to make the un-solved bits mechanical instead of best-practice.

| Risk | Solved by current doc? | Notes |
|---|---|---|
| Snapshot vs tier permissions confusion | ❌ documented only | Two DTOs ship identical-looking `permissions` fields with different semantics. |
| String permission typos / drift | ❌ documented only | Mitigation is "centralize constants" — helps in-Flutter drift, doesn't help Flutter↔backend drift. |
| JWT lag on grant/expiry | ✅ for client UI<br/>❌ for server gating | `/me` is filtered server-side so client UI is fine. Server `@PreAuthorize` checks still trust the stale JWT. |
| Multi-sub "primary plan" pick | ⚠️ punted to Flutter | API gives raw list; client picks. Doc suggests "most recent" as the default. |

Plus two items the current doc doesn't mention:

- **`/me` failure mode** (network error → fail closed; paid user loses CTAs silently).
- **Permission i18n labels** (today: hardcoded in Flutter — drift risk between marketing copy and code).

---

## Risk 1 — Snapshot vs tier-permissions confusion

### The risk

Two DTOs both expose `permissions: List<String>` with different meanings:

- `SubscriptionTierResponse.permissions` — the tier's **current** permissions (catalog state).
- `MySubscriptionResponse.permissions` — the permissions **snapshotted at grant time** for one user.

`FLUTTER_SUBSCRIPTIONS.md` (lines 123, 267) is loud about which one to use where, but nothing prevents a developer from rendering the tier's list under "your plan includes …", which would be wrong any time tier perks have changed since the grant.

### Backend fix — minimal

Rename the field on the catalog DTO so the two shapes don't look identical at a glance:

```jsonc
// Before
{
  "id": "pro_v1",
  "name": "Pro",
  "permissions": ["business:create:multiple", ...]
}

// After
{
  "id": "pro_v1",
  "name": "Pro",
  "snapshotOnGrant": ["business:create:multiple", ...]
}
```

Cost: a one-line Java rename + a Jackson alias for back-compat. Makes the wrong call site fail at code review.

### Backend fix — better

Split the catalog DTO into a marketing-facing shape and remove raw permission codes from catalog responses entirely:

```jsonc
{
  "id": "pro_v1",
  "name": "Pro",
  "price": 9.99,
  "billingPeriod": "monthly",
  "featuredPerks": [
    {
      "code": "business:create:multiple",
      "labelAr": "إدارة عدة منشآت",
      "labelEn": "Manage multiple businesses",
      "descriptionAr": "…",
      "descriptionEn": "…"
    }
  ]
}
```

`MySubscriptionResponse` keeps the raw `permissions: List<String>` snapshot. There's now exactly one place in the API where raw permission codes are returned to the client for self-display purposes. Closes the foot-gun mechanically.

### Flutter counterpart

- Update `SubscriptionTierResponse` DTO to drop `permissions` (or rename to `snapshotOnGrant`).
- Plan-card widgets read `featuredPerks[i].labelAr` instead of synthesising labels from raw codes.
- Settings tile "ما يتضمنه اشتراكك" iterates `MySubscriptionResponse.permissions` (unchanged).

---

## Risk 2 — Typos / Flutter↔backend drift on permission strings

### The risk

Permissions are raw strings. `subState.has('business:create:multipel')` compiles and returns `false` for everyone. Centralising constants on the Flutter side helps in-Flutter drift, but a backend rename (`business:create:multiple` → `business:multi-create`) silently breaks every call site without a single compile error.

`FLUTTER_SUBSCRIPTIONS.md` (line 269) acknowledges this but the mitigation is "convention".

### Backend fix — three escalating options

**1. Permission catalog endpoint (cheap, high ROI).** Expose every known permission code in one place:

```http
GET /api/v1/permissions/catalog

200 OK
[
  {
    "code": "business:create:multiple",
    "labelAr": "إدارة عدة منشآت",
    "labelEn": "Manage multiple businesses",
    "descriptionAr": "…",
    "descriptionEn": "…"
  },
  …
]
```

Source: the set of all permission codes the server's `@PreAuthorize` actually checks for + any extras only used in tier definitions. The backend maintains one source of truth; the catalog is just a serialisation of it.

**2. Write-side validation on tier definitions (cheap, complementary).** Reject `tier.permissions` containing codes not in the registered catalog at the admin-grant / tier-edit endpoint:

```
POST /api/v1/admin/subscriptions/tiers
Body: { ..., "permissions": ["business:create:multipel"] }

400 Bad Request
{ "error": "Unknown permission code: business:create:multipel" }
```

Stops admin-side drift from sneaking into the DB. Independent of the client.

**3. Codegen contract (heavier, definitive).** Publish either OpenAPI or a `permissions.json` build artifact that Flutter consumes via `build_runner` (or similar) to generate `SubscriptionPermissions` constants. Once shipped, a backend rename forces a regenerate which forces compile errors in Flutter — drift becomes a compile-time error, not a runtime one.

For this app today, options 1 + 2 together close the practical risk. Option 3 is worth setting up once there are ~10+ permission codes.

### Flutter counterpart

For options 1 + 2:

```dart
// Generated/maintained from /permissions/catalog at app start
class SubscriptionPermissions {
  static const businessCreateMultiple = 'business:create:multiple';
  // ...
}

class PermissionsCatalog {
  static Set<String> _known = const {};
  static void hydrate(List<PermissionCatalogEntry> entries) {
    _known = entries.map((e) => e.code).toSet();
  }

  /// Dev-mode guard. In release builds asserts are stripped, so this
  /// is free in production but catches typos in debug + tests.
  static String validated(String code) {
    assert(_known.contains(code), 'Unknown permission code: $code');
    return code;
  }
}

// Call site
final canCreateMultiple = subState.has(
  PermissionsCatalog.validated(SubscriptionPermissions.businessCreateMultiple),
);
```

For option 3, the Flutter generator replaces the hand-maintained `SubscriptionPermissions` class.

---

## Risk 3 — JWT lag on grant/expiry, `/me` ↔ JWT divergence

### The risk

The JWT's `permissions` claim is computed at token-issue time and frozen until the next refresh. Two failure modes:

- **Admin just granted a sub** → `/me` reflects it immediately, but the user's JWT was issued before the grant and doesn't carry the perm. Client UI gated by `/me` shows the gated CTA; the server's `@PreAuthorize` 403s on tap because the JWT is stale. UX: "I see the button but it doesn't work."
- **Cron just expired a sub** → `/me` no longer returns the row (server-side filter), but the JWT still has the perm. Server's gating endpoint accepts the call. UX: "Ghost permission" for up to one JWT TTL after expiry.

`FLUTTER_SUBSCRIPTIONS.md` (line 277) acknowledges both and points at "force token refresh" as the escape hatch — but doesn't say when to trigger it.

### Backend fix — the standard pattern

**Add `users.token_version` (INT, default 0).** Bump it on every subscription change:

- Admin grants a subscription → bump.
- Admin cancels a subscription → bump.
- Cron flips `active` → `expired` → bump.

Embed `tokenVersion` as a claim in the JWT at issuance. The server's auth filter validates `jwt.tokenVersion == user.token_version` on every authenticated request. Mismatch → return `401` with a distinct error code (e.g., `"token-stale"`):

```http
401 Unauthorized
{ "status": "ERROR", "error": "token-stale" }
```

Client interprets this specific code as "silently call `/auth/refresh` and retry the original request once". On refresh, the new JWT carries the current `tokenVersion` and the merged subscription permissions are fresh.

### Backend fix — cheaper stopgap

Shorten the access-token TTL. Today TTL determines the upper bound on "ghost perks" and on "newly-granted-but-not-yet-effective" windows. Going from a long TTL (~hours) to ~15 minutes paired with a refresh token bounds both windows without per-event invalidation. Less elegant; ships in an afternoon.

### Flutter counterpart

For the `tokenVersion` pattern:

- Existing fresh-token interceptor (the project uses `fresh_dio`) already handles 401-driven refresh. Wire a small filter on the response that recognises the `"token-stale"` error code and triggers the same refresh path, retrying the request once on the new token.
- Optionally: on receiving a `MySubscriptionResponse` that contains a permission the current JWT doesn't, proactively call `/auth/refresh` rather than waiting for the next gated tap to 401.

For the shorter-TTL stopgap: no Flutter change needed — the existing refresh-on-401 plumbing handles it.

---

## Risk 4 — "Primary plan" pick rule

### The risk

A user can hold multiple active subscriptions. `MySubscriptionResponse[]` is the wire shape. The doc punts "which one is 'my plan'?" to the client — its example picks "most recently started", but that's a UX guess.

### Backend fix

Two options, both small:

**1. Return `primary: bool` on each row.**

```jsonc
{ "id": "…", "tierName": "Pro", "primary": true,  "permissions": [...] }
{ "id": "…", "tierName": "Plus", "primary": false, "permissions": [...] }
```

Server picks by whatever rule the platform team standardises on (most recent, highest priced, etc.). Client reads `subs.firstWhere((s) => s.primary)`. Backwards-compatible — older clients see `primary` default to `false` and use their own pick logic.

**2. Add `GET /api/v1/subscriptions/me/primary`** returning a single object (or `204 No Content` when none). The raw `/me` list endpoint stays for "all my plans" / debug. Client never has to merge.

Pick depending on whether the client ever needs to enumerate all subs (option 1 keeps the list shape; option 2 explicitly bifurcates).

### Flutter counterpart

Drop the `primaryTierName` helper's "sort by `startedAt`" logic. Read `s.primary` (option 1) or hit `/me/primary` once for the surface that needs it (option 2). Either way the UX behaves consistently with whatever rule the backend picks; we stop hardcoding a UX assumption in two places.

---

## Risk 5 — `/me` failure mode

### The risk

`getMySubscriptions()` can fail (network, server 500). Today's recommended approach defaults the cache to empty on failure → fail-closed → a paid user loses access UI to features they're entitled to until the next successful fetch.

`FLUTTER_SUBSCRIPTIONS.md` doesn't mention this.

### Backend fix

Largely a client concern, but the backend can help by:

- **Returning the latest `MySubscriptionResponse[]` in the auth refresh response itself.** When the client refreshes its JWT, the response body includes the user's current subscriptions. The Flutter side already has a refresh-token flow; piggy-backing the sub list on it gives the client a high-uptime path to the same data (refresh fails → user is logged out anyway, so subscription staleness becomes irrelevant).

- **Returning the merged permission list in the JWT claim** (it already does — this is a reminder to lean on it as a secondary cache, not a replacement). When `/me` fails, the client can fall back to "do I have this perm in my JWT" as a degraded but functional gate.

### Flutter counterpart

- Treat `getMySubscriptions()` failure as **stale, not absent**. Keep the prior cached state if any; only flip to "no active subs" after a clean 200-with-empty-list response.
- Surface a small "couldn't verify your plan, retry" affordance somewhere users can self-recover (settings → subscription tile).

---

## Risk 6 — Permission labels / marketing copy live in Flutter

### The risk

`business:create:multiple` is a permission code; "إدارة عدة منشآت" is the marketing label. Today: hardcoded in Flutter. Means:

- Marketing copy changes require a Flutter release.
- Adding a new permission requires synced backend + Flutter releases.
- i18n drift is possible (different labels in different locales of the app).

`FLUTTER_SUBSCRIPTIONS.md` doesn't mention this.

### Backend fix

The permission-catalog endpoint from Risk 2 doubles as the source of truth for marketing copy:

```jsonc
GET /api/v1/permissions/catalog

[
  {
    "code": "business:create:multiple",
    "labelAr": "إدارة عدة منشآت",
    "labelEn": "Manage multiple businesses",
    "descriptionAr": "ادر أكثر من منشأة واحدة من حساب واحد.",
    "descriptionEn": "Run more than one business from a single account."
  }
]
```

Schema: a small `permissions` table with `code`, `labelAr`, `labelEn`, `descriptionAr`, `descriptionEn`. Admin-editable; client cached for ~24h.

### Flutter counterpart

- Subscription state holder includes a `Map<String, PermissionCatalogEntry>` keyed by code.
- Plan cards, "your plan includes…" lists, and upgrade banners all source labels from the catalog instead of hardcoded `'إدارة عدة منشآت'` literals.
- Falls back to the raw code (or a generic "Premium feature") if the catalog entry is missing.

---

## Suggested sequence

Independent items; each ships on its own. Ordered by ROI for this app's current state:

1. **`SubscriptionTierResponse.permissions` → `snapshotOnGrant`** (or full split into `featuredPerks`). Closes Risk 1. Trivial.
2. **`GET /api/v1/permissions/catalog` + write-side validation on tier perms.** Closes Risk 2 functionally + sets up Risk 6's label source. Small backend ticket.
3. **`primary: bool` on `MySubscriptionResponse`.** Closes Risk 4. One-line schema-derivation change.
4. **`users.token_version` + bump on subscription mutations + `"token-stale"` 401 contract.** Closes Risk 3. The heaviest item — touches token issuance + auth filter — but the impact for the platform goes beyond subscriptions (anywhere permission state changes mid-session benefits).

The first three are afternoon tickets each. The fourth is a sprint item but pays off across the platform.

---

## Flutter changes that ship today, no backend dependency

Independent of the above, the Flutter app should:

- Build a `SubscriptionBloc` holding `List<MySubscriptionResponse>` with `has(String)` + `primaryTierName` accessors.
- Maintain a `SubscriptionPermissions` constants class. Keep it minimal until the backend ships the catalog endpoint.
- Wire the actual client-side gate on `ConvertToBusinessAccountBloc`: don't let the user fill out + submit the "register a business" form when they already have one and lack `business:create:multiple`. Today the server 403s after submission — bad UX.
- Add a "اشتراكي" tile to the settings page sourcing `MySubscriptionResponse.tierName` for the headline + `MySubscriptionResponse.permissions` for "ما يتضمنه".
- Treat `getMySubscriptions()` failure as stale (keep prior cache), not absent.

Once Risk 2's catalog ships, the constants class is replaced by the catalog-validated version (Risk 2's Flutter counterpart section).

---

## Cross-references

- Main spec: `FLUTTER_SUBSCRIPTIONS.md`
- Backend admin grant flow: `ADMIN_DASHBOARD_GUIDE.md`
- Schema: `V31__create_subscriptions.sql`
- Server-side wiring:
  - `SubscriptionController` (`hangout-user`) — public + `/me` endpoints
  - `AdminSubscriptionController` (`hangout-admin`) — admin CRUD + grant + cancel
  - `AuthServiceImpl.generateToken` — where subscription permissions merge into the JWT
  - `SubscriptionMaintenanceScheduler` — flips expired rows to `expired` status
  - `BusinessRequestServiceImpl:41` — current example of a subscription-gated endpoint
