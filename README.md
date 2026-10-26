# RoamBite 🚚🌮

**RoamBite** is a modern, production-grade Flutter application for real-time mobile food truck discovery, live proximity tracking, verified customer reviews, and vendor shift management.

Designed around a segregated dual-shell architecture:
- **Foodie Experience**: Instant discovery of active food trucks near you, live radar scanning, dynamic menu exploration, and anti-spam location-verified reviews.
- **Truck Owner Experience**: One-tap shift activation, automatic 2-minute live location pings, 15-minute inactivity auto-expiry, instant menu editor with version bumping, and foot-traffic analytics.

---

## 📱 Architecture & Key Features

### 1. Dual Shell Model (Foodie vs Truck Owner)
- **Role-Based Routing**: Strict separation between food lovers and truck vendors. Truck owners access operational dashboards and analytics; foodies discover and review.
- **Home Dashboard First**: Cold starts land directly on the rich Home discovery dashboard with "Serving Right Now" live carousels, hub pickers, and quick radar access.
- **Modern Theme System**: Defaults to a clean, high-contrast Material 3 **Light Theme** with instant toggle and persistent dark mode saved to device preferences.

### 2. Live Proximity & PostGIS Radar
- **Live Location Broadcasting**: Active food trucks stream GPS coordinates every 2 minutes while on shift.
- **15-Minute Auto-Expiry**: Trucks that drop offline or stop broadcasting automatically disappear from the live radar after 15 minutes to guarantee freshness.
- **Server-Side PostGIS Geofencing**: Distance calculations and spatial queries use PostGIS `geography(Point, 4326)` with GIST indexing.

### 3. Anti-Fraud Verified Visit Reviews
- Customer reviews are validated server-side using the `check_is_verified_visit` RPC function.
- A review receives the **"Verified Visit"** badge only if the user's location was recorded within **200 meters** of the truck's verified live location within a **±2 hour** window of the shift.

### 4. Push & Area Notification Safeguards
- **Quiet Hours**: Respects user sleep windows (10:00 PM – 8:00 AM local time).
- **Idempotent Deduplication**: Prevents spamming subscribers using unique daily hash keys: `hash(user_id, truck_id, area_id, date)`.

---

## 🛠️ Tech Stack

- **Frontend**: Flutter 3.x (Dart 3)
- **State Management**: `Provider` (MultiProvider with `ThemeProvider` & `AuthProvider`)
- **Backend & Auth**: Supabase (PostgreSQL 15 + PostGIS extension, Row Level Security, RPCs)
- **Auth Providers**: Phone SMS OTP and Google OAuth via Supabase Auth
- **Persistence**: `shared_preferences` for offline caching and theme persistence
- **CI/CD**: GitHub Actions for automated linting, widget testing, and release APK packaging

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.27+ recommended)
- [Supabase CLI](https://supabase.com/docs/guides/cli) or a Supabase Cloud project
- Android Studio / Xcode for device emulation

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/sahaysnehil22/RoamBite.git
cd RoamBite
flutter pub get
```

### 2. Database Migrations & Seeds
1. In your Supabase project (or local instance via `supabase start`):
2. Apply the schema migration:
   - Navigate to `supabase/migrations/00001_initial_schema.sql`
   - Run the script in the Supabase SQL Editor.
3. Seed sample data (Miami & Austin demo food trucks, menus, and locations):
   - Run `supabase/seed.sql` in the Supabase SQL Editor.

### 3. Run the App
RoamBite reads configuration via Dart compile-time environment variables (`--dart-define`).

#### Running in Production Mode with Supabase:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key \
  --dart-define=SENTRY_DSN=https://your-sentry-dsn@sentry.io/project
```

#### Running in Preview Mode:
If launched without `--dart-define`, RoamBite runs in **Preview / Offline Mode**, allowing you to evaluate the UI, explore demo shells, test theme switches, and inspect truck menus without requiring an active backend connection.

---

## 🤖 Android Release Signing

The project is pre-configured with a secure release signing configuration in `android/app/build.gradle.kts`.

### Keystore Configuration
1. Generate an upload keystore (if you don't already have one):
   ```bash
   keytool -genkey -v -keystore roambite-release.jks -keyalg RSA \
     -keysize 2048 -validity 10000 -alias roambite_release_key
   ```
2. Copy the template:
   ```bash
   cp android/key.properties.example android/key.properties
   ```
3. Fill in your details in `android/key.properties`:
   ```properties
   storePassword=your_keystore_password
   keyPassword=your_key_password
   keyAlias=roambite_release_key
   storeFile=/absolute/path/to/roambite-release.jks
   ```
> [!NOTE]
> If `key.properties` or environment variables are not provided, Gradle automatically and safely falls back to debug signing keys so release builds always succeed during development. `key.properties` and `*.jks` are explicitly ignored in `.gitignore`.

### Building Release APK
```bash
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://your-project-id.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```
The output APK is generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🧪 Testing & Code Quality

Run static analysis:
```bash
flutter analyze
```

Run test suite:
```bash
flutter test
```

---

## 📂 Project Structure

```
RoamBite/
├── .github/
│   └── workflows/
│       └── build-apk.yml        # CI/CD pipeline for analyze, test, and release APK build
├── android/
│   ├── app/build.gradle.kts     # Release signing configuration with debug fallback
│   └── key.properties.example   # Keystore template
├── assets/
│   └── images/                  # RoamBite official logos and icons
├── lib/
│   ├── main.dart                # Application entrypoint & role-based gatekeeper
│   ├── providers/
│   │   ├── auth_provider.dart   # Auth, session, and role state management
│   │   └── theme_provider.dart  # ThemeMode state (Light default, Dark persisted)
│   ├── screens/
│   │   ├── auth_screen.dart           # Authentication & quick role selector
│   │   ├── explore_screen.dart        # Search, filter, and city hub explorer
│   │   ├── home_dashboard_screen.dart # Cold-start foodie landing page
│   │   ├── menu_editor_screen.dart    # Truck owner menu item & version manager
│   │   ├── owner_dashboard_screen.dart# Shift ops, 2-min GPS ping, 15-min auto expiry
│   │   ├── radar_discovery_screen.dart# Interactive radar proximity scanner
│   │   ├── settings_screen.dart       # User preferences, quiet hours, radius
│   │   ├── truck_detail_screen.dart   # Menu viewer & verified review writer
│   │   └── visitor_stats_screen.dart  # Real-time analytics & verified foot-traffic
│   ├── services/
│   │   └── supabase_service.dart      # Supabase client, queries, caching, GPS broadcast
│   ├── shells/
│   │   ├── foodie_shell.dart          # Customer navigation shell
│   │   └── truck_owner_shell.dart     # Vendor partner navigation shell
│   ├── theme/
│   │   └── app_theme.dart             # Material 3 Light & Dark themes
│   └── widgets/
│       ├── location_picker_sheet.dart # Active hub selector
│       └── radar_painter.dart         # Custom Canvas radar sweep rendering
├── supabase/
│   ├── migrations/
│   │   └── 00001_initial_schema.sql  # PostGIS tables, RLS, spatial indexes, RPCs
│   └── seed.sql                       # 4 demo food trucks with menus & coordinates
└── pubspec.yaml                       # Dependencies, assets & version 1.1.0+2
```

---

## 📄 License
This project is proprietary software developed for RoamBite. All rights reserved.
