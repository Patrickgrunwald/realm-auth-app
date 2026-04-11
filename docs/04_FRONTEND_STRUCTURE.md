# 04 — Frontend-Struktur (Flutter)

## Flutter-Projekt anlegen

```bash
cd ~/workspace/realm-auth-app
flutter create --org com.realmauth --project-name realm_auth_app flutter
cd flutter
flutter pub add supabase_flutter
flutter pub add riverpod
flutter pub add go_router
flutter pub add camera
flutter pub add video_player
flutter pub add chewie
flutter pub add flutter_image_compress
flutter pub add ffmpeg_kit_flutter
flutter pub add flutter_secure_storage
flutter pub add cached_network_image
flutter pub add timeago
flutter pub add shimmer
flutter pub add image_picker  # NUR für Avatar-Camera, NICHT Galerie!
```

## pubspec.yaml (dependencies)

```yaml
name: realm_auth_app
description: Social Media App — Realm Auth
publish_to: 'none'

dependencies:
  flutter:
    sdk: flutter

  # Supabase
  supabase_flutter: ^2.3.0

  # State Management
  flutter_riverpod: ^2.4.0
  riverpod_annotation: ^2.3.0

  # Navigation
  go_router: ^13.0.0

  # Camera & Media
  camera: ^0.10.5
  video_player: ^2.8.0
  chewie: ^1.7.0
  flutter_image_compress: ^2.1.0
  ffmpeg_kit_flutter: ^6.0.0

  # Storage & Auth
  flutter_secure_storage: ^9.0.0
  path_provider: ^2.1.0
  path: ^1.8.0

  # UI
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  timeago: ^3.6.0
  uuid: ^4.2.0
  intl: ^0.19.0

  cupertino_icons: ^1.0.6

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  build_runner: ^2.4.0
  riverpod_generator: ^2.3.0

flutter:
  uses-material-design: true
```

## lib/-Struktur

```
lib/
├── main.dart                    ← App-Entry, ProviderScope, Router
├── app.dart                     ← MaterialApp + Theme
│
├── core/
│   ├── theme/
│   │   ├── app_theme.dart       ← Farben, Typography, ThemeData
│   │   └── app_colors.dart      ← Farben-Konstanten
│   ├── constants/
│   │   ├── app_constants.dart   ← App-Name, Limits, etc.
│   │   └── storage_constants.dart
│   ├── router/
│   │   └── app_router.dart      ← GoRouter-Konfiguration
│   └── utils/
│       ├── compression.dart     ← Bild+Video Kompression
│       ├── exif_stripper.dart  ← EXIF entfernen
│       ├── validators.dart      ← Username, Email Validierung
│       └── date_formatter.dart  ← Zeit-Darstellung
│
├── data/
│   ├── models/
│   │   ├── user_model.dart
│   │   ├── post_model.dart
│   │   ├── comment_model.dart
│   │   ├── notification_model.dart
│   │   └── ea_report_model.dart
│   ├── repositories/
│   │   ├── auth_repository.dart
│   │   ├── post_repository.dart
│   │   ├── user_repository.dart
│   │   ├── comment_repository.dart
│   │   ├── follow_repository.dart
│   │   ├── notification_repository.dart
│   │   └── ea_repository.dart
│   └── services/
│       ├── supabase_service.dart   ← Client-Init
│       ├── storage_service.dart    ← Media-Upload/Download
│       ├── camera_service.dart     ← Kamera-Initialisierung
│       └── notification_service.dart
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   └── controllers/
│   │       └── auth_controller.dart    ← Riverpod Notifier
│   │
│   ├── feed/
│   │   ├── screens/
│   │   │   ├── feed_screen.dart       ← FYP / Following Tabs
│   │   │   └── post_detail_screen.dart
│   │   ├── widgets/
│   │   │   ├── post_card.dart         ← Für Foto-Posts
│   │   │   ├── video_post_card.dart   ← Für Video-Posts
│   │   │   ├── feed_tab_bar.dart
│   │   │   └── interaction_bar.dart   ← Like/Comment/Share Buttons
│   │   └── controllers/
│   │       └── feed_controller.dart
│   │
│   ├── camera/
│   │   ├── screens/
│   │   │   ├── camera_screen.dart     ← Vollbild-Kamera
│   │   │   ├── photo_review_screen.dart
│   │   │   └── video_review_screen.dart
│   │   ├── widgets/
│   │   │   ├── camera_controls.dart  ← Auslöser, Switch, Flash
│   │   │   └── mode_toggle.dart       ← Foto/Video Wechsler
│   │   └── controllers/
│   │       └── camera_controller.dart
│   │
│   ├── post/
│   │   ├── screens/
│   │   │   ├── create_post_screen.dart  ← Caption + EA-Toggle
│   │   │   └── comments_sheet.dart      ← Bottom Sheet
│   │   ├── widgets/
│   │   │   ├── ea_toggle.dart           ← ⚠️ EA MARK BUTTON (prominent!)
│   │   │   ├── caption_input.dart
│   │   │   └── media_preview.dart
│   │   └── controllers/
│   │       └── post_controller.dart
│   │
│   ├── profile/
│   │   ├── screens/
│   │   │   ├── profile_screen.dart     ← Eigenes Profil
│   │   │   ├── user_profile_screen.dart ← Andere User
│   │   │   ├── edit_profile_screen.dart
│   │   │   └── followers_screen.dart
│   │   ├── widgets/
│   │   │   ├── profile_header.dart
│   │   │   ├── stats_row.dart
│   │   │   ├── posts_grid.dart
│   │   │   └── follow_button.dart
│   │   └── controllers/
│   │       └── profile_controller.dart
│   │
│   ├── notifications/
│   │   ├── screens/
│   │   │   └── notifications_screen.dart
│   │   └── controllers/
│   │       └── notifications_controller.dart
│   │
│   ├── search/
│   │   ├── screens/
│   │   │   └── search_screen.dart
│   │   └── controllers/
│   │       └── search_controller.dart
│   │
│   └── ea_moderation/
│       ├── screens/
│       │   └── ea_report_sheet.dart    ← bottomsheet zum Melden
│       └── controllers/
│           └── ea_controller.dart
│
└── widgets/
    ├── ea_badge.dart              ← 🧠 Badge auf EA-Posts
    ├── blur_overlay.dart          ← Unscharf auf bestätigten EA-Posts
    ├── loading_shimmer.dart
    ├── avatar_widget.dart
    ├── empty_state.dart
    ├── error_widget.dart
    └── user_tile.dart
```

## State Management (Riverpod)

### Architektur

```dart
// providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Auth
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>

// Feed
final feedPostsProvider = FutureProvider<List<Post>>((ref) async { ... })
final feedTabProvider = StateProvider<FeedTab>((ref) => FeedTab.fyp)

// Camera
final cameraControllerProvider = StateNotifierProvider<CameraController, CameraState>

// Profile
final profileProvider = FutureProvider.family<User?, String>((ref, userId))

// Notifications
final notificationsProvider = StreamProvider<List<Notification>>

// EA
final eaReportsProvider = ...
```

### AuthController

```dart
class AuthController extends StateNotifier<AuthState> {
  final SupabaseClient _supabase;

  Future<void> signUp(String email, String password, String username) async { ... }
  Future<void> signIn(String email, String password) async { ... }
  Future<void> signOut() async { ... }
  Future<void> updateProfile(...) async { ... }
  User? get currentUser => _supabase.auth.currentUser;
}

enum AuthState { initial, loading, authenticated, error }
```

## Nächste Docs

← [03 API](03_API.md)
→ [05 AUTH_FLOW](05_AUTH_FLOW.md)
