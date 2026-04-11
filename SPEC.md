# Realm Auth App — Spezifikation

## 1. Überblick

**Name:** Realm Auth (Arbeitstitel — ggf. catchy rebranding)
**Plattform:** iOS + Android (Flutter, eine Codebasis)
**Core-Konzept:** Social-Media-App à la TikTok für Foto + Video — NUR Aufnahme, keine Galerie-Uploads. KI-generierte Inhalte werden durch die Community als "EA Content" markiert und bei genügend Meldungen geprüft + gelöscht.

---

## 2. Tech Stack

### Frontend
- **Framework:** Flutter 3.x (Dart)
- **State Management:** Riverpod oder Bloc
- **Camera:** camera package (Flutter) — Live-Vorschau, Foto + Video aufnehmen
- **Video Player:** video_player + chewie
- **Kompression:** ffmpeg_kit_flutter (Videos komprimieren nach Aufnahme)
- **Bild-Kompression:** flutter_image_compress

### Backend / Database
- **Option A: Supabase** (PostgreSQL + Auth + Storage + Realtime + Edge Functions)
  - Pros: out-of-the-box Auth, Storage, Realtime, RLS-Policies, kostenloser Plan reicht für Start
  - Cons: Abhängigkeit von Supabase-Cloud
- **Option B: Firebase** (Firestore + Auth + Storage + Cloud Functions)
  - Pros: sehr ausgereift, gute Flutter-Integration
  - Cons: Firestore ist nicht ideal für Social-Feed (eher für Chat/Dokumente)
- **Option C: Eigenes Backend** (Node.js/Go + PostgreSQL + S3)
  - Pros: volle Kontrolle
  - Cons: mehr Aufwand

**Empfehlung: Supabase** — schnellste Time-to-Market, eine DB für beide Apps, Auth+Storage+Realtime included.

### Community Moderation Backend
- Supabase Edge Functions für EA-Melde-Logik + automatisierte Löschung

---

## 3. Datenmodell (Supabase/PostgreSQL)

### users
| Feld | Typ | Beschreibung |
|---|---|---|
| id | uuid | Primary Key (= auth.users.id) |
| username | text | Unique, öffentlicher Handle |
| email | text | Unique |
| display_name | text | Anzeigename |
| avatar_url | text | URL zu Profilbild |
| bio | text | Bio-Text |
| followers_count | integer | DEFAULT 0 |
| following_count | integer | DEFAULT 0 |
| posts_count | integer | DEFAULT 0 |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### posts
| Feld | Typ | Beschreibung |
|---|---|---|
| id | uuid | Primary Key |
| user_id | uuid | FK → users |
| type | enum('photo','video') | Medientyp |
| media_url | text | URL zum komprimierten Medium |
| thumbnail_url | text | Thumbnail (Video) |
| caption | text | Beschreibungstext |
| is_ea_content | boolean | DEFAULT false (manuell markiert) |
| is_ai_confirmed | boolean | DEFAULT false (nach Prüfung bestätigt) |
| ea_report_count | integer | DEFAULT 0 |
| likes_count | integer | DEFAULT 0 |
| comments_count | integer | DEFAULT 0 |
| shares_count | integer | DEFAULT 0 |
| report_status | enum('none','pending','confirmed','rejected') | DEFAULT 'none' |
| created_at | timestamptz | |
| updated_at | timestamptz | |

### likes
| Feld | Typ | |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users |
| post_id | uuid | FK → posts |
| created_at | timestamptz | |
| UNIQUE(user_id, post_id) | | |

### comments
| Feld | Typ | |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users |
| post_id | uuid | FK → posts |
| content | text | Kommentartext |
| created_at | timestamptz | |

### follows
| Feld | Typ | |
|---|---|---|
| follower_id | uuid | FK → users |
| following_id | uuid | FK → users |
| created_at | timestamptz | |
| PK: (follower_id, following_id) | | |

### ea_reports
| Feld | Typ | |
|---|---|---|
| id | uuid | PK |
| post_id | uuid | FK → posts |
| reporter_id | uuid | FK → users |
| reason | text | Begründung |
| created_at | timestamptz | |
| UNIQUE(post_id, reporter_id) | | Ein User kann nur einmal pro Post melden |

### notifications
| Feld | Typ | |
|---|---|---|
| id | uuid | PK |
| user_id | uuid | FK → users (Empfänger) |
| type | text | 'like','comment','follow','ea_resolved' |
| actor_id | uuid | FK → users (Auslöser) |
| post_id | uuid | FK → posts (optional) |
| read | boolean | DEFAULT false |
| created_at | timestamptz | |

---

## 4. Feed-Logik

### For-You-Page (FYP)
- Algorithmen-basiert: Gewichtung nach likes, shares, comments, views
- Supabase: `posts` mit Join auf `users`, Sortierung nach Score
- Score = `(likes*3 + comments*5 + shares*10) / hours_age`

### Following-Feed
- Nur Posts von Usern denen man folgt
- Chronologisch absteigend

---

## 5. EA-Content Moderation (Kernfeature)

### Flow:
1. **User markiert Post als EA** → `ea_reports` Eintrag + `ea_report_count++`
2. **Wenn `ea_report_count >= 5` UND `report_status == 'none'`**
   → Supabase Edge Function triggered
   → `report_status = 'pending'`, `is_ea_content = true`
3. **Admin-Bereich** (Web-Dashboard oder In-App für Mods):
   → Post prüfen → `is_ai_confirmed` setzen
4. **Bestätigung:** `is_ai_confirmed == true` → Post wird soft-deleted (blurred + Badge)
5. **Auto-Löschung:** Nach 24h ohne Admin-Einspruch → Post wird komplett gelöscht
6. **Ablehnung:** `report_status = 'rejected'`, `ea_report_count` reset

### Erkennungshilfen:
- Metadata-Analyse: EXIF prüfen (Kamera-Marke, Software-Flags)
- Keine externe KI-Erkennung nötig für Start — Community-Moderation reicht vorerst

---

## 6. Kamera-Flow

### Aufnahme (Photo)
1. Kamera-Vorschau (Fullscreen)
2. Auslöser → Foto aufnehmen
3. **Kompression:** flutter_image_compress → Ziel: < 500KB, Qualität 80%, max 1080px
4. Caption-Eingabe
5. EA-Markierung optional ankreuzen
6. Upload → Supabase Storage

### Aufnahme (Video)
1. Kamera-Vorschau mit Aufnahme-Button
2. Aufnahme starten/stoppen (max 60s)
3. **Kompression:** ffmpeg_kit_flutter → Ziel: < 5MB, 720p, H.264, 30fps
4. Thumbnail generieren (erstes Frame)
5. Caption + EA-Markierung
6. Upload

### Verbote
- Galerie-Upload: NICHT möglich — absolute Core-Regel
- Filter/Effects: NICHT erlaubt
- EXIF-Daten werden vor Upload stripped

---

## 7. Auth-Flow

### Registrierung
- E-Mail + Passwort
- Username (unique, 3-20 Zeichen, alphanumerisch + underscore)
- Bestätigungsmail via Supabase Auth

### Login
- E-Mail + Passwort
- "Angemeldet bleiben" (Refresh Token)

### Profil
- Avatar (Foto — muss mit interner Kamera aufgenommen werden!)
- Bio (max 150 Zeichen)
- Posts-Grid, Follower/Following-Zähler

---

## 8. App-Struktur (Flutter)

```
lib/
├── main.dart
├── core/
│   ├── theme/
│   ├── constants/
│   └── utils/
│       ├── compression.dart      # Bild+Video Kompression
│       ├── exif_stripper.dart    # EXIF-Daten entfernen
│       └── feed_algorithm.dart   # Ranking-Score
├── data/
│   ├── models/                   # User, Post, Comment, etc.
│   ├── repositories/            # Datenbank-Zugriffe
│   └── services/
│       ├── supabase_service.dart
│       ├── auth_service.dart
│       ├── camera_service.dart
│       └── notification_service.dart
├── features/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   └── forgot_password_screen.dart
│   ├── feed/
│   │   ├── feed_screen.dart     # FYP oder Following Tab
│   │   ├── post_card.dart
│   │   └── video_player_widget.dart
│   ├── camera/
│   │   ├── camera_screen.dart   # Vollbild-Kamera
│   │   ├── photo_review_screen.dart
│   │   └── video_review_screen.dart
│   ├── post/
│   │   ├── create_post_screen.dart  # Caption + EA-Markierung
│   │   └── post_detail_screen.dart
│   ├── profile/
│   │   ├── profile_screen.dart
│   │   ├── edit_profile_screen.dart
│   │   └── user_profile_screen.dart
│   ├── notifications/
│   │   └── notifications_screen.dart
│   ├── search/
│   │   └── search_screen.dart
│   └── ea_moderation/
│       └── report_post_sheet.dart   # EA-Markierung bottomsheet
└── widgets/
    ├── ea_badge.dart
    ├── loading_indicator.dart
    └── blur_overlay.dart
```

---

## 9. Ordnerstruktur

```
workspace/realm-auth-app/
├── SPEC.md                    # Diese Datei
├── README.md                  # Setup-Anleitung
├── flutter/                   # Flutter-Projekt (iOS + Android)
│   ├── pubspec.yaml
│   ├── lib/
│   └── ...
├── supabase/                  # Supabase SQL Migrations
│   └── migrations/
│       └── 001_initial.sql
└── docs/                     # Extra-Dokumentation
    ├── api_endpoints.md
    └── design.md
```

---

## 10. Security-Überlegungen

- **RLS (Row Level Security)** in Supabase — User sehen nur ihre eigenen Daten + öffentliche Posts
- **Upload-Validierung:** Dateityp (jpeg/png/mp4), Dateigröße (Foto < 2MB, Video < 20MB), MIME-Type Check
- **Rate Limiting:** Supabase Level / Edge Functions
- **Auth-Token:** Secure Storage (flutter_secure_storage), nicht in SharedPreferences
- **EXIF Strippen:** Obytes/exif_writer oder manuell parsen + entfernen

---

## 11. Nice-to-Have (für später)

- [ ] Push Notifications (Firebase Cloud Messaging / Supabase Realtime)
- [ ] Livestream-Funktion
- [ ] Sound/Audio-Tracks zu Videos
- [ ] Text-Overlays auf Fotos
- [ ] Admob / Monetarisierung
- [ ] Admin-App (Flutter Web oder React Native Dashboard)
- [ ] Analytics Dashboard

---

## 12. Nächste Schritte

1. ✅ SPEC.md schreiben (hier)
2. Flutter-Projekt anlegen (`flutter create realm_auth_app`)
3. Supabase-Projekt in der Cloud anlegen
4. SQL-Migration ausführen
5. Auth-Screens implementieren
6. Feed + Camera implementieren
7. EA-Reporting + Edge Functions
8. Testen + Build
