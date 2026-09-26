# CreditVance — UX Redesign

This document summarises the redesign of the Flutter app: what changed, why, and the features that were added.
A full copy of the pre-redesign `lib/` is kept in `../_backup/` for reference.

## 1. Design system

| Area | Before | After |
| --- | --- | --- |
| Theme | Dark only, light theme broken | Light, Dark and **System** (follows OS), switchable live from Account |
| Type scale | Large display fonts everywhere | Compact scale (body 13–14 sp, titles 15–20 sp), Inter + Manrope, text scale clamped at 1.3× |
| Icons | Material icons mixed with custom | **Lucide** (ISC licence, free) via `AppIcons` only |
| Surfaces | One card style | `AppSurface` tones (base / alt / high / accent / outline), gradients, press-scale feedback |
| Feedback | Plain snackbars | Compact theme-aware toasts, haptics on every meaningful interaction (toggleable) |

Tokens live in `lib/core/constants` (`app_palette`, `app_colors`, `app_typography`, `app_dimensions`, `app_icons`) and are read with `context.colors` / `context.text`.

## 2. Responsive layout

- **Compact (< 600 dp):** floating blurred bottom bar.
- **Medium:** `NavigationRail`.
- **Expanded (≥ 1024 dp):** extended rail with labels.
- Content is width-constrained (`ContentWidth`), and grids reflow to 1 / 2 / 3 columns.
- Auth, Rewards and Card detail switch to two-column layouts on wide screens.
- Back on Android returns to Home before exiting.

## 3. Screens

### Sign in
- Floating card hero, animated Sign in ↔ Create account switch, inline validation.
- **Continue as guest** keeps everything on-device. Guest cards are uploaded automatically after the user signs in later, and their vault secrets move with them.

### Home (Advisor)
- Collapsing sliver header with greeting and wallet pulse: card count, annual fees, and the next due date.
- Amount input with quick-amount chips and an international toggle.
- Expandable category grid.
- A hero "Use this card" result with one-tap biometric copy of the card number.
- A "you're missing ₹X" banner when a market card beats the wallet.
- Collapsible alternatives, and insights.
- Works offline, and for guests, through the on-device ranker (`WalletRanker`). International spends deduct forex markup plus GST.

### Wallet
- **Carousel** of flippable 3D cards with scale/opacity paging. Tap reveals; long-press opens actions.
- **Timed reveal** with a countdown ring. Secrets hide automatically when the timer ends or the app is backgrounded.
- Quick actions: copy number, copy CVV, copy expiry, and reveal/flip. Every action is biometric-gated.
- **Manage mode:** drag-to-reorder (the order persists) and swipe-to-edit/remove, with undo.
- Empty state with "Try sample cards".

### Add / edit card
- Pinned live preview that shrinks on scroll and flips to the back when the CVV field is focused.
- Searchable card picker sheet.
- A vault toggle chooses between storing the full details on-device (PAN, expiry, CVV, Luhn-validated) and storing only the last 4 digits.
- Nickname and statement day fields.

### Explore (catalog)
- Pinned search with a filter badge, quick chips and bank chips.
- **True server pagination:** infinite scroll, dedupe, footer loading/error/end states.
- Debounced search that ignores stale responses.
- Filter sheet: network, fee type, popular, sort.
- List ↔ grid toggle. Shows an offline cache notice when serving cached results.
- **Compare tray** (up to 3 cards) opens a comparison table with the best value crowned.

### Card detail
- Hero header, stats grid, and a reward estimate that links to Rewards.
- "Read more" overview and expandable sections: earn rates, highlights, lounges, benefits.
- Sticky "I have this card" action.

### Rewards (calculator)
- Pick any catalog or wallet card.
- Monthly spend sliders per bucket, with presets (Student / Family / Traveller / Premium).
- Net annual value hero with fee-waiver detection, and a donut chart breakdown.
- **Wallet showdown** ranks the user's own cards for the same spend profile.

### Account
- Collapsing profile header with stats, and a guest upsell.
- **Appearance:** System / Light / Dark preview tiles.
- **Security:**
  - App lock: biometric on launch and after 15 s in the background.
  - Hide in screenshots / recents: FLAG_SECURE, plus a privacy blur in the app switcher.
  - Clipboard auto-clear timer (15 / 30 / 60 s), reveal duration, and haptics.
- **Data:** sync now, clear catalog cache, erase vault.
- About / privacy / how-the-vault-works sheets.
- Sign out, and **Reset this device**, both behind a confirmation.

## 4. Android "copy number" fix

**Root cause:** `local_auth` needs a `FragmentActivity` host. The app used `FlutterActivity`, so the biometric prompt failed on Android and the copy never happened.

**Fix:**
- `MainActivity` now extends `FlutterFragmentActivity`.
- Copying goes through a native channel (`creditvance/secure`) that:
  - marks the clip as **sensitive**, so it is hidden from the Android 13+ clipboard preview and keyboard suggestions;
  - schedules the wipe natively, so it still clears when the app is in the background. A Dart timer acts as a backstop.
- Cancelled biometric prompts are silent. Real failures show a clear toast.

## 5. New features added

1. System / Light / Dark theme.
2. Guest mode with automatic sync on sign-in.
3. App lock and privacy screen (FLAG_SECURE, app-switcher blur).
4. Configurable clipboard and reveal timers, and a haptics toggle.
5. Copy CVV / expiry, timed reveal with countdown, and a flip card.
6. Drag-to-reorder wallet, swipe actions with undo.
7. Card comparison (up to 3).
8. Missed-value banner on Home; on-device recommendations offline and for guests.
9. Spend presets, donut breakdown, fee-waiver detection, and wallet showdown in Rewards.
10. Infinite pagination, filters, sort, and grid view in Explore; an offline cache indicator.
11. Reset device, clear cache, and erase vault.
12. Session-expiry handling (401 → signed out with a message).

## 6. Security invariants (unchanged)

- PAN, CVV and full expiry never leave the device. The backend only ever receives `card_id`, `nickname`, `last4`, and the statement day.
- Secrets are stored with `flutter_secure_storage` (Android KeyStore / iOS Keychain).
- Reveal and copy always require `local_auth`.
- The clipboard auto-clears (30 s by default).
