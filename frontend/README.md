# GotNews (Frontend)

Aplikasi Flutter untuk GotNews — TikTok-style news reader dengan infinite scroll, AI summarization, dan notifikasi real-time.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter (SDK >=3.2.0) |
| **State Management** | Provider |
| **Storage** | flutter_secure_storage |
| **Networking** | http |
| **UI** | Material Design, google_fonts, shimmer, cached_network_image |

## Getting Started

### Prasyarat

- Flutter SDK (>=3.2.0)
- Android device (USB debugging) atau emulator, atau iOS simulator

### Install

```bash
cd frontend
flutter pub get
```

### Run

```bash
# Android real device via USB
adb reverse tcp:3000 tcp:3000
flutter run

# Android emulator (10.0.2.2 otomatis)
flutter run

# iOS simulator
flutter run
```

## Struktur

```
lib/
├── main.dart                       # App entry point
├── models/
│   ├── user.dart                   # User model
│   └── news_item.dart              # Article model
├── services/
│   ├── api_client.dart             # HTTP client + JWT auth headers
│   ├── auth_service.dart           # Auth state, login, register, token refresh
│   ├── news_service.dart           # Feed, search, likes, bookmarks
│   └── admin_service.dart          # Admin API calls
├── screens/
│   ├── login_screen.dart
│   ├── signup_screen.dart
│   ├── main_layout.dart            # Bottom navigation shell
│   ├── feed_screen.dart            # TikTok-style infinite scroll
│   ├── explore_screen.dart         # Search + category filter
│   ├── bookmark_screen.dart        # Saved articles
│   ├── news_detail_screen.dart     # Article detail + AI summary
│   ├── profile_screen.dart
│   ├── edit_profile_screen.dart
│   └── admin_dashboard_screen.dart
└── widgets/
    └── news_list_tile.dart
```

## Catatan

Base URL backend otomatis menyesuaikan platform:

| Platform | Base URL |
|----------|---------|
| Android | `http://10.0.2.2:3000` |
| iOS / Web | `http://localhost:3000` |

Untuk device Android fisik, jalankan `adb reverse tcp:3000 tcp:3000` agar bisa akses backend lokal.
