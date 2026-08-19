# 🚌 SafeRoute — Enterprise Multi-Tenant School Bus Safety & Real-Time Tracking Platform

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Supabase](https://img.shields.io/badge/Backend-Supabase-3ECF8E?logo=supabase)](https://supabase.com)
[![OpenStreetMap](https://img.shields.io/badge/Maps-OpenStreetMap-7EBC6F?logo=openstreetmap)](https://www.openstreetmap.org)
[![Vercel](https://img.shields.io/badge/Deploy-Vercel-000000?logo=vercel)](https://saferoute-admin-self.vercel.app)
[![Android](https://img.shields.io/badge/OS-Android%209%20to%2015+-3DDC84?logo=android)](https://developer.android.com)

**SafeRoute** is an end-to-end, multi-tenant school bus tracking and safety management platform built with Flutter, Riverpod, Supabase PostgreSQL, and OpenStreetMap. It empowers Parents, Drivers, and Fleet Administrators with live GPS location tracking, proximity alerts, multi-channel notifications (Push, WhatsApp, SMS), and automated safety management.

---

## 🌐 Live Production Admin Console

👉 **[https://saferoute-admin-self.vercel.app](https://saferoute-admin-self.vercel.app)**

---

## 🌟 Key Features & Capabilities

### 📱 Mobile App (Parent & Driver Roles)
- **Live Geofenced Tracking**: Real-time bus location streamed via Supabase WebSockets over OpenStreetMap (no Google Maps API dependency).
- **Proximity & Arrival Alerts**: Automated 500m geofence detection triggering instant arrival notices.
- **Universal Android Notification Support (Android 9 – 15+)**:
  - **Heads-Up Floating Banners**: High-priority floating screen popups with sound & vibration whether device is unlocked or locked.
  - **In-App Center Alert Modals**: High-visibility dialog cards popping up directly in the app UI upon notification arrival.
  - **Mandatory System Settings Handler**: Detects disabled notification permissions across standard Android and custom ROMs (Xiaomi/MIUI) and provides a 1-tap shortcut to App Settings.
- **Smart Notification Management**:
  - Dynamic unread badge counter that automatically hides when `unreadCount == 0`.
  - Inbox **Mark All as Read**, individual deletion, and **Delete All / Clear Inbox** features.
- **Driver Roll Call & HUD**: Active trip management, student boarding/drop-off status, and route navigation.

### 🏢 Super Admin & Fleet Web Dashboard
- **Multi-Tenant Administration**: Enterprise organization (school) onboarding and role-based permissions (Super Admin, Fleet Admin, Driver, Parent).
- **Realtime DB Usage Stats**:
  - Live table metrics: Total Organizations, User Profiles, Students, School Buses, Notification Events, and Deliveries.
  - Database health status, PostgreSQL 15 connection metrics, and Row-Level Security (RLS) enforcement verification.
- **Notification Audit & Dispatch Center**:
  - Send custom emergency alerts or announcements to specific parents or school-wide broadcasts.
  - **Delete Notification History**: Permanent audit log cleanup for administrative compliance.

---

## 🏗️ Repository Architecture (Monorepo)

```
saferoute/
├── apps/
│   ├── saferoute_app/        # Flutter Mobile App (Android & iOS — Parent & Driver)
│   └── saferoute_admin/      # Flutter Web Admin Dashboard (Vercel Deployed)
└── packages/
    └── saferoute_core/       # Shared Domain Models, Supabase Services, & Utilities
```

---

## 🔑 Demo Credentials (QA Sandbox)

| Persona | Email | Password | Role / Access Level |
| :--- | :--- | :--- | :--- |
| **Fleet Admin** | `admin@dps.edu` | `Password123!` | School fleet management, route dispatch, audit logs |
| **Parent** | `parent@dps.edu` | `Password123!` | Real-time student tracking, arrival alerts |
| **Driver** | `driver@dps.edu` | `Password123!` | Active route trip HUD & student roll call |

---

## 🚀 Getting Started & Local Development

### Prerequisites
- **Flutter SDK**: `>=3.0.0 <4.0.0`
- **Dart SDK**: `>=3.0.0`
- **Android SDK**: API level 28+ (Android 9+)

### Installation & Run

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/Shivam-Ranpise/saferoute.git
   cd saferoute
   ```

2. **Install Core Dependencies**:
   ```bash
   cd packages/saferoute_core
   flutter pub get
   ```

3. **Run the Mobile App (Android/iOS)**:
   ```bash
   cd ../../apps/saferoute_app
   flutter pub get
   flutter run -d <your-device-id>
   ```

4. **Run the Admin Dashboard (Web)**:
   ```bash
   cd ../../apps/saferoute_admin
   flutter pub get
   flutter run -d chrome
   ```

---

## 🛡️ Security & Privacy

- **Row-Level Security (RLS)**: Enforced in PostgreSQL database to ensure strict data isolation between school tenants and parent accounts.
- **Secure Storage**: Sensitive auth tokens stored using OS-level encrypted storage (`flutter_secure_storage`).

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for details.
