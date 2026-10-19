# Account and Data Deletion Policy for Credvert

**Effective Date:** October 18, 2026  
**Last Updated:** October 18, 2026  
**Application Name:** Credvert  
**Package Name:** `com.jaychauhan.credvert`  
**Developer:** Jay Chauhan  
**Contact Email:** `privacy@credvert.app` / `support@credvert.app`  
**Web Deletion Request URL:** `https://credvert.app/deletion`  

---

## 1. Overview and Commitment

Credvert respects your right to privacy and full control over your personal data. In strict compliance with **Google Play Store Data Safety Policies**, **Apple App Store Review Guidelines (Guideline 5.1.1)**, the **India Digital Personal Data Protection Act (DPDP Act, 2023)**, and the **General Data Protection Regulation (GDPR)**, Credvert provides straightforward, transparent, and permanent data deletion mechanisms.

You can delete your account and all associated data at any time:
1. Directly within the Credvert mobile application.
2. Online via our web deletion portal (without needing to reinstall or open the mobile app).
3. By emailing our privacy team directly.

---

## 2. How to Delete Your Account and Data

### Method 1: In-App Instant Deletion (Recommended)
If you have the Credvert app installed on your device:
1. Open the **Credvert** application.
2. Navigate to the **Account** tab (profile icon in the bottom navigation bar).
3. Scroll down to the **Account management** section.
4. Tap **Delete account** (highlighted in red).
5. Read the confirmation dialog summarizing the permanent deletion process.
6. Tap **Delete permanently** to confirm.
7. Your session is terminated immediately, your cloud account and all synced records are queued for immediate permanent erasure, and local app cache is purged.

---

### Method 2: Web Deletion Request (If App is Uninstalled)
If you no longer have access to your mobile device or have uninstalled Credvert:
1. Visit our official data deletion portal: **[https://credvert.app/deletion](https://credvert.app/deletion)**.
2. Enter the registered email address associated with your Credvert account.
3. Click **Submit Deletion Request**.
4. An automated verification link will be dispatched to your email address to confirm ownership.
5. Click the confirmation link in the email.
6. Upon confirmation, your account deletion is processed immediately.

---

### Method 3: Email Request
You can also request account and data deletion by sending an email from your registered email address to:
- **Email:** `privacy@credvert.app`
- **Subject:** `Data Deletion Request - [Your Registered Email]`
- **Processing Time:** Our privacy team will verify the request and complete the deletion process within **forty-eight (48) hours**, sending you written confirmation upon completion.

---

### Method 4: Guest Mode / Local-Only Users
If you used Credvert without creating an account (Guest Mode):
- None of your data was ever sent to our remote servers.
- To purge all locally stored information:
  - Go to **Account → Reset this device**, or
  - Go to your device's **Settings → Apps → Credvert → Storage → Clear Storage / Clear Data**, or
  - Simply uninstall the Credvert app from your device.
- All hardware-encrypted card tokens and local SQLite database records will be instantaneously and permanently destroyed.

---

## 3. What Information Is Deleted

When an account deletion request is processed, the following information is **permanently and irreversibly purged**:

| Data Category | Specific Items Deleted | Timeline |
| :--- | :--- | :--- |
| **Authentication & Profile Data** | User ID, email address, password hash, display name, and authentication session tokens. | Deleted immediately (within 24 hours). |
| **Synced Card Metadata** | Card product mappings, issuing bank names, user-assigned card nicknames, last 4 digits, billing statement dates, and payment due dates. | Deleted immediately (within 24 hours). |
| **Spend & Expense History** | All parsed transaction records, merchant names, amounts, categories, milestone histories, and bill reminders stored in your cloud account. | Deleted immediately (within 24 hours). |
| **Shortlist & Preferences** | Bookmarked cards, comparison tray configurations, custom spend assumptions, and notification preferences. | Deleted immediately (within 24 hours). |
| **Device Tokens** | Firebase Cloud Messaging (FCM) push notification tokens and installation IDs. | Unlinked and invalidated immediately. |
| **Local Device Secrets** | Hardware-encrypted card numbers (PAN), CVVs, and expiry dates stored in Android KeyStore / iOS Secure Enclave. | Cleared upon in-app account deletion or local app storage wipe. |

---

## 4. What Information Is Retained (If Any) and Retention Timelines

| Category | Reason for Temporary Retention | Maximum Retention Period |
| :--- | :--- | :--- |
| **Server Logs (Anonymized)** | System security logs, IP addresses associated with requests, and rate-limiting traces retained strictly for threat mitigation and fraud prevention. | Purged automatically on a rolling **30-day** window. |
| **Database Backups** | Encrypted snapshots of the production database maintained for disaster recovery. Backups are isolated and cannot be queried for production operations. | Automatically overwritten and permanently expunged within **30 to 90 days** in accordance with our automated backup rotation policy. |
| **Legal / Dispute Records** | In the rare event of an ongoing legal dispute, regulatory inquiry, or valid law enforcement subpoena, minimal relevant records may be preserved as mandated by applicable statutory law. | Only for the duration legally required by court order or statutory limitation period. |

---

## 5. Third-Party Service Providers (Sub-Processors)

When your deletion request is executed, deletion directives are cascaded to our processors:
- **Google Firebase:** User authentication records are removed from Firebase Auth; analytics user properties are unlinked (`setUserId(null)`).
- **PostgreSQL Database:** All foreign-key relationships linked to your user record (`cards`, `shortlist`, `spend_transactions`, `bill_notices`) use `ON DELETE CASCADE` and are immediately deleted.

---

## 6. Questions and Contact

For any questions, verification status, or assistance regarding data deletion, please contact:

- **Data Protection Officer / Grievance Officer:** Jay Chauhan
- **Privacy Email:** `privacy@credvert.app`
- **Support Email:** `support@credvert.app`
- **Official Address:** Ahmedabad, Gujarat, India
