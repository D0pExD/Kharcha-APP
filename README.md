# 💸 Kharcha (खर्चा)

> **A modern, privacy-first iOS companion for student expense tracking, Apple Health fitness, college scheduling, and interactive widgets.**

[![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue.svg?style=flat&logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg?style=flat&logo=swift)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-purple.svg?style=flat&logo=swift)](https://developer.apple.com/xcode/swiftui/)
[![SwiftData](https://img.shields.io/badge/Storage-SwiftData-green.svg?style=flat)](https://developer.apple.com/documentation/swiftdata)
[![Privacy](https://img.shields.io/badge/Privacy-100%25%20On--Device-success.svg)](PRIVACY.md)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

---

## 📱 App Preview

<p align="center">
  <img src="docs/screenshots/widgets.jpg" width="85%" alt="Kharcha Live Dashboard & Widgets" />
</p>

### 📸 In-App Experience

| 📊 Home & Analytics | ⚡ Quick Add Expense | 🏃‍♂️ Apple Health Fitness | 📜 History & Geotags |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/dashboard.png" width="100%" alt="Home Dashboard" /> | <img src="docs/screenshots/quickadd.png" width="100%" alt="Quick Add" /> | <img src="docs/screenshots/fitness.png" width="100%" alt="Fitness & Health" /> | <img src="docs/screenshots/history.png" width="100%" alt="History" /> |

---

## 🌟 Overview

**Kharcha** is designed specifically for college students and young professionals to manage daily finances, stay on top of health goals, and organize academic routines in one unified, sleek native iOS experience.

Built 100% in **SwiftUI** and **SwiftData**, Kharcha operates completely offline with zero tracking, cloud lock-in, or external telemetry.

---

## ✨ Features

### 💸 1. Expense & Budget Tracking
- **Instant Logging**: Log expenses with payment mode (*UPI, Cash, Card*), category, note, bill photo, and geotag.
- **Smart Budgets**: Set monthly budgets with dynamic progress bars and alert warnings (*"Sabr kar bhai, budget khatam hone wala hai!"*).
- **Audit Logs & History**: View detailed breakdown by date, payment mode, and localized categories.
- **Photo Receipts**: Snap bills or select receipts from camera/photos to keep proof of purchase.

### ⚡ 2. Apple Shortcuts & Siri Integration (AppIntents)
- **2-Second Back Tap Logging**: Log expenses without opening the app via iOS Back Tap (Double/Triple tap on iPhone back).
- **Interactive Prompts**: Sequential prompt flow for *Amount ➔ Category Picker ➔ Note ➔ Optional Receipt Photo*.
- **Dynamic Categories**: Automatically queries user's custom and default categories directly from SwiftData.

### 📱 3. Interactive Home Screen & Lock Screen Widgets
- **Spend & Budget Widget**: Displays today's spend and remaining monthly budget at a glance (*Small, Medium, Lock Screen*).
- **Fitness & Steps Widget**: Live step count and interactive **"+ Add Glass"** one-tap water logger on Home Screen.
- **Instant Sync**: Main App and Widget Extension communicate seamlessly via App Groups (`group.com.kharchabsdk.app`).

### 🏃‍♂️ 4. Apple Health Integration (HealthKit)
- **Activity Rings & Step Tracker**: Visual step progress ring and 7-day weekly trend bar chart.
- **Comprehensive Metrics**:
  - 🔥 Active Energy Burned (`kcal`)
  - 🚶‍♂️ Walking & Running Distance (`km`)
  - ⏱️ Apple Exercise Time (`mins`)
  - ❤️ Resting Heart Rate (`BPM`)
  - 😴 Sleep Duration Analysis (`hrs`)
  - 🪜 Flights Climbed (Floors)
- **Hydration Tracker**: Daily 8-glass water goal with instant tap-to-log.
- **Workout Logger**: Log exercises (*Push-ups, Running, Cycling, Swimming, Yoga*) with reps/distance/time.

### 📍 5. Real GPS Location Tagging
- **CoreLocation Geotagging**: Automatically tags every expense with precise latitude, longitude, and locality name.
- **Map View**: Review expense locations on Apple Maps.

### 📚 6. College Timetable & Academic Planner
- **Class Schedule**: Day-by-day timetable planner with subject, time, classroom, and professor details.
- **Assignment & Exam Tracker**: Due dates, status tags (*Pending, In Progress, Submitted*), and reminders.

### 🇮🇳 7. Multilingual Hinglish & Localized UI
- Switch effortlessly between **Hinglish**, **English**, and **Hindi**.
- Authentic desi contextual messages and financial wisdom throughout the app.

### 🔒 8. 100% Offline, Private & Portable Backup
- **Local Storage**: All data stays on-device in SwiftData.
- **Single-File Backup**: Export full database to `KharchaBackup.json` and restore anytime across devices.

---

## 🛠️ Tech Stack & Architecture

| Layer | Technology |
|---|---|
| **Language** | Swift 5.9+ / Swift 6 Ready |
| **User Interface** | SwiftUI (iOS 17+ Modern Design System) |
| **Data Persistence** | SwiftData (`@Model`, `@Query`, Schema Migrations) |
| **Shortcuts & Siri** | AppIntents (`AppIntent`, `AppEntity`, `EntityQuery`) |
| **Widgets** | WidgetKit & App Groups |
| **Health & Fitness** | HealthKit (`HKHealthStore`, `HKStatisticsQuery`) |
| **Location & Maps** | CoreLocation & MapKit |
| **Unit Testing** | XCTest (`BudgetTests`, `PhoneValidatorTests`, `BackupManagerTests`) |
| **Project Spec** | XcodeGen (`project.yml`) |

---

## 🚀 Getting Started

### Prerequisites
- macOS Sonoma 14.0 or later
- Xcode 15.0 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (for generating Xcode project)

```bash
# Install XcodeGen via Homebrew (if not already installed)
brew install xcodegen
```

### Installation & Build

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/D0pExD/Kharcha-APP.git
   cd Kharcha-APP
   ```

2. **Generate the Xcode Project**:
   ```bash
   xcodegen generate
   ```

3. **Open and Run in Xcode**:
   ```bash
   open Kharcha.xcodeproj
   ```
   - Select your connected iPhone or Simulator.
   - Press **`⌘ + R`** to build and run!
   - Press **`⌘ + U`** to run the unit test suite.

---

## 📲 Setting Up iOS Back Tap (Shortcuts)

1. Open Apple's **Shortcuts App** on your iPhone.
2. Create a new shortcut named **`Log Kharcha`**.
3. Add the **`Log Kharcha`** action from the Kharcha app.
4. *(Optional Photo Prompt)*:
   - Add **`Choose from Menu`** with prompt: *"Add Receipt Photo?"*
   - Under **Yes**: Add **`Take 1 Photo with Camera`** followed by **`Attach Receipt Photo`**.
5. Go to **Settings ➔ Accessibility ➔ Touch ➔ Back Tap**.
6. Select **Double Tap** or **Triple Tap** and assign **`Log Kharcha`**.
7. Tap the back of your iPhone anytime to log expenses in seconds! ⚡

---

## 🔒 Privacy & Security

Kharcha collects **zero** data. See our full [Privacy Policy](PRIVACY.md) for details on device permissions and local-first architecture.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 Author

**Ram**  
*Built with ❤️ for students and builders.*
