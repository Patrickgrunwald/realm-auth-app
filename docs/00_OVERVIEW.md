# 00 — Overzogen

## Projekt-Name

**Realm Auth** (Arbeitstitel — catchy Name später)

## Was ist das?

Social-Media-App à la TikTok für Foto + Video-Inhalte. Der Clou:
- Medien werden **nur über die interne Kamera** aufgenommen — kein Galerie-Upload
- Keine Filter, keine Effects
- KI-generierte Inhalte (EA = External/Artificial) werden von der Community markiert und bei 5 Meldungen geprüft + gelöscht

## Zielgruppe

- Mobile-first User (18-35)
- Menschen die authentische Inhalte teilen wollen (kein "Fake-Glanz")
- Community-Moderation gegen KI-Inhalte

## Tech-Stack

### Frontend
- **Flutter 3.x** (Dart) — eine Codebasis für iOS + Android
- State Management: **Riverpod** (einfacher als Bloc, besser als Provider)
- Kamera: `camera` package
- Video: `video_player` + `chewie`
- Kompression: `ffmpeg_kit_flutter` (Video) + `flutter_image_compress` (Foto)

### Backend
- **Supabase** (PostgreSQL + Auth + Storage + Realtime + Edge Functions)
- Eine Datenbank für beide Apps
- Auth via Supabase Auth (E-Mail + Passwort)
- Storage für Medien (Fotos + Videos)
- Edge Functions für EA-Melde-Logik + Auto-Löschung

### Warum Supabase?
- Out-of-the-box Auth, Storage, Realtime-Subscriptions
- RLS (Row Level Security) für Zugriffskontrolle
- Kostenloser Plan reicht für Entwicklung + Start
- PostgreSQL = flexibel, relational, robust

## Key-Entscheidungen

| Entscheidung | Gewählt | Begründung |
|---|---|---|
| Framework | Flutter | Eine Codebasis für iOS + Android |
| Backend | Supabase | Schnellste Time-to-Market |
| Auth | Supabase Auth | Integriert, sicher |
| Kompression Video | ffmpeg_kit_flutter | Beste Qualität/Größe-Ratio |
| Kompression Bild | flutter_image_compress | Schnell, leicht |
| State Management | Riverpod | Einfach, testbar, Type-safe |
| Feed-Algorithmen | PostgreSQL + Dart | Supabase Queries + Flutter-Sortierung |

## App-Screens (MVP)

```
Splash → Onboarding → Auth Stack
                         ↓
              Login / Register / ForgotPW
                         ↓
                 Main App (Bottom Nav)
                    ↓           ↓           ↓
              Feed Tab    Camera Tab   Profile Tab
              (FYP/       (Fullscreen   (My Profile /
               Follow)      Camera)      Others)
                         ↓
                   Post Create
                   (Caption +
                    EA Toggle)
```

## Ordnerstruktur

```
realm-auth-app/
├── README.md              ← Du bist hier
├── SPEC.md                ← Ursprüngliche Spezifikation
├── docs/
│   ├── 00_OVERVIEW.md     ← Überblick
│   ├── 01_ARCHITECTURE.md ← System-Architektur
│   ├── 02_DATABASE.md     ← DB-Schema + RLS
│   ├── 03_API.md          ← Edge Functions + REST
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
└── flutter/               ← Flutter-Projekt (kommt)
    ├── lib/
    └── pubspec.yaml
```

## Nächste Docs

→ [01 ARCHITECTURE](01_ARCHITECTURE.md) — System-Architektur
