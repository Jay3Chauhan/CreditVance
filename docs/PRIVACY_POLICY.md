# Privacy Policy for Credvert

**Effective Date:** October 18, 2026  
**Last Updated:** October 18, 2026  
**Application Name:** Credvert  
**Package Name:** `com.jaychauhan.credvert`  
**Developer:** Jay Chauhan  
**Contact Email:** `privacy@credvert.app` / `support@credvert.app`  
**Grievance Officer Contact:** `grievance@credvert.app`

---

## 1. Introduction and Philosophy

Credvert ("we", "our", or "us") provides a privacy-first credit card intelligence, rewards optimization, expense tracking, and card management application. Our architectural philosophy is built upon **Zero-Knowledge Security** and **Data Minimization**:

1. **Your full card numbers (PAN), CVVs, and expiry dates never leave your physical device.** They are stored exclusively in your device's hardware security enclave (Android Keystore / iOS Keychain & Secure Enclave).
2. **We never sell, rent, monetize, or trade your personal or financial data** to third-party data brokers, advertisers, loan aggregators, or credit bureaus.
3. **SMS parsing is performed 100% on-device.** The raw text of your personal SMS messages, OTPs, or chats is never uploaded to any remote server.
4. **Biometric data (fingerprint or face) is processed exclusively by your device's operating system.** Credvert never has access to, nor does it store or transmit, your biometric templates.

This Privacy Policy explains what information we collect, what information remains strictly on your device, how we process data, and your rights under global privacy laws including the **Digital Personal Data Protection Act (DPDP Act, India 2023)**, the **General Data Protection Regulation (GDPR / UK GDPR)**, and the **California Consumer Privacy Act (CCPA / CPRA)**.

---

## 2. Information Handled by Credvert

### 2.1 Information Stored Strictly On-Device (Never Collected by Servers)

| Data Type | Description & Purpose | Storage Mechanism | Transmitted to Server? |
| :--- | :--- | :--- | :--- |
| **Card Primary Account Number (PAN)** | Full 16-digit credit card number used for quick one-tap autofill or manual clipboard copy at checkout. | Hardware-backed Android Keystore / iOS Secure Enclave via `flutter_secure_storage`. Protected by AES-256-GCM / RSA encryption. | **NO (Zero-Knowledge)** |
| **Card CVV / Security Code** | 3-digit or 4-digit card verification value. | Hardware-backed Android Keystore / iOS Secure Enclave. Protected by biometric authentication gate. | **NO (Zero-Knowledge)** |
| **Card Full Expiry Date** | Expiry month and year. | Hardware-backed Android Keystore / iOS Secure Enclave. | **NO (Zero-Knowledge)** |
| **Biometric Credentials** | Fingerprint scans, Touch ID, Face ID, or system PINs. | Handled entirely by Android `BiometricPrompt` and iOS `LocalAuthentication` frameworks. | **NO (Never Accessible by App)** |
| **Raw SMS Text Messages** | The full body of text messages received on the device. | Filtered in memory for bank transaction alerts. Processed locally and discarded immediately. | **NO (Never Leaves Phone)** |
| **Guest Mode Local Database** | Card metadata, calculation inputs, and custom settings when using the app without signing in. | Local SQLite database on the device. | **NO** |

---

### 2.2 Information Collected and Synced When You Create an Account

If you choose to sign in to Credvert to sync your data across devices, we collect and process the following information:

| Category | Specific Data Collected | Purpose | Lawful Basis |
| :--- | :--- | :--- | :--- |
| **Account Credentials** | Email address, hashed password, optional display name, account creation timestamp. | Account creation, authentication, password recovery, and security verification. | Performance of Contract |
| **Card Metadata (Non-Sensitive)** | Card product name (e.g., "Infinia", "Regalia Gold"), issuing bank, user-defined card nickname, last 4 digits of the card, billing statement day, and payment due day. | Multi-device synchronization of your active wallet, milestone reminders, and statement alerts. *(Note: Last 4 digits are used solely for card identification).* | Performance of Contract |
| **Spend & Transaction Records** | Extracted transaction amount, currency code, merchant name, spend category, transaction timestamp, issuing bank, and the card's last 4 digits. | Providing spend analytics, monthly category breakdowns, unusual spend alerts, and card fee-waiver milestone calculations. | Explicit Consent / Performance of Contract |
| **Shortlisted & Compared Cards** | Identifiers of credit cards you have bookmarked, shortlisted, or added to the comparison tray. | Syncing your research progress and card preferences across your devices. | Performance of Contract |
| **App Settings & Preferences** | Theme preference (dark/light), default currency, reminder lead times, and advisor spend defaults. | Saving user experience preferences. | Legitimate Interests |

---

### 2.3 Diagnostic, Performance, and Device Information

To ensure application stability, prevent crashes, and deliver timely reminders, we collect minimal technical diagnostics:

1. **Crash Reports (Firebase Crashlytics):** Stack traces, device model, operating system version, and application build number when an unexpected error occurs. Crash reports are anonymized and **never include card numbers, CVVs, or personal financial details**.
2. **Performance Traces (Firebase Performance Monitoring):** Anonymized network response durations and app launch latency to monitor server availability and optimize app speed.
3. **Usage Metrics (Firebase Analytics):** Screen view counts, button tap events, and aggregated feature usage. You can disable analytics data collection at any time under **Account → Settings → Diagnostics & Analytics**.
4. **Push Notification Tokens (Firebase Cloud Messaging):** A pseudonymous device registration token used solely to dispatch scheduled bill payment reminders and critical security alerts.

---

## 3. Financial SMS Processing (Android Policy Disclosure)

Credvert includes an optional on-device financial tracking module designed to help users track credit card expenses, verify bill statement totals, monitor fee-waiver milestones, and detect unusual charges.

### 3.1 Strict Compliance with Google Play SMS Policy
Credvert requests Android `READ_SMS` and `RECEIVE_SMS` permissions under the **Financial Services / SMS-based Money Management** exception. We adhere to the following strict operating principles:

- **Prominent In-App Disclosure:** Before requesting any runtime SMS permission from the operating system, Credvert displays a dedicated full-screen disclosure explaining exactly what is read, what stays on the device, and how the data is used.
- **Affirmative User Consent:** SMS tracking is strictly opt-in. The runtime permission request is only triggered after the user taps "I Agree, Allow SMS Access". Users can decline or skip this feature without losing access to card comparisons, rewards calculators, or the manual wallet.
- **Read-Only Operation:** Credvert never requests `SEND_SMS`, `WRITE_SMS`, or phone call permissions. Credvert cannot and will never send SMS messages from your device.
- **Bank Sender Whitelisting:** Our native bridge inspects SMS headers and strictly processes only messages originating from verified, pre-registered financial institution sender IDs (e.g., `HDFCBK`, `ICICIT`, `SBICRD`, `AXISBK`, `AMEXIN`, `KOTAKB`, etc.).
- **Zero Access to Personal Chats & OTPs:** Non-banking messages, personal conversations, verification codes, and one-time passwords (OTPs) are ignored at the system level and are never read, parsed, or stored.
- **100% On-Device Parsing:** All regex pattern matching and transaction extraction occurs entirely in device memory. The raw text of the SMS message is discarded immediately after parsing and **never leaves the physical device**.
- **Complete Revocation & Data Erasure:** Users can pause tracking, toggle sync, or permanently erase all parsed transaction records at any time from **Spend Insights → Tracking & Privacy → Delete all spend data**.

---

## 4. How We Use Your Information

We use the collected information exclusively for the following operational purposes:
- **Card Rewards & Lounge Recommendation:** Calculating estimated reward point yields, cashback percentages, and lounge access availability across different spending categories.
- **Spend Insights & Budgeting:** Aggregating monthly spending trends, merchant distributions, recurring subscription detection, and card milestone progress.
- **Bill Due Reminders:** Sending timely local or push notifications prior to credit card payment due dates and statement generation dates.
- **Security & Account Integrity:** Authenticating user sessions, enforcing rate limits, blocking fraudulent abuse, and safeguarding account access.
- **Service Maintenance:** Debugging software issues, optimizing network latency, and maintaining high platform reliability.

**We do NOT use your information for:**
- Serving targeted or behavioural third-party advertisements.
- Credit scoring, profiling for loan underwriting, or sharing with financial lenders.
- Sale or brokerage to any external commercial entity.

---

## 5. Sharing and Disclosure of Information

We do not sell, rent, trade, or share your personal information with third parties for their direct marketing purposes. Information is only shared under the following limited circumstances:

1. **Authorized Service Providers (Sub-Processors):**
   - **Google Cloud / Firebase (USA / Global):** Firebase Authentication, Cloud Messaging (FCM), Crashlytics, and Performance Monitoring.
   - **Database & Backend Infrastructure (Neon / Supabase / AWS):** Fully encrypted cloud databases and API hosting operating under strict Data Processing Agreements (DPAs) with TLS 1.3 in-transit encryption and AES-256 rest encryption.
2. **Legal and Regulatory Compliance:**
   - We may disclose information if required to do so by applicable law, court order, regulatory authority, or lawful subpoena, provided such disclosure is strictly necessary and legally enforceable.
3. **Business Transfers:**
   - If Credvert is involved in a merger, acquisition, reorganization, or sale of assets, your account data may be transferred as part of that transaction, subject to the acquiring party agreeing to honor this Privacy Policy.

---

## 6. Security Architecture & Zero-Knowledge Vault

Credvert applies multi-layered enterprise-grade security protocols:

- **End-to-End Encryption in Transit:** All client-server communication is enforced over HTTPS utilizing Transport Layer Security (TLS 1.3) with Certificate Pinning safeguards.
- **Hardware Enclave Encryption at Rest:** Card PAN, CVVs, and expiry dates are encrypted using AES-256-GCM cryptographic keys generated and stored inside the Android KeyStore or iOS Secure Enclave. The encryption keys never leave the hardware module and cannot be exported.
- **Mandatory Biometric Gate:** Decrypting, viewing, or copying sensitive card data requires biometric verification (fingerprint or facial recognition).
- **Clipboard Auto-Clearing:** When a card number is copied to the clipboard for checkout convenience, Credvert flags the clipboard payload as sensitive content (supported on Android 13+) and executes a background job to wipe the clipboard after 30 seconds.
- **Screenshot & App-Switcher Protection:** Credvert enables `FLAG_SECURE` on Android and applies a privacy blur cover on iOS when the application transitions into the background or multi-tasking app switcher.

---

## 7. Data Retention and Erasure

- **Account Data:** Synced account information and card metadata are retained as long as your account remains active.
- **Spend & Transaction History:** Maintained to generate historical monthly trends. You may delete individual transactions or purge your entire spend history at any time.
- **Guest Mode Data:** Stored exclusively in local application storage. Uninstalling the app or tapping **Account → Reset this device** immediately destroys all local data.
- **Account Deletion:** When you request account deletion (via in-app **Account → Delete Account** or via our web portal at `https://credvert.app/deletion`), your user record, synced cards, transaction history, and push tokens are permanently purged from live databases within 24 hours. Archived database backups are overwritten and expunged within 30 to 90 days in accordance with automated backup rotation cycles.

---

## 8. Your Legal Rights

Depending on your geographical jurisdiction, you possess specific statutory rights regarding your personal data:

### 8.1 Rights Under the India DPDP Act, 2023
- **Right to Access Information:** Request a summary of personal data processed by Credvert.
- **Right to Correction and Erasure:** Correct inaccurate personal data or request complete erasure of your account.
- **Right to Grievance Redressal:** Lodge inquiries or complaints with our designated Grievance Officer.
- **Right to Nominate:** Nominate an individual to exercise your rights in the event of death or incapacity.

### 8.2 Rights Under GDPR / UK GDPR
- **Right to Access, Rectification, and Erasure ("Right to be Forgotten").**
- **Right to Restriction of Processing & Right to Data Portability.**
- **Right to Object to Processing** and right to withdraw consent at any time.
- **Right to Lodge a Complaint** with your local European Data Protection Authority (DPA).

### 8.3 Rights Under California Law (CCPA / CPRA)
- **Right to Know & Access** the categories of personal information collected.
- **Right to Delete** personal information.
- **Right to Non-Discrimination** for exercising consumer privacy rights.
- **Notice of No Sale:** Credvert does not "sell" or "share" personal information as defined under the CCPA/CPRA.

---

## 9. Protection of Children

Credvert is intended solely for adult consumers who are eligible to hold credit cards. We do not knowingly market to, solicit, or collect personal information from individuals under the age of 18 (or the age of majority in your jurisdiction). If we discover that an account has been created by a minor, we will promptly delete all associated information.

---

## 10. Changes to This Privacy Policy

We may update this Privacy Policy periodically to reflect enhancements to our features, changes in legal requirements, or adjustments to our operational practices. When material updates are made, we will notify you through an in-app notice, push notification, or email update prior to the changes taking effect. The date of the most recent revision will always be displayed at the top of this document.

---

## 11. Contact Us & Grievance Redressal

If you have questions, feedback, data subject requests, or security inquiries regarding this Privacy Policy, please contact us:

- **Developer:** Jay Chauhan
- **Support & Privacy Email:** `support@credvert.app` / `privacy@credvert.app`
- **Designated Grievance Officer (India DPDP Act):**
  - **Officer Name:** Jay Chauhan (Grievance Redressal Officer)
  - **Email:** `grievance@credvert.app`
  - **Response Turnaround:** All privacy grievances are acknowledged within 24 hours and resolved within 30 calendar days.
- **Official Web Portal:** `https://credvert.app`
- **Data Deletion Portal:** `https://credvert.app/deletion`
