# CreditVance — Backend Requirements & Suggestions

These findings come from testing the live API while redesigning the app. Each item lists the current behaviour, what the app does today as a workaround, and the change being requested.

> Hard rule: none of these endpoints may accept a PAN, CVV or full expiry. They stay on-device.

## P0 — Correctness

### 1. Advisor ignores `is_international`
- **Now:** `/advisor/recommend` returns the same rate (e.g. 31%) whether or not `is_international` is true.
- **App workaround:** the on-device ranker deducts `forex_markup × 1.18` (GST included) for international spends.
- **Ask:** apply the forex markup (and any international earn rates) on the server, and return a `forex_markup_applied` field.

### 2. Advisor for guests / explicit card list
- **Now:** unauthenticated calls return `top_recommendation: null` and an empty `alternative_cards` list. Only `market_benchmark_card` is populated.
- **App workaround:** guests are ranked on-device.
- **Ask:** accept an optional `card_ids: [int]` in the body, so that ranking works without a wallet stored on the server.

### 3. Card detail content is empty
- **Now:** `available_tabs: []`, `overview_text: null`, `apply_link: null` and `card_image_url: null` for every card sampled. `/cards/{slug}/tabs/*` returns 404.
- **App workaround:** detail sections fall back to highlights, lounges and benefits, and hide when empty.
- **Ask:** populate these fields. The app already renders them: tab sections with earn rates, overview "read more", the apply CTA, and the card image.

## P1 — Features the app is ready for

### 4. Reward calculator data
- **Ask:** add these to card detail:
  - `fee_waiver_spend` (annual spend at which the renewal fee is waived);
  - per-category earn rates `[{category_slug, rate_percent, cap_monthly}]`;
  - `point_value_inr`.
- Today the app uses curated rates for 4 cards and `return_min_percent` for everything else.
- **Optional:** add `POST /calculator/annual` with a body of `{card_id, monthly_spend: {category_slug: amount}}` that returns a per-category breakdown, fee, waiver status and net value.

### 5. Profile & account
- `PATCH /auth/me` for `full_name` (the Account screen is ready for editing the name).
- `POST /auth/refresh` with refresh tokens. A 401 currently signs the user out.
- `POST /auth/password/forgot` and `POST /auth/password/reset`.
- `DELETE /auth/me` for in-app account deletion. Required by Google Play and the App Store.

### 6. Wallet
- Add `sort_order` to user cards, and a `PUT /wallet/order` endpoint that takes `{ids: [int]}`. Drag-to-reorder currently persists on-device only.
- Add `statement_day` and `due_day` to user cards (`billing_cycle_day` exists but is not echoed back consistently).
- Add `updated_at` to user cards, so offline edits can be reconciled.

### 7. Catalog
- Add filters `has_lounge=true` and `lounge_type=INTERNATIONAL_LOUNGE`, and sorts `annual_fee_asc` and `return_desc`, to `/cards`.
- Return the applied filters in `meta` so the app can show them.
- The paging meta (`total`, `page`, `has_next`) works well. Please keep it consistent on filtered queries.

## P2 — Nice to have

- **Due-date reminders:** a device-token registration endpoint plus push (FCM/APNs) for statement and due-date reminders. Only the day of the month is needed, never card data.
- **Legal:** stable URLs for the privacy policy and terms, e.g. `GET /meta/legal`, so the About sheet can link to them.
- **Feature flags / app config:** `GET /meta/config` for the minimum app version, a maintenance banner, and the curated category order.
- **Category metadata:** return `icon_key` and `display_order` from `/categories`. The app maps slugs to icons today.
- **Error shape:** use `{"detail": "message"}` consistently. Validation errors currently return a list, which the client flattens.

## Verified behaviour (for reference)

- `/cards` holds 731 cards, and its paging meta is correct.
- `/advisor/recommend` works without auth and returns `market_benchmark_card` and `insights`.
- Category slugs are capitalised (`Dining`, `Online Shopping`, `UPI`, `International`) and matched case-insensitively.
