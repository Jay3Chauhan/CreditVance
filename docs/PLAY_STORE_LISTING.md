# Credvert — Google Play Launch Kit

Ready-to-paste store copy, Play Console answers, graphics specs, AI image prompts and growth material for the Android launch.

- Package: `com.jaychauhan.credvert`
- Version at launch: `1.0.0+1`
- Market: India (INR, English-first)
- Character counts in this file were measured by script. Play counts every character, including spaces, line breaks, bullets (`•`) and dashes. Re-count after any edit.

Items marked **[VERIFY]** are assumptions or depend on something you must confirm in code, on the server, or in Play Console before submitting.

---

## 0. Read first: issues found while preparing this kit

These are not copy problems, but they affect what you can truthfully say in the listing and in the Data safety form.

1. **Four brand names are in use.** See section 1.
2. **Firebase Analytics, Crashlytics and Performance Monitoring are active by default.** `firebase_bootstrap.dart` calls `AnalyticsService.applyCollection(true)`, and the "Diagnostics" setting defaults to on (`diagnosticsEnabled = true`). Analytics also sets the user id (`setUserId`). The manifest flag `firebase_crashlytics_collection_enabled=false` is overridden at runtime. Data safety must declare this (section 6).
3. **Advertising ID.** `firebase_analytics` on Android can merge the `com.google.android.gms.permission.AD_ID` permission into the final manifest and collect the Advertising ID. Either disable it (manifest meta-data `google_analytics_adid_collection_enabled=false` and remove the `AD_ID` permission with `tools:node="remove"`), or declare Advertising ID use in Play Console. **[VERIFY]** by inspecting the merged manifest of the release build (`build/app/intermediates/merged_manifests/release/...`).
4. **Notification channel mismatch.** The manifest default channel is `credvert_general`. The backend guide says the Android reminder channel is `creditvance_reminders`. Pick one before launch, or reminders may land in an unexpected channel. (Tell the agent editing the Flutter code; this kit does not change code.)
5. **Colour tokens differ.** `AGENTS.md` says gold `#DFB76C` and canvas `#090B10`; `app_colors.dart` uses gold `#D6B06A` and dark canvas `#09090C`. Marketing art below uses the `AGENTS.md` values. They are close enough visually, but pick one set for brand consistency.
6. **Card data source.** `BACKEND_REQUIREMENTS.md` / the backend guide say card details are crawled on demand from a third-party site (SaveSage) or synthesised. Confirm you have the right to use that data and the card images. Keep the "estimates, verify with your bank" disclaimer in the listing and in the app.
7. **Apply links.** Card detail shows a bank "apply" link. If any link earns you a commission or is a lead-generation link, you must disclose it, and in India you should check whether that makes you a card-sourcing agent under RBI rules. If they are plain links to the bank's public page, the listing wording below is accurate. **[VERIFY]**
8. **Compare limit.** `docs/UX_REDESIGN.md` says "up to 3" but the code (`CatalogProvider.maxCompare = 4`) and the API allow 2–4. This kit says "2 to 4".
9. **Store screenshots.** "Hide in screenshots" (FLAG_SECURE) is on by default. Turn it off in Account → Security before capturing store screenshots, and use sample cards only.

---

## 1. Branding note and app name options

### The problem

| Where | Name |
| --- | --- |
| `pubspec.yaml`, Android label, `AppStrings.appName`, docs | **Credvert** |
| Backend guide, notification channel in backend | **CreditVance** |
| Firebase project id | `credvance-cb042` (**Credvance**, no "it") |
| Project folder, AI spec | **CardSage** |

A user never sees the Firebase project id, so that one does not matter. The others do: they show up in emails, notifications, the privacy policy, the website and support replies.

### Recommendation

Pick **one** name before you publish. The Play listing title can change later, but screenshots, the icon, the privacy policy, the support email and the website domain are expensive to redo, and a rename after launch confuses early reviewers.

- **Credvert** — already in the app, short, distinctive, and easy to search for. It is the name used throughout this kit.
- **CreditVance** — clearer meaning ("credit" + "advance"), but longer and closer to generic credit/loan brands. That can invite extra scrutiny under Play's financial-services policies.
- **CardSage** — clear meaning, but the card data comes from a site called SaveSage, and "Sage" is a common fintech word. Check trademarks before you use it.

Before committing: search the Play Store, the Indian trademark registry (ipindia.gov.in, class 9 and 36), and domain/handle availability.

**To swap names:** replace every "Credvert" in sections 1–3, 8–12 with the chosen name. The name also appears in the notification copy (section 10) and the FAQ (section 11). Re-count characters afterwards; "CreditVance" is 3 characters longer than "Credvert".

### App name (title) options — limit 30 characters

Play does not allow words like "best", "#1", "top", "free" or prices in the title, or emoji and all-caps used for emphasis.

| # | Title | Chars |
| --- | --- | --- |
| 1 | `Credvert: Credit Card Advisor` | 29 |
| 2 | `Credvert: Card Rewards & Vault` | 30 |
| 3 | `Credvert: Card Advisor & Vault` | 30 |
| 4 | `Credvert – Credit Card Wallet` | 29 |
| 5 | `Credvert` | 8 |

Recommended: **#1**. "Credit card" is the highest-intent search term and "advisor" describes the core feature. Swap-in: `CreditVance: Card Advisor` (25).

---

## 2. Short description — limit 80 characters

Pick one. It shows under the title and weighs heavily in search.

| # | Short description | Chars |
| --- | --- | --- |
| 1 | `Pick the right credit card for every spend. Card numbers stay on your phone.` | 76 |
| 2 | `Compare Indian credit cards, estimate rewards and get bill due-date reminders.` | 78 |
| 3 | `See which of your cards earns more on dining, fuel, travel and forex spends.` | 76 |
| 4 | `Credit card rewards advisor, secure card wallet and statement reminders.` | 72 |
| 5 | `Your card wallet and rewards guide. Card details never leave your phone.` | 72 |

Recommended: **#1** for launch (clear benefit plus the privacy hook). Test **#2** later with a store listing experiment.

Avoid bank names in the short description; keep them to the full description where they are used descriptively.

---

## 3. Full description — limit 4,000 characters

Play renders plain text with line breaks. Bullets (`•`) and CAPS section headers work well. Do not use Markdown or HTML.

### 3.1 Primary version (informative)

Character count: **3,490**

```text
Credvert helps you choose the right credit card for every spend, and keeps your card details locked on your own phone.

Tell Credvert where you are paying and how much. It ranks the cards in your wallet for that spend and shows the estimated reward value in rupees, so you can decide before you tap, swipe or check out.

WHAT YOU CAN DO

• Ask the advisor: pick a category such as dining, groceries, fuel, travel, online shopping or UPI, enter the amount, and see which of your cards gives the highest estimated return.
• Pay abroad with clarity: international mode subtracts each card's forex markup plus the 18% GST charged on that markup, so the ranking reflects what you actually get back.
• Keep a secure wallet: add the cards you hold with a nickname. Optionally save the full card number, expiry and CVV on this phone, then copy them at checkout after a fingerprint or face check.
• Explore the catalog: browse 700+ Indian credit cards from banks such as HDFC Bank, SBI Card, ICICI Bank and Axis Bank. Filter by lifetime free, lounge access, network and fee type, and sort by annual fee or reward return.
• Read card details: earn rates by category, airport lounge access, milestones, redemption options, fees and the spend needed for a fee waiver.
• Compare 2 to 4 cards side by side: joining and renewal fees, forex markup, reward rates, point value and lounge access.
• Estimate yearly value: set your monthly spends by category and see estimated annual rewards, whether the renewal fee would be waived, and the net value after fees.
• Shortlist cards you are thinking of applying for.
• Wallet insights: your total yearly renewal fees, how many cards include lounge access, and which card you hold earns the most in each category.
• Reminders: add a statement day and a payment due day, and get a notification before the bill is due and when the statement is generated.

PRIVATE BY DESIGN

• Your full card number, expiry and CVV never leave your phone. They are encrypted with keys held in the Android Keystore and are never sent to our servers.
• Only the card product, a nickname, the last 4 digits and the statement and due days sync to your account.
• Revealing or copying card details always asks for biometric confirmation.
• Copied numbers are marked sensitive and cleared from the clipboard automatically after 15, 30 or 60 seconds.
• Screenshots and screen recording are blocked, and the app is blurred in the recent apps screen.
• Optional app lock asks for your fingerprint or face when you open Credvert.
• Guest mode: use Credvert without an account. Everything stays on this device. Sign in later to sync.
• Delete your account from inside the app at any time.

MADE FOR EVERYDAY USE

• Light, dark or system theme.
• Works with saved data when you are offline.
• Clear numbers in rupees, not jargon.

IMPORTANT

Credvert is an independent information tool. It is not a bank, card issuer, lender or payment app, and it is not affiliated with or endorsed by any bank or card network. Credvert does not apply for cards on your behalf, does not make payments, does not offer loans and does not check your credit score.

Reward values are estimates based on published card features. Issuers can change fees, earn rates and benefits at any time, so confirm the current terms with your bank before you apply or spend. Bank and card names are trademarks of their respective owners and are used only to identify their products.

Questions or feedback: support@credvert.app
```

**[VERIFY]** before pasting:
- "700+" — the backend reported 731 cards. Update if the catalog shrinks.
- "UPI" category — present in backend category slugs.
- "support@credvert.app" is a placeholder. Use a real inbox you monitor; Play also shows your developer email.
- Reminders line assumes Firebase push ships in 1.0.0. If not, remove the Reminders bullet and add it in the first update.
- "face" — Android face unlock only counts if the device supports Class 3 (strong) face biometrics. Keep "fingerprint or face" generic.

### 3.2 Alternative version (warmer, shorter)

Character count: **2,039**

```text
Which card should I use for this?

If you carry more than one credit card, you have asked yourself that at a checkout counter. Credvert answers it in a few seconds.

Enter the amount, pick what you are paying for, and Credvert ranks the cards you hold by the estimated reward you would earn, in rupees. Paying abroad? Switch on international mode and it takes each card's forex markup, plus the 18% GST on it, into account.

A WALLET THAT STAYS ON YOUR PHONE

Save your cards once. When you need the number at checkout, confirm with your fingerprint and copy it. The full number, expiry and CVV are encrypted on this phone and never uploaded. The clipboard clears itself, screenshots are blocked, and an optional app lock keeps everything behind your biometric.

FIND AND COMPARE CARDS

• Browse 700+ Indian credit cards and filter by lifetime free, lounge access, network or fee.
• Open any card for earn rates, lounges, milestones and redemption options.
• Put 2 to 4 cards side by side.
• Shortlist the ones you like.

KNOW WHAT A CARD IS WORTH TO YOU

Set your monthly spends and see a card's estimated yearly rewards, whether its renewal fee would be waived, and what is left after fees.

STAY ON TOP OF BILLS

Add your statement and due days and Credvert reminds you before the payment is due. Wallet insights show your total yearly fees and which card earns the most in each category.

NO ACCOUNT NEEDED

Start in guest mode and keep everything on your device. Create an account later to sync your wallet (card product, nickname and last 4 digits only). You can delete your account inside the app whenever you like.

PLEASE NOTE

Credvert is an independent information tool, not a bank, card issuer, lender or payment app, and is not affiliated with any bank or card network. It does not apply for cards for you, make payments or check your credit score. Rewards shown are estimates; issuers change terms, so confirm details with your bank before applying. Bank and card names belong to their owners.

Feedback: support@credvert.app
```

### 3.3 Things never to write in the listing

- "Best", "#1", "top-rated", "India's favourite", "guaranteed savings", "save ₹X every year", "free money".
- "Bank-grade", "military-grade", "100% secure", "unhackable". Describe what the app does instead (Keystore, biometric gate, clipboard clear).
- "Approved by RBI", or any bank or network logo.
- Lists of keywords, competitor app names, or repeated terms.
- Promises about approval odds, credit scores or loans.
- Emoji as bullets or in headers.

---

## 4. ASO keyword strategy (India)

Play has no keyword field. It indexes the title, short description and full description, plus signals such as installs, retention and ratings. Use each important term naturally 2–4 times across the description. Repeating a term more often than that reads as stuffing and can get the listing rejected.

### Primary (high intent, highest volume)

| Keyword | Where to use it |
| --- | --- |
| credit card | Title, short description, first line of full description |
| credit card rewards | Short description (#4), advisor bullet |
| credit card compare / compare credit cards | Compare bullet, alt short description #2 |
| card wallet | Wallet bullet, short description #5 |
| credit card reminder / bill due date | Reminders bullet, short description #2 |

### Secondary

| Keyword | Where |
| --- | --- |
| lifetime free credit card | Catalog bullet |
| lounge access credit card | Catalog and card-detail bullets |
| forex markup | International bullet |
| reward points / cashback | Advisor and calculator bullets |
| annual fee waiver | Calculator bullet |
| credit card statement date | Reminders bullet |

### Long-tail (use once each, only where true)

- "which credit card to use for dining" — advisor bullet mentions dining.
- "credit card for international travel" — international bullet.
- "zero forex markup card" — card-detail/compare context only; do not claim the app offers one.
- "HDFC / SBI / ICICI / Axis credit card" — one mention each in the catalog bullet. Descriptive use of bank names is generally acceptable; never imply partnership.
- "UPI credit card rewards" — advisor bullet mentions UPI.
- "credit card fee calculator" — calculator bullet.

### Where not to put keywords

- Not in the developer name.
- Not as a list at the end of the description.
- Not in screenshot captions in a way that reads as a keyword list.

### Local languages

India search is mostly English for finance, but Hindi listings can help. Add a `hi-IN` translation of the title, short description and full description after launch (Play Console → Store presence → Translations). Human-review any machine translation; financial wording must stay accurate.

### Measure

Use Play Console → Acquisition reports → search terms, and run a store listing experiment on the short description and first screenshot after you have about 1,000 store visitors a week.

---

## 5. Category, tags and content rating

### Category

- **App or game:** App
- **Category:** **Finance**
- **Free or paid:** Free

Finance is the natural fit (card comparison, rewards, wallet) and where users look for credit card apps. Choosing Finance triggers the Financial features declaration (section 7.2).

### Tags (Play Console → Store settings → Tags, up to 5)

Pick the closest available from Play's fixed list. **[VERIFY]** exact labels; the list changes. Likely candidates:

1. Personal finance
2. Credit cards
3. Budgeting
4. Digital wallet (only if Play's definition does not imply payments; skip if it does)
5. Finance tools / Calculators

### Contact details

- Email (required, public): a monitored support address.
- Website: recommended (the landing page with privacy policy and deletion page).
- Phone: optional. Skip unless you staff it.

### Content rating (IARC questionnaire)

- **Email for IARC certificates:** your developer email.
- **Category:** "All other app types" (sometimes labelled "Utility, Productivity, Communication, or Other"). Not "Reference, news or educational"; the core use is a utility.

| Question | Answer | Reasoning |
| --- | --- | --- |
| Violence (any form) | No | No violent content |
| Fear / horror | No | — |
| Sexuality / nudity | No | — |
| Crude humour / profanity | No | App copy only |
| Controlled substances (drugs, alcohol, tobacco) | No | Spend categories are generic (dining, fuel). If a category ever names alcohol or bars, answer again. **[VERIFY]** category list |
| Gambling / simulated gambling | No | No betting, lotteries or loot boxes |
| Real-money gambling | No | — |
| Does the app allow users to interact or exchange content? | No | No chat, comments, profiles or user-generated content visible to others |
| Does the app share the user's current physical location with other users? | No | Location is not collected |
| Does the app allow users to purchase digital goods? | No | No in-app purchases |
| Is the app a web browser or search engine? | No | Opens bank links in a browser, but is not a browser |
| Does the app contain content from news or unmoderated sources? | No | Server banners/promotions are editor-published |

Expected result: **IARC 3+ / Everyone / PEGI 3**. That is normal for finance apps; the audience age is set separately in Target audience (section 7.4).

---

## 6. Data safety form

This reflects the code and backend as of 27 Sep 2026. Data safety must match your privacy policy and your real SDK behaviour, including SDKs (Firebase). Google checks this. If you change the Diagnostics default or the Advertising ID setting (section 0), update these answers.

### 6.1 Overview questions

| Question | Answer | Notes |
| --- | --- | --- |
| Does your app collect or share any of the required user data types? | **Yes** | Account email/name, wallet metadata, device IDs, analytics |
| Is all of the user data collected by your app encrypted in transit? | **Yes** | **[VERIFY]** the production API base URL is `https://` and there is no cleartext traffic (no `usesCleartextTraffic`, no `http://` endpoints). Firebase uses TLS. |
| Do you provide a way for users to request that their data is deleted? | **Yes** | In-app: Account → Delete account (`DELETE /auth/me`, cascades to wallet cards and shortlist). Web: the data deletion URL from `GET /meta/legal`. |
| Account creation method | "Username and password" (email + password) | Guest mode also exists; the app does not require an account |
| Delete account URL | URL from `/meta/legal` (data deletion) | **Must be a public web page** that lets a user request deletion without reinstalling the app, names the app/developer, lists what is deleted and what is kept, and gives retention periods. **[VERIFY]** it is live |
| Is your app independently security reviewed (MASA)? | No | Optional badge; consider later |
| Does your app comply with the Families Policy? | Not applicable | Target audience is 18+ |

"Collected" means data leaves the device. The full card number, expiry and CVV are **processed only on the device** and are therefore **not collected**; do not declare them. Biometrics are handled by Android and never reach the app; do not declare them.

"Shared" means transfer to a third party. Firebase (Google) acting as your service provider, and your own backend, count as **not shared**.

### 6.2 Data types

| Category → type | Collected? | Shared? | Processed ephemerally? | Required or optional | Purposes | What exactly |
| --- | --- | --- | --- | --- | --- | --- |
| Personal info → **Name** | Yes | No | No | Optional (only if the user sets a display name) | App functionality, Account management | `full_name` via `PATCH /auth/me` **[VERIFY]** whether sign-up asks for it |
| Personal info → **Email address** | Yes | No | No | Optional (guest mode needs none) | Account management, App functionality | Sign-in, password reset |
| Personal info → **User IDs** | Yes | No | No | Optional | Account management, Analytics | Account id; also sent to Firebase Analytics/Crashlytics via `setUserId` when signed in |
| Financial info → **User payment info** | **No** | — | — | — | — | Full card number, CVV and expiry stay on-device only |
| Financial info → **Other financial info** | Yes | No | No | Optional (guest wallet stays on device) | App functionality | Signed-in wallet: which card product and bank you hold, nickname, last 4 digits, statement day, due day, display order. Also the shortlist |
| Financial info → **Purchase history** | **[VERIFY]** | No | Yes, if not stored | Required to use the advisor | App functionality | The advisor sends spend category + amount (+ international flag) to the server. If the server does **not** store these, mark "processed ephemerally". If it logs or stores them, declare as collected, not ephemeral |
| Financial info → Credit score | No | — | — | — | — | — |
| Location (approximate / precise) | No | — | — | — | — | No location permission. **[VERIFY]** against Google's Firebase data disclosure page; Analytics derives country from IP but Google's guidance currently does not require declaring it as location |
| App activity → **App interactions** | Yes | No | No | Optional if the Diagnostics toggle stays in Account settings **[VERIFY]** | Analytics | Firebase Analytics screen views and events |
| App activity → **In-app search history** | **[VERIFY]** | No | Yes, if not stored | Required for search | App functionality | Catalog search and suggest queries go to the server. Declare as ephemeral only if not logged |
| App activity → Other actions | Yes | No | No | Optional | Analytics | Banner/promotion impression and click tracking (`/banners/{id}/track`) — anonymous counts, but it is collected |
| App info and performance → **Crash logs** | Yes | No | No | Optional | Analytics (app stability) | Crashlytics |
| App info and performance → **Diagnostics** | Yes | No | No | Optional | Analytics | Firebase Performance traces, Crashlytics custom keys |
| Device or other IDs | Yes | No | No | Required for reminders; optional otherwise | App functionality (push), Analytics | FCM registration token, Firebase installation ID / app instance ID. Add Advertising ID here **only if** you keep the AD_ID permission (section 0) |
| Messages, Photos/videos, Audio, Files, Calendar, Contacts, Health, Web browsing | No | — | — | — | — | — |

About "Optional": Play defines optional data as data the user can choose not to provide. Analytics and crash data are collected by default with an opt-out toggle. Many developers mark this optional because a user can turn it off, but the safer choice is **Required** unless you switch Diagnostics to opt-in (off until the user enables it). **[VERIFY]** which you pick and keep the privacy policy consistent.

### 6.3 Security practices section — suggested wording for the privacy policy

- Data in transit is encrypted with TLS.
- Card number, expiry and CVV are stored only on the device, encrypted with keys held in the Android Keystore (iOS: Keychain protected by the Secure Enclave), and are never transmitted.
- Users can delete their account and all synced wallet data in the app or via the web deletion page. Guest data lives only on the device and is removed by "Reset this device" or uninstalling.
- State retention: for example, "Account data is deleted within 30 days of a deletion request; backups are purged within 90 days." **[VERIFY]** your real backend (Neon PostgreSQL) backup retention.
- Name Firebase (Google) as a processor for analytics, crash reporting, performance and push notifications.

---

## 7. App content declarations (Play Console → Policy → App content)

### 7.1 Permissions

Permissions in `AndroidManifest.xml`: `INTERNET`, `USE_BIOMETRIC`, `POST_NOTIFICATIONS`. None of these are "sensitive" permissions that require a Play Console declaration form. Play may still ask about them in pre-review, and you should explain them in the privacy policy and in-app. Use the text below where asked.

| Permission | Justification (paste) |
| --- | --- |
| `INTERNET` | Credvert connects to its server to load the credit card catalog, card details, recommendations and reward estimates, and to sync your wallet (card product, nickname, last 4 digits, statement and due days) when you are signed in. Card numbers, expiry dates and CVVs are never sent. |
| `USE_BIOMETRIC` | Credvert asks for your fingerprint or face before it reveals or copies saved card details, and for the optional app lock. Biometric data is handled entirely by Android; Credvert never receives or stores it. |
| `POST_NOTIFICATIONS` | Credvert sends reminders before a credit card payment is due and when a statement is generated, based on the statement and due days you add. You can turn reminders off in the app or in Android settings. Product news notifications are off unless you opt in. |

In-app runtime prompt (Android 13+): ask only when the user adds a due or statement day or opens reminder settings, not at first launch. Pre-prompt copy:

```text
Get a reminder before your bill is due?
Credvert can notify you a few days before the payment due date and when your statement is ready. You can change this anytime.
[Turn on reminders]  [Not now]
```

If the release build ends up with `AD_ID` (section 0), answer the **Advertising ID** declaration: "Yes, uses Advertising ID — Analytics". Otherwise answer "No".

### 7.2 Financial features declaration

Play asks every Finance app which financial features it offers. Answer truthfully that Credvert provides **no** regulated financial service.

Suggested selection: choose the option stating the app **does not provide any of the listed financial features** (no banking, no personal loans, no payments or money transfer, no investments/trading, no crypto, no insurance, no credit repair). If Play requires a category, choose the closest informational one (for example "Personal finance: tools such as budgeting or rewards calculators"). **[VERIFY]** the exact options on the form today; they change.

Explanation text, if a free-text field is offered:

```text
Credvert is an informational tool for people who already hold credit cards or are researching them. It compares publicly available card features (fees, reward rates, lounge access), estimates rewards for a given spend, and reminds users of their own statement and due dates. It does not lend money, offer or facilitate personal loans, issue cards, process payments, hold funds, check credit scores, or submit card applications. Card numbers entered by the user are stored only on the device and are never transmitted. Links to card issuers open the issuer's own website.
```

**Personal loan policy (India):** Not applicable. Credvert offers no loans, EMIs, credit lines or loan comparisons. Do not add loan features without first completing Play's personal loan declaration and India-specific licensing requirements (RBI-regulated entity or partner documentation).

**Affiliate links:** if any "apply" link pays you a commission, add to the description: "Some links may earn Credvert a referral fee from the issuer; this does not affect rankings." Make sure the ranking truly is not affected. **[VERIFY]**

### 7.3 Other App content questions

| Section | Answer | Notes |
| --- | --- | --- |
| Privacy policy | URL from `GET /meta/legal` | Must be public, not a PDF behind login, and name the app and developer. Also link it inside the app (About sheet already does) |
| Ads | **No, my app does not contain ads** | No ad SDK in `pubspec.yaml`. Server banners are the app's own content, not paid third-party ads. **[VERIFY]** no paid placements from banks; if banks pay for banners, answer Yes |
| App access | "All or some functionality is restricted" → provide instructions | Give reviewers a test account (email + password) with 2–3 sample wallet cards and due days set. Add: "Guest mode (Continue as guest) gives access to all features without an account. Revealing or copying card numbers requires a device screen lock or biometric; use Try with sample cards." **[VERIFY]** behaviour on a device with no biometric enrolled |
| Content rating | Section 5 | — |
| Target audience and content | **18 and over** only | See 7.4 |
| News app | No | — |
| COVID-19 contact tracing / status | No | — |
| Data safety | Section 6 | — |
| Government app | No | Not developed by or for a government body |
| Financial features | Section 7.2 | — |
| Health apps | No health features | — |
| Actor/celebrity or "Made for Families" | No | — |
| Account deletion | Yes, in-app and web URL | Section 6.1 |
| Photo and video permissions | Not used | — |
| Foreground service, exact alarm, full-screen intent | Not used | Reminders come from FCM; do not add `SCHEDULE_EXACT_ALARM` unless you build local scheduling. **[VERIFY]** final merged manifest |
| Accessibility API | Not used | — |
| VPN, device admin, SMS/Call log | Not used | Do not add SMS reading for transaction parsing without going through Play's SMS permission review; it is usually rejected for this use |

### 7.4 Target audience

- **Target age groups:** 18 and over only.
- **Appeals to children?** No.
- Reason: credit cards are only issued to adults, and the app deals with financial information. This keeps the app out of the Families policy.

---

## 8. Store graphics specification

### 8.1 Required and recommended assets

| Asset | Spec | Notes |
| --- | --- | --- |
| **App icon** | 512 × 512 px, 32-bit PNG (alpha allowed), ≤ 1 MB | Full-bleed square; Play applies the rounded mask. No text, no badges like "NEW" or "FREE", no bank logos. Should match the launcher icon |
| **Feature graphic** | 1024 × 500 px, JPG or 24-bit PNG (**no alpha**), ≤ 15 MB | Required. Keep key elements in the centre ~ 924 × 400; edges may be cropped. It is shown behind the promo video play button, so avoid important content in the centre if you add a video |
| **Phone screenshots** | 2–8 required. PNG or JPG, no alpha. Each side 320–3840 px, long side ≤ 2 × short side | Use **1080 × 1920** (9:16) or **1080 × 2400**. For eligibility in Play's recommendation surfaces, provide at least **4 screenshots at ≥ 1080 px** on the short side, portrait 9:16 |
| **7-inch tablet screenshots** | Up to 8; 320–3840 px | Optional, but the app has responsive rail layouts; worth adding 4 |
| **10-inch tablet screenshots** | Up to 8; 1080–7680 px | Use 1600 × 2560 or 2560 × 1600. Needed for "designed for tablets" visibility |
| **Chromebook / XR / TV / Wear** | — | Skip |
| **Promo video** | YouTube URL; public or unlisted; ads off; not age-restricted; not a playlist | 30–60 s. Start with the product within 3 s. Show the advisor, biometric copy and compare. Use sample cards. Add captions (many viewers watch muted). Landscape or portrait both work; portrait fits phone-first viewing |

### 8.2 Screenshot rules to avoid rejection

- Show the real app UI. Framed device mockups with a caption are fine; images unrelated to the app are not.
- Captions: short, factual, no "best", "#1", ratings, awards or price claims. Keep text to roughly the top 20–25% of the frame.
- Use **sample cards with fake numbers** (e.g. `4000 00•• •••• 1234`) and made-up nicknames. Never show a real card number.
- Card art: showing a real bank's card image in a screenshot is a trademark risk. Prefer the app's generic metal card skins, or blur/replace bank logos. If you show catalog rows with bank names, keep it small and descriptive.
- Turn off **Hide in screenshots** before capturing, then turn it back on.
- Use the same theme (dark recommended) across all 8 for a consistent strip.
- Localise captions for `hi-IN` later.

### 8.3 Eight-screenshot storyboard

Order matters: the first 2–3 are seen without scrolling. Frame size 1080 × 1920. Layout: caption block at top (headline 64–72 px Manrope SemiBold, subline 34–38 px Inter), device screen below, obsidian gradient background.

| # | Screen to capture | Headline (≤ 32 chars) | Subline (≤ 50 chars) |
| --- | --- | --- | --- |
| 1 | Home advisor result: Dining, ₹2,500, "Best card for this" hero card | `The right card, every checkout` | `Enter an amount, pick a category, see the pick` |
| 2 | International toggle on, result showing forex markup applied | `Paying abroad? Forex counted.` | `Markup plus 18% GST deducted from rewards` |
| 3 | Wallet carousel with 3 sample metal cards | `Your cards, on your phone only` | `Full numbers never leave this device` |
| 4 | Biometric prompt over "Copy number", toast "Copied, clears in 30s" | `Copy at checkout with a touch` | `Biometric check, then the clipboard clears` |
| 5 | Explore with "Lifetime free" + "Lounge" chips active | `Explore 700+ Indian cards` | `Filter by fee, lounges, network and returns` |
| 6 | Compare table with 3 cards and winner highlights | `Compare up to 4 cards` | `Fees, forex, reward rates and lounges` |
| 7 | Rewards calculator: net annual value hero + bar chart | `See a card's yearly value` | `Rewards minus fees, with fee-waiver check` |
| 8 | Wallet insights + a reminder notification in the shade | `A nudge before the due date` | `Statement and due-day reminders you control` |

Alternative #8 if reminders are not in 1.0.0: Account security screen — `Locked down by default` / `App lock, screenshot block, clipboard timer`.

Tablet set (4): Home + advisor side panel, Card detail two-column, Rewards two-column, Compare table.

---

## 9. AI image prompts

### 9.1 Brand guidance for every prompt

- **Mood:** quiet luxury fintech. Dark, calm, precise. Think private-bank metal card, not casino gold.
- **Palette:**
  - Obsidian surfaces: `#090B10` (canvas), `#11151F` (surface), `#181E2C` (raised)
  - Gold accent: `#DFB76C` (use sparingly: edges, highlights, one keyword)
  - Emerald `#10B981` for positive values (rewards, savings)
  - Sapphire `#3B82F6` for information and links
  - Text: off-white `#F4F4F5`, muted `#A1A1AA`
- **Typography (add in Figma/Canva, not in the AI image):** Manrope SemiBold for headlines, Inter Regular/Medium for body and numbers. Use the Indian rupee sign `₹` correctly (Inter supports it).
- **Iconography:** thin-line, rounded (Lucide style).
- **Composition:** generous negative space, one focal object, soft studio lighting, subtle grain, gold rim light.
- **Text in AI images:** most generators still misspell text. Generate **text-free backgrounds** and add all words in a design tool. Ideogram is the only one worth trying for short text, and you should still check every letter.

### 9.2 Legal and safety warnings

- **Do not** generate or include real bank logos, card designs, Visa/Mastercard/RuPay/Amex marks, or anything resembling a specific bank's card, without written permission. Prompts below say "unbranded".
- No realistic card numbers. Use `•••• 1234` style placeholders added later.
- No real people's faces that look like celebrities. If you use people, use generic stock-style models and keep them secondary.
- No currency notes or coins spilling (reads as "get rich" and cheapens the brand).
- Check your generator's commercial-use licence (Midjourney paid plans, DALL·E via OpenAI terms, Ideogram paid plans allow commercial use at the time of writing **[VERIFY]**).

### 9.3 Universal negative prompt

Use as `--no` in Midjourney or as the negative prompt field elsewhere:

```text
text, letters, words, numbers, watermark, signature, logo, bank logo, Visa logo, Mastercard logo, RuPay logo, brand names, real card numbers, QR code, currency notes, coins pile, cartoon, clipart, childish, neon cyberpunk, casino, glitter, lens flare overload, oversaturated, cluttered background, busy pattern, distorted hands, extra fingers, blurry, low resolution, jpeg artifacts, harsh shadows, plastic look, stock photo watermark
```

### 9.4 Feature graphic (1024 × 500)

Generate at 2048 × 1000 (or `--ar 205:100`) and downscale.

**Midjourney**

```text
Ultra-premium fintech hero banner, a single unbranded matte black metal credit card floating at a slight 20-degree tilt on the right third, brushed titanium texture, thin warm gold (#DFB76C) edge highlight, soft emerald (#10B981) glow reflecting underneath, deep obsidian background gradient from #090B10 to #181E2C, faint geometric grid lines, studio product lighting, shallow depth of field, generous empty dark space on the left for a headline, minimal, elegant, photorealistic 3D render, 8k --ar 205:100 --style raw --v 7 --no text, logo, numbers, watermark
```

**DALL·E / GPT-Image**

```text
A wide 1024x500 banner for a luxury credit card app. On the right, one unbranded matte-black metal credit card with no logos, no numbers and no text, tilted slightly, lit by soft studio light with a thin warm-gold rim (#DFB76C) and a faint emerald (#10B981) reflection below it. The background is a smooth deep navy-black gradient (#090B10 to #181E2C) with a very subtle fine grid. The left 55% is empty dark space for text to be added later. Photorealistic, minimal, calm, premium. No text anywhere in the image.
```

**Layout after generation:** left side, "Credvert" wordmark (Manrope SemiBold, off-white), below it `The right card, every checkout.` in Inter, with "right card" in gold. Keep the centre clear if you add a promo video.

### 9.5 Screenshot frame backgrounds (1080 × 1920)

Generate one base, then variations so the 8 frames feel like a set. Place the device screenshot on top in a design tool.

**Base (Midjourney)**

```text
Vertical abstract background for a mobile app screenshot, deep obsidian gradient from #090B10 at the top to #11151F at the bottom, a soft diffuse warm-gold (#DFB76C) light bloom in the upper third, very subtle brushed-metal texture, faint thin concentric arcs, premium fintech mood, lots of empty space, no objects, minimal, matte --ar 9:16 --style raw --no text, logo, numbers, people
```

Per-frame accent variations (append to the base prompt):

| Frame | Append |
| --- | --- |
| 1 Advisor | `, faint gold arc sweeping behind the centre like a compass` |
| 2 International | `, subtle thin-line world map dots in sapphire (#3B82F6) at 10% opacity` |
| 3 Wallet | `, three blurred unbranded metal cards stacked far in the background, out of focus` |
| 4 Biometric copy | `, a soft fingerprint-ridge pattern in gold at 6% opacity near the bottom` |
| 5 Explore | `, a faint grid of rounded rectangles receding into depth` |
| 6 Compare | `, two soft vertical light columns side by side, gold and sapphire` |
| 7 Rewards | `, gentle emerald (#10B981) rising curve of light across the lower half` |
| 8 Reminders | `, a minimal thin-line calendar ring in gold at 8% opacity` |

### 9.6 Social media posters

**Instagram post (1080 × 1080) — product hero**

```text
Square luxury product shot, one unbranded matte black metal credit card standing upright on a glossy obsidian surface, reflection below, warm gold (#DFB76C) rim light from the left, soft emerald (#10B981) accent light from behind, dark gradient background #090B10, cinematic studio lighting, empty space at the top for a headline, photorealistic, minimal, premium fintech --ar 1:1 --style raw --no text, logo, numbers, watermark
```

Overlay: `Which card should you use for this?` + `Credvert ranks your cards for every spend.` + small "Get it on Google Play" badge (use Google's official badge artwork and follow its brand guidelines).

**Instagram post — privacy angle**

```text
Square minimal 3D render, an unbranded dark metal credit card partially inside a translucent smoked-glass vault box, a thin gold (#DFB76C) keyhole glow, obsidian background #11151F, soft volumetric light, calm and secure mood, high detail, generous negative space --ar 1:1 --style raw --no text, logo, numbers, padlock clipart, cartoon
```

Overlay: `Your card number never leaves your phone.`

**Instagram / WhatsApp story (1080 × 1920)**

```text
Vertical premium smartphone scene, a modern unbranded black smartphone floating at a slight angle in the centre with a blank dark screen, an unbranded metal credit card hovering behind it, warm gold (#DFB76C) and emerald (#10B981) light accents, deep obsidian gradient background #090B10 to #181E2C, soft glow, empty space at top and bottom for text, photorealistic render --ar 9:16 --style raw --no text, logo, numbers, app icons, UI
```

Place the real app screenshot on the phone screen afterwards. Keep text out of the top 250 px and bottom 300 px (Instagram UI overlays).

**X / Twitter header (1500 × 500) and LinkedIn banner (1584 × 396)**

```text
Ultra-wide minimal fintech banner, a row of three unbranded matte metal credit cards in black, graphite and deep navy fanned slightly on the right, thin gold (#DFB76C) edge highlights, obsidian background gradient #090B10 to #11151F, faint fine grid, soft studio light, left two-thirds empty for text, calm, premium, photorealistic --ar 3:1 --style raw --no text, logo, numbers
```

For LinkedIn, use `--ar 4:1` and keep content in the centre band (profile photo covers the lower left).

### 9.7 Launch announcement poster (1080 × 1350, 4:5)

```text
Vertical premium launch poster background, a single unbranded matte black metal credit card rising upward out of soft dark mist, warm gold (#DFB76C) light beams radiating subtly from behind, tiny emerald (#10B981) particles like sparks, deep obsidian gradient #090B10, dramatic but elegant studio lighting, large empty area at the top for a headline and at the bottom for a call to action, photorealistic, cinematic --ar 4:5 --style raw --no text, logo, numbers, confetti, fireworks, cartoon
```

Overlay copy:
- Headline: `Credvert is live on Google Play`
- Sub: `Pick the right card for every spend. Keep card details on your phone.`
- CTA: official Google Play badge + short link.

### 9.8 Festive and seasonal campaigns

Keep festive posters useful (a tip or a feature), not "sale" style. Do not promise discounts or bank offers unless an issuer has published them and you show the terms.

**Diwali (Oct–Nov)**

```text
Elegant Diwali-themed luxury fintech poster background, a single unbranded matte black metal credit card resting on a dark obsidian surface, surrounded by a few softly glowing brass diyas with warm flames, subtle marigold petals, warm gold (#DFB76C) bokeh lights in the background, deep #090B10 backdrop, refined and minimal, not cluttered, photorealistic, warm cinematic lighting, empty space at top for headline --ar 4:5 --style raw --no text, logo, numbers, fireworks explosion, rangoli clutter, cartoon, deity images, religious symbols
```

Copy idea: `Festive shopping? Check which card earns more before you pay.` / `Shopping, gifts, travel: ask Credvert first.`
Avoid deity images and religious symbols in commercial posters.

**Travel season (summer holidays / Dec–Jan)**

```text
Premium travel-themed fintech poster, an unbranded dark metal credit card resting on a closed leather passport cover next to a boarding-pass-shaped blank card, soft window light from an airport lounge with a blurred runway at dusk in the background, warm gold (#DFB76C) and sapphire (#3B82F6) tones, obsidian shadows, calm and aspirational, photorealistic, shallow depth of field, empty space at top --ar 4:5 --style raw --no text, logo, numbers, airline logos, passport emblem, flags
```

Copy idea: `Flying abroad? Forex markup + 18% GST, counted for you.` / `Find cards with lounge access in Explore.`

**New Year / fee-renewal season (Jan)**

```text
Minimal new-year fintech poster, an unbranded black metal credit card beside a sleek thin-line gold calendar ring showing no numbers, soft emerald (#10B981) glow, dark obsidian background #11151F, clean studio lighting, calm and organised mood, generous negative space --ar 4:5 --style raw --no text, logo, numbers, fireworks, champagne
```

Copy idea: `New year, fewer surprise fees. See your yearly renewal total in Wallet.`

**Monsoon / online-shopping season (Jul–Sep sale weeks)**

```text
Cosy premium scene, an unbranded dark metal credit card on a wooden desk beside a steaming cup of chai and a blank-screen smartphone, rain streaks on a window in the soft-focus background, warm gold (#DFB76C) lamp light, obsidian tones, calm, photorealistic, empty space at top --ar 4:5 --style raw --no text, logo, numbers, shopping app logos
```

Copy idea: `Sale week? Check which of your cards earns more on online shopping.`

**Ideogram tip (short text in-image)**: add `with the words "Credvert" in clean modern sans-serif, off-white` and nothing longer. Check spelling carefully.

---

## 10. Engagement and growth

### 10.1 Onboarding

- **Show value before sign-up.** Keep "Continue as guest" prominent; let people try the advisor with **Try with sample cards** in the first minute.
- **First success in under 60 seconds:** the first screen after onboarding should be the advisor with a pre-filled example (e.g. Dining, ₹1,500) and the sample wallet.
- **Explain privacy once, at the right moment:** show the "stored only on this phone" note the first time the user types a card number, not as a wall of text on launch.
- **Ask permissions in context:** notifications when they add a due day; biometric enrol prompt when they first reveal/copy.
- **Nudge the one setup step that matters:** after adding the first card, ask for statement and due days ("Add due day for reminders"). No due day means no reminders.
- **Convert guests gently:** after the third advisor use, or when they add a second card, show "Sign in to sync your wallet to a new phone." Never block features behind sign-in.

### 10.2 Push notification copy library

Principles:
- Reminders must be about the user's own dates and be worth receiving. At most one reminder per card per trigger, sent at 09:00 IST (the backend default).
- Never include the last 4 digits, card number, amounts owed or balances. The app does not know the outstanding amount, and lock screens are public. Use the nickname (the user chose it) or the bank name.
- Product news is **off by default**; only send marketing to users who opted in, and cap at 2 per month.
- Title ≤ 40 characters, body ≤ 110 characters so nothing is cut off on most phones.
- Every reminder opens `/wallet`.

**Due-date reminders** (`type: due_date`)

| Trigger | Title | Body |
| --- | --- | --- |
| 3 days before | `Payment due in 3 days` | `Your {nickname} bill is due on {date}. Pay on time to avoid late fees and interest.` |
| 1 day before | `Payment due tomorrow` | `{nickname} ({bank}) is due tomorrow, {date}.` |
| On the day | `Payment due today` | `Today is the due date for {nickname}. If you have already paid, you can ignore this.` |

**Statement reminders** (`type: statement`)

| Trigger | Title | Body |
| --- | --- | --- |
| 1 day before | `Statement tomorrow` | `{nickname}'s statement is generated tomorrow. Spends from the day after count toward the next cycle.` |
| On the day | `New statement for {nickname}` | `Your statement is ready in your bank app. The due date is {due_date}.` |

Verify with a finance-savvy reviewer that the "count toward the next cycle" line is correct for all issuers before using it; if unsure, use `{nickname}'s statement is generated tomorrow.`

**Setup and utility** (sent once, only if relevant)

| Trigger | Title | Body |
| --- | --- | --- |
| Test push (settings button) | `Reminders are on` | `You'll hear from Credvert before your card payments are due.` |
| Card added without due day (next day, once) | `Add a due day?` | `Set a due day for {nickname} and Credvert will remind you before the bill.` |

**Re-engagement** (opted-in to product news only; max once per 30 days; stop after 2 ignored)

| Title | Body |
| --- | --- |
| `Paying abroad soon?` | `Switch on international mode to see which of your cards costs less after forex markup.` |
| `Which card for groceries?` | `Ask the advisor. It takes a few seconds.` |
| `Your yearly card fees` | `See your total renewal fees and which cards earn the most in Wallet insights.` |

**Feature announcements** (opted-in only)

| Title | Body |
| --- | --- |
| `New: compare up to 4 cards` | `Put cards side by side: fees, forex, reward rates and lounges.` |
| `New in Credvert` | `{feature one-liner}. Update to try it.` |

### 10.3 In-app review prompt

The project does not include `in_app_review` yet; add it when ready (Play In-App Review API).

When to ask (all must be true):
- The user has had a clear success: 3+ advisor results, or copied a card number via biometric 2+ times, or finished a calculator run.
- At least 3 days since install and at least the 3rd session.
- No error, crash or failed sync in the current session.
- Not during checkout flow (right after copy); ask when they return to Home.
- Not more than once every 90 days, and never again after they leave a review (Play also enforces its own quota).

Rules: do not ask "Do you like the app?" first and only send happy users to Play (review gating is against policy). Do not offer rewards for reviews.

### 10.4 Release notes ("What's new", ≤ 500 characters)

**v1.0.0** (415 chars)

```text
Welcome to Credvert.
• Advisor: see which of your cards earns more for any spend, including international mode with forex markup and GST.
• Wallet: save cards with a nickname; card numbers stay encrypted on your phone.
• Explore 700+ Indian cards, compare up to 4 and shortlist favourites.
• Rewards calculator with fee-waiver check.
• Due-date and statement reminders.
Tell us what to improve: support@credvert.app
```

**Template: feature release** (≤ 500)

```text
New in this version:
• {Feature}: {one-line benefit}.
• {Feature}: {one-line benefit}.
Improvements:
• {Fix or speed-up in plain words}.
Thanks for the feedback that shaped this update.
```

**Template: fixes-only release**

```text
This update fixes {issue users noticed, e.g. "copy number not working on some Android 14 phones"} and makes {area} faster and more reliable. Thanks for reporting it.
```

**Template: security/privacy release**

```text
Security update: {what changed, e.g. "the clipboard now clears even when the app is closed"}. Your card numbers still stay only on your phone. We recommend updating.
```

Avoid "bug fixes and performance improvements" on its own; say what got better.

### 10.5 Launch checklist (marketing side)

- [ ] Landing page live: one-line pitch, 3 screenshots, Play badge, privacy policy, deletion page, support email.
- [ ] Social handles reserved in the chosen brand name (Instagram, X, LinkedIn, YouTube).
- [ ] Promo video uploaded (unlisted is fine) and linked in the listing.
- [ ] Short link / UTM for Play URL: `https://play.google.com/store/apps/details?id=com.jaychauhan.credvert&referrer=utm_source%3D{source}%26utm_medium%3D{medium}%26utm_campaign%3Dlaunch`.
- [ ] Launch posts scheduled (section 10.6).
- [ ] Friends/testers asked to leave honest reviews in the first week (no incentives).
- [ ] Posts in relevant communities where self-promotion is allowed (r/CreditCardsIndia rules check, TechnoFino forum, personal-finance Discords/Telegram groups).
- [ ] Monitor Android vitals (crash rate < 1.09%, ANR rate < 0.47% — Play's bad-behaviour thresholds) and reply to every review in week 1.

### 10.6 Social caption templates

**Launch (Instagram/LinkedIn)**

```text
Credvert is now on Google Play.

If you carry more than one credit card, you know the checkout-counter question: which one should I use?

Credvert ranks the cards you hold for that exact spend and shows the estimated reward in rupees. Paying abroad? It accounts for forex markup and the 18% GST on it.

Your card numbers stay encrypted on your phone. They are never uploaded.

Free on Google Play: {link}
```

**Feature tip (X, ≤ 280)**

```text
Paying in dollars this month? Credvert's international mode subtracts each card's forex markup plus 18% GST before ranking your cards, so you see the real return. {link}
```

**Privacy post**

```text
We built Credvert so your card number never has to leave your phone.
• Stored encrypted on the device
• Fingerprint to reveal or copy
• Clipboard clears itself
• Screenshots blocked
Only the nickname and last 4 digits sync. {link}
```

**Festive**

```text
Festive shopping list ready? Before you pay, ask Credvert which of your cards earns more on online shopping, electronics or travel. Estimates are based on published card features; check your bank's current terms. {link}
```

Hashtags (use 3–5, not 20): `#CreditCards #PersonalFinanceIndia #CreditCardRewards #FintechIndia #MoneyTips`

### 10.7 Play review reply templates (limit 350 characters)

**Positive**

```text
Thank you for trying Credvert. Glad the advisor is helping you pick the right card. If there's a card or feature you'd like us to add, write to support@credvert.app.
```

**Bug report**

```text
Sorry about this, and thanks for reporting it. Could you email support@credvert.app with your phone model and Android version? We'll look into it right away and reply to you. A fix for {issue} is also in progress.
```

**Feature request**

```text
Thanks for the suggestion. {Feature} is on our list, and requests like yours help us decide what to build next. We'll mention it in the release notes when it ships.
```

**Privacy / security concern**

```text
Thanks for asking. Your full card number, expiry and CVV are encrypted on your phone and are never sent to our servers. Only the card name, nickname and last 4 digits sync if you sign in, and guest mode keeps everything on the device. Details: {privacy URL}
```

**Wrong card data**

```text
Thanks for flagging this. Card terms change often and we'd like to fix it. Please email support@credvert.app with the card name and what looks wrong, and we'll update it. Always confirm current terms with your bank.
```

**Negative, no detail**

```text
Sorry Credvert didn't work for you. We'd like to understand what went wrong so we can fix it. Please write to support@credvert.app and we'll get back to you.
```

---

## 11. FAQ (store listing website / help page)

The in-app Help screen reads from `GET /meta/faq`; keep these consistent with that content.

**1. What does Credvert do?**
It tells you which of your credit cards earns the most for a specific spend, helps you explore and compare Indian credit cards, estimates a card's yearly value, and reminds you of statement and payment due dates.

**2. Is Credvert a bank or a card issuer?**
No. Credvert is an independent information tool. It is not a bank, issuer, lender or payment app, and it is not affiliated with any bank or card network.

**3. Can I apply for a credit card through Credvert?**
No. Credvert does not submit applications. Card pages link to the issuer's own website, where you apply directly with the bank.

**4. Where is my card number stored?**
Only on your phone, encrypted with keys held in Android's secure hardware (Keystore) or the iPhone Secure Enclave. It is never sent to our servers.

**5. What does sync to my account?**
If you sign in: which card you hold (product and bank), your nickname for it, the last 4 digits, the statement and due days, and the card order. Never the full number, expiry or CVV.

**6. Do I need an account?**
No. Guest mode keeps everything on your device. You can sign in later to sync your wallet across phones.

**7. What happens to my saved card numbers if I change phones?**
Full card numbers stay on the old phone by design. On the new phone, sign in to restore your wallet (nicknames, last 4, dates), then add the full numbers again if you want to copy them at checkout.

**8. How accurate are the reward estimates?**
They are estimates based on each card's published earn rates, caps and point values. Issuers change terms, and some rewards depend on merchant codes or monthly caps, so confirm with your bank.

**9. How does international mode work?**
It subtracts the card's foreign-currency markup plus 18% GST on that markup from the reward, so cards with low or zero markup rank higher for spends abroad.

**10. Does Credvert see my transactions or read my SMS?**
No. Credvert does not connect to your bank, read SMS or see your transactions. It only uses the amount and category you type in.

**11. How do reminders work?**
Add a statement day and due day to a card. Credvert sends a notification before the payment is due and when the statement is generated. You can change the timing or turn them off in settings.

**12. Does Credvert affect my credit score?**
No. Credvert does not check or report your credit score.

**13. How do I delete my account and data?**
In the app: Account → Delete account. This removes your account, synced wallet and shortlist. You can also request deletion at {deletion URL}. For guest data, use Account → Reset this device, or uninstall the app.

**14. Why can't I take a screenshot?**
Screenshots are blocked to protect card details. You can turn this off in Account → Security → Hide in screenshots.

**15. Is Credvert free?**
Yes. There are no subscriptions or in-app purchases. **[VERIFY]** and update if this changes.

---

## 12. Pre-launch checklist (Play Console)

### Account and legal

- [ ] Developer account type decided (personal vs organisation). Organisation accounts need a D-U-N-S number and let you show a company name instead of your personal name. For a finance app, an organisation account builds more trust. **[VERIFY]**
- [ ] Identity verification completed; developer contact details (email, and address if required) are correct. Personal accounts may show address publicly if you monetise.
- [ ] **Privacy policy URL** live (from `GET /meta/legal`), public, mentions: data types in section 6, Firebase as processor, on-device card storage, retention, deletion, contact, grievance officer contact (India DPDP Act 2023 expects a contact point for grievances).
- [ ] **Terms of use URL** live.
- [ ] **Account deletion web URL** live and working without the app.
- [ ] Trademark and name search done for the chosen brand (section 1).
- [ ] Rights to card data and card images confirmed (section 0, item 6).

### Build

- [ ] One brand name everywhere: app label, `AppStrings.appName`, biometric prompts, notification channel names, privacy policy.
- [ ] Target SDK meets the current Play requirement. New apps had to target API 35 from 31 Aug 2025; the requirement moves up yearly around 31 Aug, so check whether API 36 is now required. **[VERIFY]**
- [ ] Release signed with an upload key; **Play App Signing** enrolled. Upload key backed up offline (you cannot recover it).
- [ ] Android App Bundle (`flutter build appbundle --release`), with `--obfuscate --split-debug-info` and the symbols uploaded to Crashlytics.
- [ ] Version code incremented for every upload.
- [ ] Merged manifest checked: only `INTERNET`, `USE_BIOMETRIC`, `POST_NOTIFICATIONS` (+ `AD_ID` only if declared), and whatever Firebase adds (`WAKE_LOCK`, `RECEIVE_BOOT_COMPLETED`, `ACCESS_NETWORK_STATE`, `com.google.android.c2dm.permission.RECEIVE`). Declare consistently.
- [ ] Production API uses HTTPS; no debug base URLs; dev-only `reset_token` behaviour off in production (`ENVIRONMENT=production`).
- [ ] Notification channel id agreed between app and server (section 0, item 4) and channel created before requesting a token.
- [ ] Diagnostics default decided (opt-in vs opt-out) and Data safety updated to match.
- [ ] `allowBackup=false` kept (it is), so vault data is not included in cloud backups.
- [ ] Tested on Android 10, 13 and 14/15/16 devices, including one without fingerprint hardware, one with only face unlock, and one small screen.
- [ ] Biometric reveal/copy works after a device PIN change and after adding a new fingerprint (Keystore keys may be invalidated).
- [ ] Offline mode, guest-to-account migration, and account deletion tested end to end.
- [ ] Push reminders tested with the test endpoint and on the real 09:00 IST schedule; tapping opens Wallet.

### Store listing

- [ ] Title, short description and full description pasted (sections 1–3), counts re-checked.
- [ ] Icon 512, feature graphic 1024×500, 8 phone screenshots, 4 tablet screenshots uploaded (section 8).
- [ ] Promo video URL (optional).
- [ ] Category Finance, tags, contact email, website set.
- [ ] Content rating questionnaire done (section 5).
- [ ] App content: privacy policy, ads, app access (reviewer test account), target audience 18+, data safety, financial features, government/news/health = No, account deletion (section 7).
- [ ] Countries: India first (consider adding others only after checking card data relevance).
- [ ] Pricing: Free.

### Testing tracks

- [ ] **Internal testing** track: up to 100 testers, available within minutes. Use it for smoke tests and for the pre-launch report (Play's automated device tests; fix accessibility and crash warnings).
- [ ] **Closed testing** — required for **personal developer accounts created after 13 Nov 2023**: at least **12 testers** must be **opted in continuously for at least 14 days** before you can apply for production access. Recruit 15–20 to allow for drop-outs; testers must opt in via the Play test link with the Google account they use on their phone, and stay opted in the whole 14 days.
- [ ] Collect feedback from closed testers (a simple form), fix issues, and push at least one update during the 14 days; the production access application asks what you learned and changed.
- [ ] Apply for production access (Dashboard → "Apply for production"), answering the questionnaire about testing, the app's audience and readiness.
- [ ] Production review can take several days for a new finance app; plan a buffer of 1–2 weeks and avoid announcing a fixed launch date.
- [ ] Staged rollout: start at 20%, watch Android vitals and reviews for 48 hours, then 50% → 100%.

### After launch (first 30 days)

- [ ] Reply to every review (section 10.7).
- [ ] Watch Android vitals, Crashlytics and the pre-launch report for new versions.
- [ ] Check search terms in Play Console after 2–3 weeks and adjust the description (section 4).
- [ ] Start a store listing experiment on screenshot 1 or the short description.
- [ ] Add the in-app review prompt (section 10.3) in the first update.
- [ ] Add the Hindi listing translation.
