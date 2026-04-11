# 13 — Projekt-Setup

## Voraussetzungen

### macOS / macOS
- Flutter SDK 3.x (via `brew install flutter`)
- Xcode 15+ (für iOS-Build)
- Android Studio (für Android-Build)
- Android SDK (via Android Studio)

### Linux
- Flutter SDK
- Android SDK

## 1. Flutter Projekt erstellen

```bash
cd ~/workspace/realm-auth-app

# Projekt erstellen
flutter create \
  --org com.realmauth \
  --project-name realm_auth_app \
  --platforms ios,android \
  flutter

cd flutter
```

## 2. Abhängigkeiten installieren

```bash
# pubspec.yaml bearbeiten (siehe 04_FRONTEND_STRUCTURE.md)
flutter pub add supabase_flutter
flutter pub add flutter_riverpod
flutter pub add go_router
flutter pub add camera
flutter pub add video_player
flutter pub add chewie
flutter pub add flutter_image_compress
flutter pub add ffmpeg_kit_flutter_full_gpl
flutter pub add flutter_secure_storage
flutter pub add path_provider
flutter pub add cached_network_image
flutter pub add shimmer
flutter pub add timeago
flutter pub add uuid
flutter pub add intl
flutter pub add image_picker
```

## 3. Supabase Projekt anlegen

1. **Supabase Dashboard öffnen:** https://app.supabase.com
2. **Neues Projekt erstellen:**
   - Name: `realm-auth-app`
   - Region: Frankfurt (Europe)
   - Password: sicheres Passwort notieren!
3. ** Projekt-URL und anon/ service-role Keys kopieren:**
   - Settings → API
   - `SUPABASE_URL` und `SUPABASE_ANON_KEY` notieren
   - `SUPABASE_SERVICE_ROLE_KEY` (für Edge Functions) — NIEMALS in Flutter-App!

## 4. Supabase Datenbank einrichten

### SQL Migration ausführen

In Supabase Dashboard → SQL Editor → neue Query:

```sql
-- Aus docs/02_DATABASE.md alle CREATE TABLE + CREATE POLICY Statements
-- Hier komplett ausführen
```

Oder per CLI:

```bash
supabase db push
```

## 5. Storage Bucket erstellen

Im Supabase Dashboard → Storage:

1. Neuer Bucket: `realm-auth-app`
2. Public Bucket: **JA** (für Medien-URLs)
3. Ordner-Struktur erstellen:
   - `avatars/`
   - `posts/`
   - `temp/`

### Storage Policies

```sql
-- Jeder kann Avatare lesen
CREATE POLICY "Avatare öffentlich lesen"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'avatars');

-- Eingeloggte User können Avatare hochladen
CREATE POLICY "User können eigene Avatare hochladen"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'avatars');

-- Jeder kann Posts-Medien lesen
CREATE POLICY "Posts-Medien öffentlich lesen"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'posts');

-- Eingeloggte User können Posts-Medien hochladen
CREATE POLICY "User können Posts hochladen"
  ON storage.objects FOR INSERT
  WITH CHECK (bucket_id = 'posts');
```

## 6. .env-Datei erstellen

```bash
cd ~/workspace/realm-auth-app/flutter
touch .env
```

```env
# .env
SUPABASE_URL=https://your-project-id.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...xxx
```

## 7. lib/main.dart Grundstruktur

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app.dart';
import 'core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://your-project.supabase.co',
    anonKey: 'your-anon-key',
  );

  runApp(
    ProviderScope(
      child: RealmAuthApp(),
    ),
  );
}
```

## 8. iOS Setup (macOS)

### Minimum iOS Version
`ios/Podfile` → `platform :ios, '13.0'`

### Info.plist — Kamera + Mikrofon Permissions

```xml
<key>NSCameraUsageDescription</key>
<string>Realm Auth braucht die Kamera um Fotos und Videos aufzunehmen.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Realm Auth braucht das Mikrofon für Video-Ton.</string>
<key>NSPhotoLibraryUsageDescription</key>
<!-- BEWUSST WEGGELASSEN — kein Galerie-Upload! -->
```

### Bundle Identifier
`com.realmauth.realm_auth_app`

## 9. Android Setup

### AndroidManifest.xml

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
<!-- KEIN READ_EXTERNAL_STORAGE — kein Galerie-Upload! -->
```

### build.gradle (app)
```groovy
minSdkVersion 21
targetSdkVersion 34
```

## 10. Apple Developer Account (für echte Devices)

1. Apple Developer Account (€99/Jahr) — https://developer.apple.com
2. Team ID notieren
3. Xcode: Sign In with Apple ID → Team auswählen
4. Bundle Identifier: `com.realmauth.realm_auth_app`
5. Capabilities: Push Notifications (für später)

## 11. Entwicklung starten

```bash
cd ~/workspace/realm-auth-app/flutter

# iOS Simulator
flutter run -d "iPhone 15 Pro"

# Android Emulator
flutter run -d emulator-5554

# Verbundenes Android Device
flutter devices   # Device-ID finden
flutter run -d <device-id>
```

## 12. Ordnerstruktur verifizieren

```
realm-auth-app/
├── README.md
├── SPEC.md
├── docs/
│   ├── 00_OVERVIEW.md
│   ├── 01_ARCHITECTURE.md
│   ├── 02_DATABASE.md
│   ├── 03_API.md
│   ├── 04_FRONTEND_STRUCTURE.md
│   ├── 05_AUTH_FLOW.md
│   ├── 06_FEED.md
│   ├── 07_CAMERA.md
│   ├── 08_POSTS.md
│   ├── 09_PROFILE.md
│   ├── 10_EA_MODERATION.md
│   ├── 11_NAVIGATION.md
│   ├── 12_DESIGN.md
│   ├── 13_SETUP.md
│   └── 14_DEPLOYMENT.md
└── flutter/
    ├── pubspec.yaml
    ├── lib/
    └── ...
```

---

## Nächste Docs

← [12 DESIGN](12_DESIGN.md)
→ [14 DEPLOYMENT](14_DEPLOYMENT.md)
