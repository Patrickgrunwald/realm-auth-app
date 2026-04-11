# 01 — System-Architektur

## High-Level Architektur

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter App                          │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │   Auth   │ │   Feed   │ │  Camera  │ │  Profile │  │
│  │  Screen  │ │   Screen │ │  Screen  │ │  Screen  │  │
│  └────┬─────┘ └────┬─────┘ └────┬─────┘ └────┬─────┘  │
│       └────────────┴────────────┴────────────┘         │
│                          │                              │
│              ┌───────────┴───────────┐                   │
│              │   Supabase Client     │                   │
│              │  (Flutter SDK)       │                   │
│              └───────────┬───────────┘                   │
└──────────────────────────┼───────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────────┐
│  Supabase     │  │  Supabase     │  │  Supabase Edge    │
│  PostgreSQL   │  │  Storage      │  │  Functions        │
│  (Database)   │  │  (Medien)     │  │  (Serverless)     │
└───────────────┘  └───────────────┘  └───────────────────┘
```

## Frontend (Flutter)

### Schichten

```
┌─────────────────────────────────────┐
│         UI Layer (Screens)          │  ← Widgets, Screens
├─────────────────────────────────────┤
│       Controller/Notifier Layer     │  ← Riverpod Notifiers
├─────────────────────────────────────┤
│        Repository Layer             │  ← Datenbank-Zugriffe
├─────────────────────────────────────┤
│         Service Layer               │  ← Supabase, Camera, TTS
└─────────────────────────────────────┘
```

### Datenfluss

```
User Aktion
    ↓
Flutter Widget (Screen)
    ↓
Riverpod Notifier (.notifier)
    ↓
Repository (post_repository.dart)
    ↓
Supabase Client (supabase_flutter)
    ↓
Supabase PostgreSQL / Storage
```

## Backend (Supabase)

### Komponenten

| Komponente | Nutzung | Wo |
|---|---|---|
| PostgreSQL | Datenbank: Users, Posts, Likes, Comments, Follows, Reports | Cloud |
| Auth | E-Mail-Login, Registrierung, Session-Management | Cloud |
| Storage | Fotos + Videos (Medien-Dateien) | Cloud |
| Realtime | Live-Feed-Updates, Notifications | Cloud |
| Edge Functions | EA-Melde-Logik, Auto-Löschung, Cron | Edge (Deno) |
| RLS | Zugriffskontrolle auf Zeilen-Ebene | Datenbank |

### Datenbank-Zugriff (Flutter)

```dart
// Initialisierung (einmal pro App)
await Supabase.initialize(
  url: 'SUPABASE_URL',
  anonKey: 'SUPABASE_ANON_KEY',
);

// Singleton-Zugriff
final supabase = Supabase.instance.client;

// Normale Queries
await supabase.from('posts').select('*, users(*)').order('created_at');

// Realtime Subscription
supabase.channel('public:posts').onPostgresChanges(
  event: INSERT,
  schema: 'public',
  table: 'posts',
  callback: (payload) => ...,
).subscribe();
```

## Medien-Speicherung (Storage)

### Bucket-Struktur

```
realm-auth-app-bucket/
├── avatars/          ← Profilbilder
│   └── {user_id}/
│       └── avatar.jpg
├── posts/            ← Post-Medien
│   └── {post_id}/
│       ├── media.jpg       (oder .mp4)
│       └── thumbnail.jpg  (nur Video)
└── temp/             ← Temporär (vor Kompression)
```

### Upload-Flow

```
1. Kamera nimmt Foto/Video auf
2. EXIF-Daten werden entfernt
3. Kompression (Foto < 500KB / Video < 5MB)
4. Upload zu Supabase Storage
5. Storage-URL in posts-Tabelle speichern
6. Temp-Dateien löschen
```

## Edge Functions (Serverless)

### EA-Moderation (Trigger: bei jedem ea_report INSERT)

```typescript
// supabase/functions/ea-moderation/index.ts
// GETRIGGERED: wenn ea_report_count >= 5
// → setzt report_status = 'pending'
// → Benachrichtigung an Admin-User
```

### Auto-Delete (Trigger: Cron, stündlich)

```typescript
// supabase/functions/ea-auto-delete/index.ts
// GETRIGGERED: stündlich
// → sucht Posts mit:
//   - is_ai_confirmed = true
//   - created_at < now() - 24 hours
//   - deleted_at = null
// → setzt deleted_at = now() (soft delete)
```

## Auth-Flow

```
┌──────────┐    Register/Login    ┌──────────────┐
│  Client  │ ──────────────────→ │ Supabase Auth │
│ (Flutter)│ ←── Access Token ── │   (JWT)       │
└────┬─────┘                     └───────────────┘
     │
     │ Access Token (im Header)
     ↓
┌────────────────────┐
│  Supabase Backend  │
│  (RLS Policies)    │
│  Erlaubt Zugriff   │ ← "Meine Posts" oder "Alle Posts"
│  nur wenn Token    │
│  gültig + erlaubt  │
└────────────────────┘
```

## Nächste Docs

← [00 OVERVIEW](00_OVERVIEW.md)
→ [02 DATABASE](02_DATABASE.md) — DB-Schema, Tabellen, RLS
