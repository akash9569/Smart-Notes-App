<div align="center">

# 🌟 Smart Notes & LifeOS

### *The Ultimate All-in-One Intelligent Productivity & Life Management Suite*

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20macOS%20%7C%20Web%20%7C%20Windows%20%7C%20Linux-brightgreen?style=for-the-badge)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-purple?style=for-the-badge)](LICENSE)
[![Theme](https://img.shields.io/badge/Theme-Dark%20%26%20Light%20Adaptive-coral?style=for-the-badge)](#-theme--design-system)

<p align="center">
  <b>Smart Notes & LifeOS</b> is a modern, high-performance, offline-first personal operating system built with Flutter. It seamlessly unites <b>Rich Document Editing</b>, <b>Task & Project Management</b>, <b>Habit Building & Streak Tracking</b>, <b>Finance & Loan Bookkeeping</b>, <b>Guided Journaling</b>, <b>Interactive Sticky Boards</b>, and <b>Smart Calendar Scheduling</b> into a single cohesive, beautifully crafted interface.
</p>

---

</div>

## 📑 Table of Contents

- [✨ Key Highlights & Overview](#-key-highlights--overview)
- [📱 Module Deep-Dive & Features](#-module-deep-dive--features)
  - [1. 📊 Executive Dashboard & Daily Pulse](#1--executive-dashboard--daily-pulse)
  - [2. 📝 Notes & Document Studio](#2--notes--document-studio)
  - [3. ✅ Task & Project Management](#3--task--project-management)
  - [4. 🔥 Habit Tracker & Streak Engine](#4--habit-tracker--streak-engine)
  - [5. 💰 Expense, Cashflow & Loan Manager](#5--expense-cashflow--loan-manager)
  - [6. 📖 Guided Journal & Daily Reflection](#6--guided-journal--daily-reflection)
  - [7. 📌 Pastel Sticky Notes Board](#7--pastel-sticky-notes-board)
  - [8. 📅 Smart Integrated Calendar](#8--smart-integrated-calendar)
  - [9. 👤 User Profile, Multi-Account & Biometric Security](#9--user-profile-multi-account--biometric-security)
  - [10. 🔔 Smart Multi-Stage Background Notifications](#10--smart-multi-stage-background-notifications)
- [🎨 Theme & Design System](#-theme--design-system)
- [🛠️ Technology Stack & Architecture](#️-technology-stack--architecture)
- [📂 Project Directory Structure](#-project-directory-structure)
- [🚀 Getting Started & Installation](#-getting-started--installation)
  - [Prerequisites](#prerequisites)
  - [Installation Steps](#installation-steps)
  - [Platform Specific Configurations](#platform-specific-configurations)
- [🔐 Privacy & Data Storage](#-privacy--data-storage)
- [🤝 Contributing & Support](#-contributing--support)
- [📄 License](#-license)

---

## ✨ Key Highlights & Overview

- 🔒 **100% Offline-First & Private**: All data is encrypted and stored locally on the user's device using high-speed persistent storage without unwanted cloud telemetry.
- 🎨 **Adaptive Responsive Design**: Tailored experiences for mobile phones, tablets, foldables, and desktop/web screens with collapsible multi-tier sidebar navigation.
- 🌙 **Bespoke Light & Dark Theme**: Custom modern palette with high-contrast legibility, soft pastel tones, glassmorphism containers, and smooth micro-interactions.
- ⏰ **Background Alarm & Notification System**: Multi-stage alarms that ring at exact times even when the device is locked or the application is killed.
- 🖨️ **Professional PDF Export & Printing**: Instant document rendering with custom page layouts, headers, and printable sheets.
- 🧬 **Biometric Authentication**: Seamless hardware-backed security using Fingerprint, Touch ID, and Face ID.
- 👥 **Instant Multi-Account Switcher**: Switch between work, personal, and study accounts instantly on the same device.

---

## 📱 Module Deep-Dive & Features

### 1. 📊 Executive Dashboard & Daily Pulse
*Your morning command center for clarity, focus, and momentum.*

- **Daily Pulse Metrics**: Real-time summary displaying current financial balance, monthly spending, pending tasks count, completed tasks count, and habits completed today.
- **7-Day Dynamic Calendar Strip**: Horizontal date strip highlighting today, active weekday indicators, and immediate tap-to-inspect dates.
- **Today's & Upcoming Agenda Timeline**: Sorted chronological list of tasks with priority tags, countdown badges, and one-tap status toggles.
- **Recent Notes & Quick Thought Previews**: Instant access to your latest thoughts, formatted notes, and drafts directly from the home screen.
- **Quick Action Speed-Dial**: One-tap shortcuts to create a New Note, Log an Expense, Start a Task, or Write a Journal Entry.

---

### 2. 📝 Notes & Document Studio
*A full-featured rich text editing powerhouse designed for thinkers and writers.*

- **Per-Character Rich Styling**: Real-time Bold, Italic, Underline, Strikethrough, Custom Font Sizes, Text Colors, and Highlight Colors without markdown clutter.
- **Dynamic Block Types**:
  - 📄 Standard Formatted Paragraphs
  - ☑️ Interactive Checklists with toggleable completion
  - 🔹 Bulleted Lists with automatic indentation
  - 📊 Editable Tables with dynamic row/column addition, cell editing, and responsive scrolling
- **Typography & Font Control**: Switch between multiple font families (*Roboto, Serif, Monospace*), line spacing, and text alignment (*Left, Center, Right, Justify*).
- **Export & Share Studio**:
  - 🖨️ Direct High-Definition PDF Generation & System Printing via `printing` & `pdf`
  - 📤 Universal System Share via `share_plus`
  - 📋 One-tap Raw Text & Formatted Copy
- **Color Coding & Pinning**: Pin crucial notes to the top and color-code cards for instant visual retrieval.

---

### 3. ✅ Task & Project Management
*Conquer your daily goals with structured hierarchies and deadline reminders.*

- **Subtasks Hierarchy**: Break down massive projects into manageable, checkable sub-action items with real-time completion progress bars.
- **Flexible Recurrence Engine**:
  - `Once` • `Daily` • `Weekly` • `Monthly`
  - `Custom Weekdays` (e.g., Every *Mon, Wed, Fri*)
- **Priority Matrix**: Color-coded urgency levels: `Urgent 🔴`, `High 🟠`, `Medium 🟡`, `Low 🔵`.
- **Categorization**: Organize by `Work`, `Personal`, `Fitness`, `Study`, `Project`, and custom tags.
- **Streak & Velocity Tracking**: Automatically computes completion streaks and records last-completed milestones.
- **Advanced Task Reminder Engine**: Configurable pre-alerts at:
  - 📅 5 Days Before
  - ⏰ 24 Hours Before (1 Day)
  - ⏳ 5 Hours Before
  - 🔔 1 Hour Before
  - ⚡ 30 Minutes Before
  - ⏱️ 10 Minutes Before
  - 🚨 Exact Due Time

---

### 4. 🔥 Habit Tracker & Streak Engine
*Build unbreakable positive habits with time-tested psychological feedback loops.*

- **Custom Target Goals**: Track 21-Day sprints, 30-Day transformations, 60-Day milestones, or continuous lifelong routines.
- **Session Duration Customizer**: Allocate dedicated session blocks (e.g., 15m, 30m, 45m, 60m).
- **Streak Analytics**: Live calculation of **Current Streak**, **Longest Streak**, total completions, and goal completion percentages.
- **Monthly Heatmap & Consistency Grid**: Visual calendar representation showing every single day you stayed consistent.
- **4-Stage Background Habit Notifications**:
  1. ⏰ **5 Min Before Start**: Preparation ping (*"Get ready! [Habit] starts in 5 minutes."*)
  2. 🔥 **At Start Time**: Session launch alert (*"It's time for [Habit]! Spend X minutes and keep your streak alive."*)
  3. ⏳ **5 Min Before Completion**: Focus countdown (*"Almost done! 5 minutes remaining. Finish strong!"*)
  4. 🎉 **At Session Completion**: Victory prompt (*"Session complete! Don't forget to mark it done!"*)

---

### 5. 💰 Expense, Cashflow & Loan Manager
*Master your personal finances, track cashflow, and manage debts seamlessly.*

- **Dual-Ledger Architecture**:
  - 💳 **Cashflow Ledger**: Track both `Income` and `Expense` transactions across categories (*Food, Salary, Bills, Shopping, Travel, Health, Entertainment, Investments*).
  - 🤝 **Loan & Debt Book**: Separate ledger for `Lend (Money Given)` and `Borrow (Money Taken)`.
- **Debt & Loan Tracking**:
  - Counterparty / Person name tracking
  - Principal amount vs. Remaining Outstanding balance
  - Partial repayments & settlement tracking with due date alerts
  - Complete vs. Active loan status
- **Financial Analytics & Cashflow Pulse**:
  - Total Available Balance
  - Monthly Inflows vs. Outflows
  - Net Savings Ratio & Category Distribution Charts
- **History & Filtering**: Filter transactions by type, date range, or category with instant running balance updates.

---

### 6. 📖 Guided Journal & Daily Reflection
*Nurture mental clarity, mindfulness, and gratitude with structured journaling.*

- **Pre-Built Journaling Templates**:
  - ☀️ **Morning Reflection**: Set daily intentions, gratitude lists, and top priorities.
  - 🌙 **Evening Review**: Wins, learnings, what could have gone better, and peaceful unwind.
  - 🔄 **Weekly Reset**: Weekly retrospective, habit audit, and goal alignments.
  - 🙏 **Gratitude Journal**: Deep-dive into things and people you are thankful for.
  - 🎯 **Goal & Habit Check-in**: Strategic alignment with quarterly and annual targets.
  - ✍️ **Freeform Note**: Open canvas for unstructured creative thought.
- **Emoji Mood Logging**: Track your emotional wellbeing across entries (*😊 Happy, 🚀 Energized, 🧘 Calm, 😐 Neutral, 😔 Down, 😴 Tired*).
- **Journal Calendar & Timeline**: Browse entries chronologically with search, mood filters, and date selectors.

---

### 7. 📌 Pastel Sticky Notes Board
*Rapid capture, brainstorms, and quick memos with intelligent text formatting.*

- **Authentic Pastel Palette**: Amber Post-It, Soft Coral, Mint Green, Sky Blue, Lavender, Rose Pink, Ocean Teal, and Lemon Lime.
- **Smart Auto-List Text Formatter**:
  - Pressing `Enter` in a **Numbered List** (`1. `) automatically inserts `2. `, `3. `, etc.
  - Pressing `Enter` in a **Bullet List** (`• `) automatically inserts the next bullet.
  - Double-tapping `Enter` cleanly terminates the list without manual backspacing.
- **Multi-Format Support**: Switch note format between `Free Text`, `Interactive Checklist`, `Bullet List`, and `Numbered List`.
- **Pins & Organization**: Pin favorite notes, organize by tags (*Work, Personal, Urgent, Idea, Shopping*), and search cards in real-time.

---

### 8. 📅 Smart Integrated Calendar
*Unified time view synchronizing tasks, deadlines, and milestones.*

- **Monthly & Daily Interactive Views**: Smooth month-to-month transitions with highlighted current day.
- **Priority Dot Indicators**: Calendar day cells display colored dots corresponding to task priorities due on that date.
- **Split-View Agenda Pane**: Select any day on the calendar to instantly view, complete, or add tasks for that exact date.
- **Quick Event Creation**: Schedule new tasks and deadlines straight from the calendar interface.

---

### 9. 👤 User Profile, Multi-Account & Biometric Security
*Tailored personalization, security, and multi-user management.*

- **Local Profile Management**: Name, Email, Phone Number, Date of Birth, Gender, Job Title, Address, Bio, and custom Avatar Photo.
- **Local Photo Storage**: Uses `image_picker` and stores avatars securely inside the local application sandbox directory.
- **Multi-Account Switching**: Register multiple user profiles on a single device and switch between them with a single tap.
- **Biometric Security Engine**: Lock the application behind Fingerprint, Face ID, or Device PIN using `local_auth`.
- **System Preferences**:
  - 🌓 Dark / Light Theme Mode toggle with live propagation
  - ⏱️ 12-Hour / 24-Hour Time Format toggle
  - 🔔 Alarm & Notification Permission Manager

---

### 10. 🔔 Smart Multi-Stage Background Notifications
*Never miss a task deadline or habit session even when the app is completely closed.*

- Built on top of `flutter_local_notifications`, `timezone`, and `flutter_timezone`.
- Uses Android `AlarmManager` with `exactAllowWhileIdle` and `POST_NOTIFICATIONS` support.
- Fully resilient against device reboots with `RECEIVE_BOOT_COMPLETED` listeners.

---

## 🎨 Theme & Design System

The application features a bespoke **Fluid Surface Design System** crafted from the ground up:

```
┌─────────────────────────────────────────────────────────────┐
│                       COLOR PALETTE                         │
├──────────────────────────────┬──────────────────────────────┤
│ DARK THEME                   │ LIGHT THEME                  │
│ • Background:    #0B0E14     │ • Background:    #F3F4F6     │
│ • Sidebar:       #12141C     │ • Sidebar:       #FFFFFF     │
│ • Card Surface:  #141417     │ • Card Surface:  #FFFFFF     │
│ • Elevated Card: #1E212B     │ • Elevated Card: #F9FAFB     │
│ • Text Primary:  #FFFFFF     │ • Text Primary:  #111827     │
│ • Text Secondary:#A0A5B1     │ • Text Secondary:#4B5563     │
├──────────────────────────────┴──────────────────────────────┤
│ ACCENT HIGHLIGHTS                                           │
│ • Primary Blue:  #2D62FF  • Royal Purple: #9D59FF          │
│ • Coral Rose:    #F08A82  • Mint Emerald: #10B981          │
│ • Warning Amber: #F59E0B  • Error Crimson:#F43F5E          │
└─────────────────────────────────────────────────────────────┘
```

---

## 🛠️ Technology Stack & Architecture

| Layer | Technology / Package | Purpose |
| :--- | :--- | :--- |
| **Framework** | [Flutter 3.x](https://flutter.dev) / [Dart 3.x](https://dart.dev) | Cross-platform high-performance UI toolkit |
| **State & Navigation** | `StatefulWidget`, `ValueNotifier`, `InheritedTheme` | Fast, reactive state management without overhead |
| **Local Storage** | [`shared_preferences`](https://pub.dev/packages/shared_preferences) | JSON-serialized persistent storage |
| **File Sandbox** | [`path_provider`](https://pub.dev/packages/path_provider), [`path`](https://pub.dev/packages/path) | Local documents & image asset sandbox |
| **Hardware Biometrics** | [`local_auth`](https://pub.dev/packages/local_auth) | Fingerprint, Touch ID & Face ID authentication |
| **Notifications & Alarms** | [`flutter_local_notifications`](https://pub.dev/packages/flutter_local_notifications), [`timezone`](https://pub.dev/packages/timezone), [`flutter_timezone`](https://pub.dev/packages/flutter_timezone) | Background exact alarms and recurring notifications |
| **PDF & Printing** | [`pdf`](https://pub.dev/packages/pdf), [`printing`](https://pub.dev/packages/printing) | Document layout generation and printing |
| **Media & Share** | [`image_picker`](https://pub.dev/packages/image_picker), [`share_plus`](https://pub.dev/packages/share_plus) | Camera/Gallery picker & system sharing sheet |
| **Formatting** | [`intl`](https://pub.dev/packages/intl) | Internationalized dates, times, and currency |

---

## 📂 Project Directory Structure

```
lifeos/
├── android/                   # Android native configuration & manifests
│   └── app/src/main/
│       └── AndroidManifest.xml # Permissions (Exact Alarms, Boot, Notifications, Biometrics)
├── ios/                       # iOS native project, Info.plist & capabilities
├── macos/                     # macOS desktop platform wrapper
├── web/                       # Web build files & manifests
├── lib/
│   ├── main.dart              # App entry point, routing, auth wrapper, master state
│   ├── app_theme.dart         # Design tokens, color system, dark/light themes, decorations
│   ├── screens/
│   │   ├── welcome_screen.dart # Interactive first-launch animated onboarding
│   │   └── login_screen.dart   # Sign In, Sign Up, Biometrics, Password Reset
│   ├── services/
│   │   └── notification_service.dart # Notification channels, exact alarms, habit reminders
│   └── widgets/
│       ├── app_logo.dart           # Vector app branding component
│       ├── dashboard.dart          # Executive dashboard, pulse metrics, timeline agenda
│       ├── notes_manager.dart      # Rich text document editor, tables, lists, PDF export
│       ├── task_manager.dart       # Tasks, subtasks, priorities, recurrence, reminders
│       ├── habit_tracker_view.dart # Habits, streak engine, heatmaps, session timers
│       ├── expense_manager.dart    # Income/Expense cashflow, loan/debt book, balances
│       ├── journal_view.dart       # Guided reflection templates, mood tracker, entries
│       ├── sticky_notes_view.dart  # Pastel sticky notes board with auto-formatting
│       ├── calendar_view.dart      # Month calendar, priority dot indicators, day agenda
│       ├── profile_view.dart       # Profile details, photo picker, security, theme toggles
│       └── sidebar.dart            # Multi-tier sidebar navigation & account switcher
├── pubspec.yaml               # Project dependencies & assets
└── README.md                  # Comprehensive project documentation
```

---

## 🚀 Getting Started & Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>= 3.11.0`)
- [Dart SDK](https://dart.dev/get-dart) (`>= 3.0.0`)
- Android Studio / Xcode / VS Code with Flutter extension
- An active Android/iOS emulator or physical development device

### Installation Steps

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/smart-notes-lifeos.git
   cd smart-notes-lifeos
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run code analysis (optional)**:
   ```bash
   flutter analyze
   ```

4. **Launch the application**:
   ```bash
   # Run on connected device or emulator
   flutter run

   # Or run with release mode for optimal performance
   flutter run --release
   ```

---

### Platform Specific Configurations

#### 🤖 Android
Ensure the following permissions are declared in `android/app/src/main/AndroidManifest.xml`:
- `android.permission.POST_NOTIFICATIONS` (Android 13+)
- `android.permission.SCHEDULE_EXACT_ALARM` & `android.permission.USE_EXACT_ALARM` (Android 12+)
- `android.permission.RECEIVE_BOOT_COMPLETED` (Notification restoration after reboot)
- `android.permission.USE_BIOMETRIC` (Biometric authentication)
- `android.permission.USE_FULL_SCREEN_INTENT` & `android.permission.WAKE_LOCK`

#### 🍏 iOS / macOS
Ensure the following entries exist in `ios/Runner/Info.plist`:
- `NSFaceIDUsageDescription`: *"Smart Notes uses Face ID to securely authenticate your account."*
- `NSPhotoLibraryUsageDescription`: *"Smart Notes requires photo access to set your profile picture."*
- `NSCameraUsageDescription`: *"Smart Notes requires camera access to take a profile photo."*

---

## 🔐 Privacy & Data Storage

- **Zero Cloud Dependence**: Your notes, journal entries, tasks, financial records, and habits are stored locally on your device in JSON format.
- **Hardware-Isolated Storage**: Application sandboxing prevents external apps from accessing your profile pictures and document files.
- **Biometric Security**: Biometric validation happens exclusively on-device via secure hardware enclaves (Touch ID, Secure Enclave, Android BiometricPrompt API).

---

## 🤝 Contributing & Support

Contributions, feature suggestions, and bug reports are warmly welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">
  <b>Built with ❤️ and Flutter</b><br>
  <i>Empowering personal productivity, mindful living, and financial clarity.</i>
</div>
