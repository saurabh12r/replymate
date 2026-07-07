# ReplyMate

An automated SMS auto-reply platform for businesses that never want to miss a customer. When a call is missed or a store is busy, **ReplyMate** instantly sends a personalised text back — and the whole operation is managed, metered, and monetised through a web-based admin & broker console.

This repository is a monorepo containing three parts:

| Directory | What it is | Stack |
|-----------|------------|-------|
| [`ReplyMate/`](ReplyMate/) | Customer-facing mobile app | Flutter (Android) + native Kotlin |
| [`admin_broker/`](admin_broker/) | Admin & broker management console | Flutter Web (Riverpod, go_router) |
| [`admin_broker/functions/`](admin_broker/functions/) | Serverless backend | Firebase Cloud Functions (Node.js) |

All three share a single Firebase project (Auth, Cloud Firestore, Cloud Messaging).

---

## ReplyMate — Mobile App

A Flutter Android app that runs a background auto-reply engine so a business never leaves a caller unanswered.

### Highlights

- **Automatic SMS replies** to missed calls, driven by a native Kotlin `AutoReplyEngine` and a persistent `AutoReplyForegroundService` that keeps working when the app is closed.
- **Scheduled messages** — queue SMS/MMS to be delivered later via exact-alarm receivers.
- **Store / contact configuration** — per-store reply templates and contact-filter allow/deny lists.
- **Activity log & analytics** — every reply, call, and delivery is logged locally (Hive) with charts (`fl_chart`), CSV export, and shareable reports.
- **Subscription-gated** — auto-reply activation is tied to an approved, non-expired subscription synced from Firestore.
- **OTP login**, push notifications (FCM), and boot-persistent service startup.

### Tech

Flutter 3.9+, GetX state management, Firebase (Auth · Firestore · Functions · Messaging), Hive local storage, and native Android receivers/services in Kotlin (`SEND_SMS`, `READ_CALL_LOG`, `READ_PHONE_STATE`, foreground service, exact alarms).

### Run it

```bash
cd ReplyMate
flutter pub get
flutter run           # on a connected Android device / emulator
```

> Requires a `google-services.json` in `android/app/` and a generated `lib/firebase_options.dart` for the Firebase project.

---

## admin_broker — Admin & Broker Console

A production-ready Flutter **Web** console with two role-based shells:

- **Admin** — dashboard, users, brokers, pending approvals, expired users, subscription plans, revenue, campaigns, notifications, and audit logs.
- **Broker** — scoped dashboard, analytics, user management, and approval queue for the users a broker owns.

Built with **Riverpod** for state, **go_router** for navigation, and `fl_chart` for reporting.

### Run it locally (mirrors Netlify SPA routing)

```bash
cd admin_broker
flutter pub get
flutter build web --release
node serve.js          # serves build/web at http://localhost:8080
```

For live development you can also just `flutter run -d chrome`.

---

## Backend — Firebase Cloud Functions

Located in [`admin_broker/functions/`](admin_broker/functions/) (region `asia-south1`). Key functions:

- `autoExpireSubscriptions` — daily scheduled job that disables auto-reply for lapsed subscriptions.
- `sendExpiryWarnings` — proactive push reminders before a plan expires.
- `onUserApproved` / `onApprovalCreated` / `onBrokerUserRegistered` — Firestore triggers that drive the approval workflow and notifications.
- `createBroker`, `sendCampaignNotification`, `sendOtp`, `verifyOtp` — callable functions for provisioning brokers, broadcast campaigns, and OTP auth.

### Deploy

```bash
cd admin_broker/functions
npm install
firebase deploy --only functions
```

---

## Architecture at a glance

```
                +---------------------------+
                |     Firebase project       |
                |  Auth · Firestore · FCM    |
                +-------------+--------------+
                              |
        +---------------------+----------------------+
        |                     |                      |
+-------v-------+   +---------v---------+   +--------v---------+
|  ReplyMate    |   |   admin_broker    |   | Cloud Functions  |
|  (Android)    |   |   (Flutter Web)   |   |    (Node.js)     |
|  auto-reply   |   | admin + broker    |   | schedules,       |
|  engine       |   | management        |   | triggers, OTP    |
+---------------+   +-------------------+   +------------------+
```

## Requirements

- Flutter SDK 3.9+ (admin_broker uses 3.11+)
- A configured Firebase project with Auth, Firestore, and Cloud Messaging enabled
- Node.js (for Cloud Functions and the local web server)

## License

Proprietary — all rights reserved.
