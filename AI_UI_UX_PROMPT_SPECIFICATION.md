# Master AI UI/UX Builder Prompt & Product Specification: CardSage (CreditVance)

> **Instructions for AI UI Builder**:
> You are an elite Principal Product Designer and Lead Mobile UI/UX Engineer specialized in luxury MNC fintech applications (aesthetic standard: *Goldman Sachs Private Wealth, American Express Centurion, Apple Wallet, and Revolut Ultra*).
> Build a complete, production-grade, pixel-perfect frontend interface for **CardSage (CreditVance)** based on the comprehensive design tokens, screen architectures, user flows, and state machines detailed below.

---

## 1. Executive Product Vision & Problem Statement

**CardSage** is a zero-knowledge, hardware-secured credit card optimization and vault application.
It solves two painful problems for affluent credit card holders:
1. **Decision Paralysis at Checkout**: Users hold 3–10 credit cards with intricate, constantly changing reward structures (e.g. 5X Swiggy, 10X SmartBuy flights, 1% fuel waiver, 3.3% flat base). At point of sale, they don't know which card yields the maximum ROI.
2. **Physical Wallet Inconvenience vs. Security**: Users need instant access to their 16-digit card numbers, CVVs, and expiries for checkout, but saving card photos in notes or gallery is a massive security hazard. CardSage stores credentials exclusively inside the device's hardware enclave (KeyStore / Secure Enclave) with biometric authorization and a 30-second auto-purge timer.

---

## 2. Design System & Visual Identity Tokens

### 2.1 Theme & Surface Architecture
* **Dark Luxury Obsidian Aesthetic**: Layered elevation using deep obsidian and rich twilight slate.
* **Canvas Background**: `#090B10`
* **Surface Primary (Cards, Navigation, Sheets)**: `#11151F`
* **Surface Secondary (Inner cards, Dropdowns, Inputs)**: `#181E2C`
* **Surface Elevated (Interactive active chips, Pressed states)**: `#222B3E`
* **Surface Card Deep**: `#141926`

### 2.2 Metallic Accent & State Colors
* **Imperial Gold (Primary Accent & Highlights)**:
  * Base: `#DFB76C`
  * Light: `#F7E096`
  * Dark: `#8C6A24`
  * Gradient: `LinearGradient(from: #FDE68A, through: #DFB76C, to: #8C6A24)`
* **Cyber Emerald (Returns, Earnings, Success)**:
  * Base: `#10B981`
  * Light: `#34D399`
  * Dark: `#065F46`
  * Glow: `rgba(16, 185, 129, 0.25)`
* **Royal Sapphire (Milestones, Lounges, Info)**:
  * Base: `#3B82F6`
  * Light: `#60A5FA`
  * Dark: `#1E3A8A`
* **Ruby Crimson (Alerts, Overdue, Destructive actions)**:
  * Base: `#EF4444`
* **Borders & Dividers**:
  * Subtle Rim: `rgba(255, 255, 255, 0.12)`
  * Prominent Border: `rgba(255, 255, 255, 0.20)`
  * Gold Luminous Rim: `rgba(223, 183, 108, 0.35)`

### 2.3 Typography Hierarchy (Font: Plus Jakarta Sans / Inter / SF Pro)
* **Display Large**: 32px / SemiBold 600 / tracking -0.5px / `#F8FAFC`
* **Headline Large**: 22px / SemiBold 600 / `#F8FAFC`
* **Headline Medium**: 18px / SemiBold 600 / `#F8FAFC`
* **Title Medium**: 16px / Medium 500 / `#F8FAFC`
* **Title Small**: 14px / SemiBold 600 / `#F8FAFC`
* **Body Medium**: 14px / Regular 400 / `#94A3B8` (Slate secondary)
* **Body Small**: 12px / Regular 400 / `#64748B` (Slate muted)
* **Label Small (Badges, Micro-caps)**: 11px / SemiBold 600 / Uppercase / tracking 0.5px

### 2.4 Shadows, Glassmorphism & Radii
* **Glass Card Effect**: `backdrop-filter: blur(16px)`, background `rgba(24, 30, 44, 0.75)`, border `1px solid rgba(255, 255, 255, 0.08)`.
* **Corner Radii**:
  * Pill / Full: `9999px`
  * XL (Credit Cards, Modals): `20px`
  * Large (Cards, Dialogs): `16px`
  * Medium (Buttons, Inputs): `12px`
  * Small (Badges, Tags): `8px`
* **Elevated Shadow**: `0 10px 30px -10px rgba(0, 0, 0, 0.7)`

---

## 3. Global Interaction Paradigms

1. **Pull-to-Refresh on All Views**:
   * Every scrollable screen (Advisor, Vault, Catalog, Calculator, Profile, Card Details) includes a pull-to-refresh gesture.
   * Spinner styled in Imperial Gold (`#DFB76C`) over obsidian background.
   * Remains fully functional even during Empty and Error states.
2. **Skeletonizer Loading States**:
   * No raw circular progress spinners.
   * Uses realistic layout skeletons with bone placeholders (Avatar bone, Title bone, Card chip bone, Chevron bone) with a subtle shimmering gradient (`#181E2C` to `#222B3E`).
3. **Floating Obsidian Toast System (Toastification)**:
   * Replaces bottom snackbars with top-centered floating frosted cards.
   * Left icon with colored ambient halo (Emerald check for copy/success, Ruby alert for failure, Gold warning for biometric cancel).
   * Auto-dismisses in 3–4 seconds with manual tap-to-dismiss.
4. **Haptic & Tactile Feedback**:
   * Light haptic on tab switch and spend slider adjustments.
   * Medium haptic on card reveal and number copy.
   * Error haptic on biometric failure or validation errors.

---

## 4. Screen-by-Screen UI/UX Specifications

### Screen 1: Smart Advisor ("Which Card Should I Use Right Now?")
* **Purpose**: Instant recommendation of the single best card to swipe or enter online for maximum savings/points.
* **Header**:
  * Title: "Smart Advisor"
  * Subtitle: "Maximized Returns at Checkout" in Imperial Gold
* **Category Picker (Horizontal Scrolling Carousel)**:
  * Pills with icons: *Dining & Food Orders, Flights & Travel, Groceries, Fuel, Online Shopping, Rent, International Forex, Utilities, Entertainment*.
  * Active state: Imperial Gold border with glowing obsidian surface.
* **Spend Amount Selector**:
  * Quick amount chips: `₹500`, `₹2,000`, `₹5,000`, `₹10,000`, `₹25,000`, `₹50,000`.
  * Custom spend input field with currency symbol prefix (`₹`).
  * International Forex Switch: Toggle button for overseas transactions (factors in foreign currency markup vs. rewards).
* **Hero Recommendation Card (Dynamic Glowing Widget)**:
  * Ambient glow border in Emerald (`#10B981`) or Gold (`#DFB76C`).
  * Badge: "BEST VALUE CHOICE" + "33% Return Rate".
  * Realistic mini credit card render with bank logo (HDFC, Axis, SBI, Amex, ICICI).
  * Prominent net earning callout: *"You will earn ₹1,650 in Reward Points"*.
  * Primary Action Button: *"Copy Number (•••• 4321)"* with one-tap copy & 30s auto-clear.
  * Breakdown list:
    * Base Return vs. Category Accelerated Multiplier.
    * Lounge Access eligibility / Milestone benefit triggered.
* **Runner-Up Alternatives Section**:
  * 2 secondary collapsed cards showing alternative choices (e.g. *"2nd Best: SBI Cashback (5% Cashback = ₹500)"*).

---

### Screen 2: My Vault (Zero-Knowledge Hardware Wallet)
* **Purpose**: Secure on-device vault allowing cardholders to store and retrieve card numbers with biometric lock.
* **3D Interactive Card Carousel**:
  * Smooth horizontal paging with active card scale (0.88 scale for adjacent cards, 1.0 for focused card).
  * Card Aspect Ratio 1.586 (Standard ISO/IEC 7810 ID-1 credit card).
  * Dynamic Card Shaders:
    * Metal / obsidian brushed gradient.
    * Realistic EMV gold chip illustration.
    * Contactless wave symbol.
    * Bank logo in top-left, card tier in top-right ("Super Premium / Visa Infinite").
    * 16-digit PAN formatted in 4-digit groups (`•••• •••• •••• 4321` or unmasked `4532 9812 3456 4321`).
    * Cardholder nickname, Valid Thru (`MM/YY`), and CVV (`•••`).
* **Active Security Actions (Bottom Panel)**:
  * Two prominent buttons side-by-side:
    1. **"Copy Number"**: Triggers biometric prompt (Face ID / Fingerprint) & copies clean 16 digits to clipboard with 30s auto-purge.
    2. **"Unlock Card" / "Lock Details"**: Unmasks PAN, Expiry, and CVV on-screen for 30 seconds.
  * 30-Second Security Countdown Pill: Shows a ticking countdown timer (`"Auto-clears in 28s"`) with sapphire glow.
* **Card Quick Specs Grid**:
  * Annual Fee (`₹12,500`), Fee Waiver Goal (`₹10,00,000`), Billing Cycle (`15th of month`).
* **Empty Vault State**:
  * Shield & key lock iconography with gold gradient.
  * Headline: *"Your Vault is Empty"*.
  * Description: *"Store your credit card credentials inside your phone's hardware KeyStore for one-tap copy at checkout."*
  * CTA: *"Add Your First Card"*.

---

### Screen 3: Add Card Flow
* **Purpose**: Add a credit card to the portfolio and encrypt credentials in the device vault.
* **Live Interactive Card Preview**:
  * Stays at the top of the form and updates live in real-time as the user types card nickname, number, and expiry.
* **Form Inputs**:
  1. **Card Model Picker**: Searchable bottom sheet or dropdown to pick from 100+ preset Indian & international cards (HDFC Infinia, SBI Cashback, Axis Magnus, Amex Platinum, Tata Neu Infinity, etc.). Auto-fills reward multipliers.
  2. **Card Nickname**: E.g. *"Jay's Primary Travel Card"*.
  3. **Full 16-Digit Card Number (PAN)**:
     * Auto-spaces every 4 digits (`XXXX XXXX XXXX XXXX`).
     * Auto-detects card brand and displays authentic Visa, Mastercard, American Express, or RuPay icon.
     * Luhn algorithm validation checkmark.
  4. **Expiry Date (`MM/YY`)**: Auto-inserts slash `/`, validates non-expired future date.
  5. **CVV / CVC**: 3 digits (or 4 digits for Amex) with password bullet masking.
  6. **Billing Cycle Day**: Dropdown (1st through 28th of each month) to enable payment due date reminders.
* **Hardware Vault Assurance Box**:
  * Luxury glass callout with padlock icon: *"Zero-Knowledge Security: PAN and CVV are encrypted on-device via AES-256 GCM backed by Android KeyStore / Apple Secure Enclave. Sensitive data never touches any cloud server."*
* **Submit Button**: *"Secure & Add to Vault"* with biometric confirmation.

---

### Screen 4: Explore Catalog & Comparison
* **Purpose**: Browse and compare 100+ cards with filters, perk breakdowns, and fee waivers.
* **Search & Filter Header**:
  * Real-time search bar with glass container and clear button.
  * Horizontal Filter Chips:
    * Bank Selector: *All, HDFC, SBI, Axis, ICICI, Amex, Kotak, IndusInd*.
    * Network: *All, Visa, Mastercard, American Express, RuPay*.
    * Annual Fee Tier: *Lifetime Free, Under ₹1k, ₹1k–₹5k, Super Premium (>₹5k)*.
  * Sort Dropdown: *Most Popular, Highest Return Rate, Lowest Fee, Best for Travel*.
* **Catalog Card Tiles (List View)**:
  * Bank Square Logo (44x44px).
  * Card Name with tier badge (*Super Premium, Cashback, Lifestyle*).
  * Key Metric Grid:
    * Base Return Rate (e.g. `3.3%`).
    * Annual Fee (e.g. `₹12,500` or `Free`).
    * Joining Perk (e.g. `10,000 Points`).
  * Top 2 bullet perks preview.
  * Tap navigates to Deep Card Details Screen.

---

### Screen 5: Deep Card Details Screen
* **Hero Section**: Large 3D rendered card visual with bank logo, network, and shiny foil overlay.
* **Key Stats Row**:
  * Joining Fee | Annual Fee | Renewal Waiver Spend | Rating (e.g. 4.9 ★).
* **Segmented Navigation Tabs**:
  1. **Multipliers & Reward Rates**:
     * Category earn rates (Dining: 10X, Flights: 16.5%, Grocery: 3.3%, Utility: 1X).
     * Point-to-Rupee conversion value (e.g. `1 RP = ₹1.00 on SmartBuy Flights`).
  2. **Airport Lounges & Travel**:
     * Domestic lounge quota (Unlimited / 4 per quarter) + Dreamfolks / Priority Pass.
     * International lounge access + free guest access rules.
     * 1% Fuel surcharge waiver conditions.
  3. **Fee Waivers & Milestones**:
     * Spend milestone thresholds with progress bar visualization.
     * Golf games, movie ticket 1+1 offers, concierge phone lines.
* **Sticky Bottom Bar**:
  * *"Add to My Vault"* button leading directly into the pre-selected Add Card screen.

---

### Screen 6: Annual ROI & Reward Calculator
* **Purpose**: Financial simulator where users dial their monthly spending habits to project net annual profit.
* **Card Selector**:
  * Dropdown selector with bank name + card name (guaranteed unique selection and safe fallback).
* **Interactive Spending Allocation Sliders**:
  * Smooth slider with divisions, active gold track, and live formatted currency display:
    1. *Dining & Food Orders*: ₹0 to ₹50,000 / month.
    2. *Flights & Hotel Stays*: ₹0 to ₹60,000 / month.
    3. *Groceries & Supermarkets*: ₹0 to ₹40,000 / month.
    4. *Online Shopping (Amazon, Flipkart)*: ₹0 to ₹50,000 / month.
    5. *General Bills & Utilities*: ₹0 to ₹40,000 / month.
* **Simulation Result Dashboard (Glassmorphism Widget)**:
  * Annual Spend Total: `₹8,40,000 / year`.
  * Total Gross Rewards Earned: `₹46,200`.
  * Applicable Fee: `₹0` (Annotated: *"Annual Fee of ₹12,500 Waived: spend exceeded ₹8,00,000 waiver threshold!"*).
  * **Net Annual ROI**: Large Emerald highlight `+ ₹46,200 (5.5% Net Return)`.
  * Category breakdown horizontal progress bar showing where the earnings originate.

---

### Screen 7: Account & Security Profile (100% On-Device / Zero Remote API)
* **Architecture**: Completely offline / on-device zero-knowledge account management. No remote authentication server required.
* **User Header**:
  * Obsidian avatar circle with initials in Imperial Gold.
  * User display name (e.g. *"Jay"*), email address.
  * Status badges: *"Vault Authenticated"*, *"AES-256 Enclave Active"*.
* **Hardware Security Settings Group**:
  * Toggle: *Biometric Unlock (Face ID / Fingerprint)*.
  * Toggle: *Hardware Keystore Encryption*.
  * Setting: *Clipboard Auto-Clear Duration (Default: 30s)*.
* **Local Session Controls**:
  * Quick Demo Sign In button for instant testing.
  * Log Out button with confirmation modal (purges on-device decrypted cache and resets session).

---

## 5. Master Prompt to Copy-Paste into AI UI Builders (v0 / Lovable / Bolt / Cursor)

```text
Build a production-grade, responsive mobile web application for "CardSage" — an ultra-luxury fintech credit card reward optimizer and zero-knowledge hardware vault.

Aesthetic Guidelines:
- Goldman Sachs / Amex Centurion luxury dark fintech theme.
- Canvas background: #090B10, Surface cards: #11151F and #181E2C, Elevated surfaces: #222B3E.
- Accent colors: Imperial Gold (#DFB76C) with gradient (#FDE68A to #8C6A24), Cyber Emerald (#10B981) for returns, Royal Sapphire (#3B82F6) for info, Ruby (#EF4444) for alerts.
- Thin borders with 12% white opacity (rgba(255,255,255,0.12)) and gold glowing borders on active/recommended elements.
- Typography: Plus Jakarta Sans or Inter, crisp sans-serif with high contrast white (#F8FAFC) and slate muted secondary (#94A3B8).
- Loading states: Skeletonizer-style animated shimmer placeholders with base #181E2C and highlight #222B3E.
- Notification toasts: Top-floating frosted obsidian pill toasts with colored glowing icons and auto-dismiss.

Core Application Navigation (5 Main Tabs):
1. Advisor Screen ("Which Card Should I Use Right Now?"):
   - Horizontal category picker: Dining, Flights, Grocery, Fuel, Shopping, Travel, International.
   - Quick spend chips: ₹500, ₹2k, ₹5k, ₹10k, ₹25k, ₹50k, and custom input.
   - International forex toggle.
   - Glowing hero recommendation card with card graphic, return percentage (e.g. 16.5%), net reward earned in Rupees, one-tap "Copy Card Number" button with 30s timer, and reward rationale breakdown.
   - Pull-to-refresh on scroll.

2. My Vault (Hardware Credit Card Wallet):
   - Horizontal 3D carousel with realistic metal card renders (chip, contactless waves, bank logo, card name, masked PAN •••• •••• •••• 4321, expiry, CVV).
   - Card action buttons: "Copy Number" (biometric simulation) and "Unlock Card / Lock Details" (unmasks credentials with 30-second timer countdown).
   - Empty state when 0 cards exist with KeyStore lock illustration and "Add Card" CTA.
   - Pull-to-refresh on scroll.

3. Add Card Flow:
   - Real-time interactive visual card preview at top that updates as user fills the form.
   - Preset card picker dropdown (HDFC Infinia, SBI Cashback, Axis Atlas, Amex Platinum, ICICI Emeralde).
   - Form fields: Card Nickname, 16-digit PAN (auto-spaced with Visa/Mastercard/Amex/RuPay brand badge), Expiry MM/YY, CVV, Billing Cycle Day.
   - Zero-knowledge encryption disclaimer box.
   - Success floating toast on add.

4. Explore Catalog:
   - Debounced search bar.
   - Filter chips for Banks, Networks, and Fee Tiers (Lifetime Free, Under 1k, Super Premium).
   - Card list tiles showing joining fee, annual fee, waiver spend goal, return rate badge, and key bullet perks.
   - Tapping opens Deep Card Details with tabs for Multipliers, Lounge Access, and Milestones.
   - Pull-to-refresh on scroll.

5. Reward Calculator:
   - Card dropdown selector.
   - 5 Monthly spending sliders: Dining, Flights, Grocery, Online Shopping, Bills.
   - Real-time calculation card showing Total Spend, Rewards Earned, Fee Waiver Status, and Net ROI % (+₹XX,XXX).
   - Pull-to-refresh on scroll.

6. Account & Security:
   - On-device profile with avatar, name, and "Vault Authenticated" badge.
   - Security toggles for Biometrics and Auto-Clear.
   - Instant Demo Login / Logout.
   - 100% offline on-device operation without external API dependencies.

Make the UI interactive, beautifully animated with smooth transitions, tactile feedback, and realistic Indian credit card presets (HDFC Infinia, SBI Cashback, Axis Atlas, Amex Platinum).
```
