# 🔒 Privacy Policy

Last updated: August 16, 2026

**Kharcha** is built with an uncompromising commitment to privacy and data ownership. We believe your financial, academic, and health data belongs to you and no one else.

---

## 1. 100% On-Device Local Storage
* **No Remote Databases**: All expenses, budgets, schedules, workouts, and personal profile information are stored exclusively on your device using Apple's local **SwiftData** framework.
* **No Cloud Lock-In**: Kharcha does not require an account, email address, password, or third-party login.
* **No Telemetry or Tracking**: There are zero third-party analytics SDKs, advertising trackers, tracking pixels, or diagnostic telemetry integrated into the app.

---

## 2. Device Permissions & Usage

Kharcha requests only the permissions necessary to provide native iOS features:

| Permission | Purpose | Data Handling |
|---|---|---|
| **Apple Health (HealthKit)** | Read step count, active calories, exercise time, walking distance, and sleep analysis for the Fitness dashboard. | Read-only. Health data is never transmitted anywhere outside your device. |
| **Camera** | Allows taking photos of physical receipts and paper bills to attach to an expense. | Captured images remain strictly on your local device storage. |
| **Photo Library** | Allows selecting existing receipt images from your photo gallery. | Read-only access to selected photos. |
| **Location (When In Use)** | Allows tagging expenses with the latitude, longitude, and locality name where the purchase occurred. | Location is fetched only at the exact moment an expense is logged and is never tracked in the background. |

---

## 3. Data Portability & Backup
* You can export a complete, unencrypted JSON backup (`KharchaBackup.json`) or CSV report of your data at any time from **Settings ➔ Data & Backup**.
* You can import this backup file to restore your data on any compatible iOS device.

---

## 4. Open Source Transparency
Kharcha is open-source software licensed under the MIT License. The complete source code is publicly inspectable on [GitHub](https://github.com/D0pExD/Kharcha-APP).

---

## 5. Contact
For questions regarding this policy or the application, please open an issue on the [Kharcha GitHub Repository](https://github.com/D0pExD/Kharcha-APP/issues).
