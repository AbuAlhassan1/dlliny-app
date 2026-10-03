# Localization guide

Conventions for adding, editing, and translating strings in the app.
Locked at the close of Phase 0; revisit only via an explicit ADR-style
PR that updates this doc and the call sites it touches.

---

## Stack

| Layer | Choice |
|---|---|
| Package | [`easy_localization`](https://pub.dev/packages/easy_localization) `^3.0.8` |
| Catalogs | `assets/translations/ar.json`, `assets/translations/en.json` (namespaced JSON) |
| Codegen | Type-safe `LocaleKeys` + embedded `CodegenLoader` in `lib/generated/` |
| Persistence | `SharedPreferences` (handled by `easy_localization` via `saveLocale: true`) |
| Server-side bilingual fields | `context.pickBilingual(ar: …, en: …)` extension |

Supported locales: `ar` (default, fallback, RTL) + `en` (LTR). Adding a
third locale means: (1) a new `<code>.json` under `assets/translations`,
(2) register it in `EasyLocalization.supportedLocales` in `main.dart`,
(3) rerun `scripts/regen_locale_keys.sh`.

---

## Phase 0 decisions

### 1. Key naming — namespaced

JSON catalogs are deep JSON objects, **not** flat key/value maps:

```json
{
  "settings": {
    "locale": {
      "title": "اللغة"
    }
  }
}
```

After codegen this becomes `LocaleKeys.settings_locale_title`. The
dotted key string `'settings.locale.title'` is what `.tr()` resolves
against at runtime.

**Why namespaced:** at ~1,500+ keys the flat namespace collides (every
screen has a "Submit", "Cancel", "Loading…"). Namespacing also lets
`grep settings\\. ar.json` show every settings-screen string in one
view — useful for translator handoff.

**Namespace shape:** `<feature>.<surface>.<element>`. Examples:
- `settings.locale.title` — settings screen, locale subsection, title
- `business.transfers.create.cta_submit` — business feature, transfers
  surface, create flow, the primary CTA
- `common.cancel` — shared across screens; lives under `common.`

When unsure, mirror the file path. `lib/presentation/business/transfers/…`
→ keys under `business.transfers.…`. Shared / cross-feature strings →
`common.…`.

### 2. Type-safe codegen

Never write `'settings.locale.title'.tr()` directly. Always use the
generated constant:

```dart
import 'package:hangout/generated/locale_keys.g.dart';

Text(LocaleKeys.settings_locale_title.tr())
```

**Why:** a typo in a stringly-typed key (`'settings.local.title'`)
falls through to `.tr()`'s default behaviour of rendering the key back
out as the displayed string — silent failure at runtime. The generated
constant catches it at compile time. Same defense pattern as
`PermissionsCatalog.validated(…)` for permission codes.

**Regenerate after every JSON edit:**

```bash
./scripts/regen_locale_keys.sh
```

Produces `lib/generated/locale_keys.g.dart` (constants) and
`lib/generated/codegen_loader.g.dart` (embeds the catalogs into the
Dart bundle so there's no async `rootBundle` read at first frame).
Both are committed — devs adding Dart code that references new keys
don't need to run the script first as long as someone ran it after
the JSON change.

### 3. English font — IBMPlexSansArabic

Per the standing memory `feedback_font_family.md`: every `TextStyle`
the assistant authors must set `fontFamily: 'IBMPlexSansArabic'`.

That holds for English locale too — the IBM Plex Sans Arabic family
includes a full Latin glyph set. If English rollout exposes rendering
issues (kerning, weight mismatches) we'll revisit with a per-locale
font override at the theme level — out of scope for Phase 0.

### 4. Arabic gender default — masculine 2nd-person singular

When authoring Arabic strings, default to masculine 2nd-person singular
("اشتراكك" not "اشتراكِكِ"; "تم" not "تمت"). Don't add gender-branching
code paths reading `user.gender`. See `memory/feedback_arabic_gender_default.md`
for the full rationale.

Gender-neutral phrasings are fine when they read naturally; don't
contort sentences to avoid the gendered form.

### 5. Server-side bilingual fields — `context.pickBilingual`

The backend ships bilingual content as paired fields
(`venue.nameAr` / `venue.nameEn`, `category.titleAr` / `category.titleEn`,
etc.). Picking the right side based on the active locale is NOT a job
for `.tr()` — those values aren't in the catalog.

Use the extension at `lib/core/services/bilingual_text.dart`:

```dart
import 'package:hangout/core/services/bilingual_text.dart';

final title = context.pickBilingual(
  ar: venue.nameAr,
  en: venue.nameEn,
);

// With an explicit fallback when both sides may be missing:
final desc = context.pickBilingual(
  ar: venue.descriptionAr,
  en: venue.descriptionEn,
  fallback: LocaleKeys.common_error_generic.tr(),
);
```

**Don't** write:

```dart
// BAD — silent empty render if nameAr is null, locale-detection drift
final isAr = context.locale.languageCode == 'ar';
final title = isAr ? venue.nameAr : venue.nameEn;
```

The helper falls back to the other side when the preferred one is
null/empty (some older venues only have `nameAr`), then to the
explicit `fallback` if both are missing. Never returns null.

Migrate existing `final isAr = context.locale.languageCode == 'ar'`
sites to this helper opportunistically — easier to do during the
feature-by-feature string migration in Phase 2 than as a separate
sweep.

### 6. Locale persistence — `saveLocale: true`

`EasyLocalization` in `main.dart` is configured with `saveLocale: true`.
The user's explicit locale choice persists across cold starts via
`SharedPreferences`. First-launch users see Arabic (the `startLocale` +
`fallbackLocale`). The only mutation path is the locale switcher tile
in Settings calling `context.setLocale(Locale('en'|'ar'))`.

---

## How to add a new string

1. Add the key to the appropriate namespace in `assets/translations/ar.json`.
2. Add the matching key to `assets/translations/en.json`. **Don't ship
   a key in one locale and not the other** — `easy_localization` will
   render the raw key string at runtime when the active locale is
   missing it.
3. Run `./scripts/regen_locale_keys.sh`.
4. Use the generated constant: `LocaleKeys.<namespace>_<key>.tr()`.

For interpolation:

```json
{ "common": { "greet": "أهلاً {name}، عندك {count} رسالة" } }
```

```dart
Text(LocaleKeys.common_greet.tr(namedArgs: {
  'name': user.name,
  'count': unread.toString(),
}))
```

For pluralization, prefer the `easy_localization` `.plural()` form over
hand-rolled string concatenation. (Detailed examples land in Phase 1
once we hit the first real plural — adding here as a placeholder.)

---

## What NOT to use

| Anti-pattern | Use instead |
|---|---|
| `'some.key'.tr()` (stringly-typed) | `LocaleKeys.some_key.tr()` |
| `final isAr = context.locale.languageCode == 'ar'; isAr ? x : y` | `context.pickBilingual(ar: x, en: y)` |
| Hardcoded `'إرسال'` / `'Submit'` literal | `LocaleKeys.common_submit.tr()` |
| Adding a key to `ar.json` only | Add to both `ar.json` AND `en.json` |
| Editing `lib/generated/*.g.dart` by hand | Edit JSON → rerun regen script |
| `if (user.gender == 'female') 'اشتراكِكِ' else 'اشتراكك'` | Pick the masculine form, ship one string |

---

## Roadmap (Phase 1+)

- **Phase 1 — Pilot one surface:** Settings page. Migrate every string,
  add the locale switcher tile UI, lock the convention for plurals /
  interpolation by demonstrating one of each.
- **Phase 2 — Mass migration:** Feature-by-feature sweep of the
  ~1,563 hardcoded Arabic literals across ~259 files. Parallelisable
  once Phase 1 conventions are visible in code.
- **Phase 3 — Polish:** `DateFormat` / `NumberFormat` locale-awareness,
  RTL audit for widgets pinning `Alignment.left` / `EdgeInsets.only(left:)`
  instead of `.start` / `.directional`, backend bilingual contract for
  server-emitted error messages and FCM payloads.
