# Firebase setup for Credvert

Project: **credvance-cb042**  
Android package and iOS bundle: `com.jaychauhan.credvert`  
Installed version today: `1.0.0` (build `1`), from `pubspec.yaml`.

The app already contains `google-services.json` and `GoogleService-Info.plist`. This document is the console setup. Until you publish Remote Config, the app uses safe defaults: no maintenance, no forced update, and every feature stays on.

## Products included

These are the free Firebase products wired into the app:

| Product | What it does in Credvert |
| --- | --- |
| Remote Config | Maintenance, force update, soft update, announcements, what's new, feature flags, support links |
| Google Analytics | Screen views, update and announcement events, auth state. No card numbers, CVVs, or email |
| Crashlytics | Fatal and non-fatal crashes in release builds. Debug builds do not upload crashes |
| Performance Monitoring | Times the Remote Config fetch in release builds |
| Cloud Messaging | Foreground alerts, plus a Notifications row in Account. No permission prompt on launch |

Not added, on purpose:

- **Authentication, Firestore, Storage, Functions** — Credvert already has its own account API and does not store card secrets in Firebase.
- **App Check** — turn this on later, after Play Integrity and DeviceCheck are configured. Enabling it early can block Analytics and Remote Config.
- **In-App Messaging** — announcements are driven by Remote Config so the copy, schedule, and dismiss rules stay in one place.

## 1. Turn the products on

1. Open [Firebase console](https://console.firebase.google.com/) and select **credvance-cb042**.
2. **Analytics.** Project settings → Integrations → Google Analytics → Enable. The iOS config now has analytics collection on.
3. **Remote Config.** Build → Remote Config. If the API is off, enable it.
4. **Crashlytics.** Build → Crashlytics → Enable. The first report appears after a release build runs on a device.
5. **Performance.** Build → Performance → Get started.
6. **Cloud Messaging.** Build → Messaging. Android works with the existing `google-services.json`. iOS also needs an APNs key: Project settings → Cloud Messaging → Apple app configuration → upload the key from Apple Developer.

## 2. Import Remote Config

1. Build → Remote Config.
2. Open the menu (three dots) → **Import from file** / **Publish from a file**, depending on the console label.
3. Choose [`firebase_remote_config_template.json`](firebase_remote_config_template.json).
4. Review the parameters. Do not publish a force update yet.
5. Click **Publish**.

Publishing is what makes values reach the app. Drafts stay in the console.

Debug builds fetch on every launch and on **Account → Check for updates**. Release builds cache Remote Config for one hour, except:

- **Try again** on the maintenance screen and **Check for updates** always fetch.
- Realtime updates apply while the app is open and online, without waiting for the hour.

## 3. How the app decides what to show

On launch the app shows a short Credvert splash, fetches Remote Config, then continues. If the fetch fails, it keeps the last good values, or the defaults on a first install. A bad value never locks every user out.

Priority, highest first:

1. **Maintenance**, when `maintenance_enabled` is true and the schedule is open.
2. **Force update**, when this install is below `min_supported_version` or `min_supported_build`.
3. **Blocking announcement**, when severity is `critical` and `announcement_dismissible` is false.
4. The normal app, with an optional announcement banner.
5. A **soft update** sheet, once per latest version, until the person taps **Not now**.
6. A **What's new** sheet, once per `whats_new_version`, after the soft update is out of the way.

People can turn analytics and crash reports off in **Account → Privacy**. That switch never includes card numbers or CVVs. Crash and performance uploads stay off in debug builds even when the switch is on, so local development does not fill the dashboard. Analytics still records in debug, which is what you want for DebugView.

## 4. Parameter rules

Versions are exactly `major.minor.patch`, such as `1.2.0`. `1.2`, `v1.2.0`, and `1.2.0-beta` are ignored. If a force-update version is invalid, the app does **not** block anyone.

Build numbers are the integer after `+` in `pubspec.yaml` (`1.0.0+1` means build 1). `0` means "do not use the build check".

Dates are ISO-8601 UTC: `2026-10-01T18:30:00Z`. An empty date means "no bound". If the end is before the start, that window stays closed.

Links must be `https`, `http`, `mailto`, `itms-apps`, or `market`. Anything else, including `javascript:`, is dropped.

`support_email` is a plain address (`hello@credvert.app`), not a `mailto:` URL.

`announcement_id` and `whats_new_version` are 1–64 and 1–32 characters: letters, numbers, `.`, `_`, `-`.

`announcement_severity` is `info`, `success`, `warning`, or `critical`. Anything else becomes `info`.

Text that is too long is shortened: titles 80 characters, messages 600, button labels 24 (update) or 32 (announcement), what's-new lines 140, and at most 8 lines.

An announcement button appears only when both the label and a valid URL are set.

## 5. Recipes

Publish after each change, then reopen a debug build or tap **Check for updates**.

### Force update

Set the iOS store URL first. Android already points at the Play listing for `com.jaychauhan.credvert` (the listing has to exist or the button opens a missing page).

```
force_update_enabled = true
min_supported_version = 1.2.0
min_supported_build = 0
ios_store_url = https://apps.apple.com/app/idYOUR_APP_ID
```

Installs on `1.0.0` see a blocking screen with no way to dismiss it. `1.2.0` and newer stay in the app. To test without shipping 1.2.0, set `min_supported_version` to `9.0.0`, confirm the screen, then set it back to `1.0.0` and publish again.

`min_supported_build` is a second floor. With the current build `1`, setting this to `2` blocks this build even when the version name matches. Leave it at `0` unless you mean that.

### Soft update

```
force_update_enabled = false
soft_update_enabled = true
latest_version = 1.1.0
latest_build = 0
```

The sheet has **Update now** and **Not now**. **Not now** hides it until `latest_version` or `latest_build` changes. Dragging the sheet away hides it for this session only; it comes back on the next launch.

### Maintenance

```
maintenance_enabled = true
maintenance_title = Scheduled maintenance
maintenance_message = Credvert will be back at 11pm IST. Your cards stay on this phone.
maintenance_starts_at = 2026-10-01T17:30:00Z
maintenance_ends_at = 2026-10-01T18:30:00Z
maintenance_show_retry = true
support_email = hello@credvert.app
```

Outside that window the app works normally, even if you forget to flip the switch, as long as the end time is still in the future when you published it. After the end time passes, the screen goes away on the next fetch. **Try again** fetches immediately.

### Announcement banner

```
announcement_enabled = true
announcement_id = diwali-2026
announcement_title = Festival offers are live
announcement_message = Compare lounge and travel cards before you book.
announcement_severity = info
announcement_dismissible = true
announcement_action_label = See travel cards
announcement_action_url = https://credvert.app/travel
```

Dismiss is remembered for that `announcement_id`. Use a new id for the next message.

### Blocking notice

```
announcement_severity = critical
announcement_dismissible = false
```

Use this for a short legal or security notice. Maintenance is the better tool for downtime, because it has a retry button and a schedule.

### What's new

```
whats_new_enabled = true
whats_new_version = 1.1.0
whats_new_title = What's new
whats_new_body = Faster card compare
Rewards chart for monthly spends
Clearer fee totals
```

Each line is a bullet. Changing `whats_new_version` shows the sheet again.

### Feature flags

| Key | Off means |
| --- | --- |
| `feature_guest_mode_enabled` | The sign-in screen hides "Continue without an account". Existing guest sessions stay as they are |
| `feature_advisor_enabled` | Home explains that recommendations are paused |
| `feature_calculator_enabled` | The Rewards tab explains that the calculator is paused |
| `feature_compare_enabled` | Compare is hidden in Explore and tapping Compare explains that it is off |
| `feature_push_enabled` | The Notifications row is hidden. This does not delete existing push tokens |

### Support and legal links

`privacy_policy_url` and `terms_url` are used only when the Credvert API does not return a link. `support_email` adds **Contact support** on the maintenance and update screens, and a row in Account. `help_url` adds **Help center**.

## 6. Analytics events

| Event | When |
| --- | --- |
| `screen_view` | Home, wallet, explore, rewards, account |
| `remote_config_fetch` | After each fetch. Parameter `result` is `success` or `fallback` |
| `remote_config_warning` | A published value was ignored or shortened |
| `maintenance_shown` | Maintenance screen |
| `force_update_shown` | Blocking update screen |
| `update_opened` | Store button. Parameter `kind` is `force` or `soft` |
| `soft_update_shown` / `soft_update_dismissed` | Soft update sheet |
| `whats_new_shown` | What's new sheet |
| `announcement_shown` / `announcement_dismissed` / `announcement_opened` | Announcement |
| `notification_permission` | After the person taps Notifications |

User property `auth_state` is `signed_in`, `guest`, `signed_out`, or `unknown`. The Analytics user id is the account id only. Email is not sent. Crashlytics gets the same id, plus `app_version`, `maintenance`, and `force_update`.

To watch events while developing: Firebase console → Analytics → DebugView, then run a debug build.

## 7. Notifications

The app does not ask for notification permission at launch. The person turns it on from **Account → Privacy → Notifications**, and only when `feature_push_enabled` is true.

Android uses the channel **Credvert updates** (`credvert_general`). A message received while the app is open shows as an in-app notice. A message received in the background is shown by the system.

iOS needs the APNs key from section 1 before Test on device works. Send a test from Messaging → Create campaign → Firebase Notification messages, or use **Send test message** with the device token from the debug logs.

## 8. Crashlytics and Performance

Crashlytics and Performance collection start only in release or profile builds, and only while **Usage & crash reports** is on. To confirm Crashlytics, ship a release build to a device, then check Build → Crashlytics after a few minutes.

The iOS target uploads dSYM files when CocoaPods has installed `FirebaseCrashlytics`. Run `flutter build ios` (or open the iOS project after `pod install`) before expecting symbolicated crashes.

## 9. Checklist before a force update

- [ ] Play Store listing exists for `com.jaychauhan.credvert`
- [ ] `ios_store_url` is the real App Store link
- [ ] `min_supported_version` is a version you have actually shipped
- [ ] `min_supported_build` is `0`, or a version code you have actually shipped
- [ ] `support_email` is set, so a blocked person can still reach you
- [ ] You tested with `9.0.0` on a debug build, then published the real minimum

## 10. Files

| File | Role |
| --- | --- |
| `docs/firebase_remote_config_template.json` | Import this into Remote Config |
| `lib/core/firebase/` | Startup, Analytics, Crashlytics, Messaging |
| `lib/features/remote_config/` | Parsing, validation, and the screens |
| `android/app/google-services.json` | Android Firebase config, already present |
| `ios/Runner/GoogleService-Info.plist` | iOS Firebase config, already present |
