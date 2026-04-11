# Realm Auth — Projekt-Dokumentation

> **Arbeitstitel der App:** Realm Auth
> **Status:** Planung abgeschlossen, Entwicklung startet bald
> **Plattform:** Flutter (iOS + Android)

---

## 📚 Dokumentations-Übersicht

| # | Dokument | Beschreibung |
|---|---|---|
| 00 | [OVERVIEW](docs/00_OVERVIEW.md) | Projekt-Überblick, Features, Tech-Stack-Entscheidungen |
| 01 | [ARCHITECTURE](docs/01_ARCHITECTURE.md) | System-Architektur, Frontend/Backend-Trennung, Datenfluss |
| 02 | [DATABASE](docs/02_DATABASE.md) | Supabase PostgreSQL Schema, RLS Policies, Indexes |
| 03 | [API](docs/03_API.md) | Edge Functions, API-Endpoints, Webhooks |
| 04 | [FRONTEND_STRUCTURE](docs/04_FRONTEND_STRUCTURE.md) | Flutter-Projektstruktur, Pakete, Architektur |
| 05 | [AUTH_FLOW](docs/05_AUTH_FLOW.md) | Login, Registrierung, Passwort-Reset, Session-Management |
| 06 | [FEED](docs/06_FEED.md) | For-You-Page, Following-Feed, Post-Cards, Video-Player |
| 07 | [CAMERA](docs/07_CAMERA.md) | Kamera-Flow, Foto/Video aufnehmen, EXIF-Stripping, Kompression |
| 08 | [POSTS](docs/08_POSTS.md) | Post erstellen, Post-Detail, Likes, Kommentare, Teilen |
| 09 | [PROFILE](docs/09_PROFILE.md) | Profil-Seite, Profil bearbeiten, Follower/Following |
| 10 | [EA_MODERATION](docs/10_EA_MODERATION.md) | EA-Markierung, 5-Melder-System, Admin-Prüfung, Auto-Löschung |
| 11 | [NAVIGATION](docs/11_NAVIGATION.md) | Bottom Navigation, Routing, Deep Links |
| 12 | [DESIGN](docs/12_DESIGN.md) | UI/UX: Farben, Typografie, Komponenten, Icons |
| 13 | [SETUP](docs/13_SETUP.md) | Projekt-Setup: Flutter, Supabase, Dev-Environment |
| 14 | [DEPLOYMENT](docs/14_DEPLOYMENT.md) | App Store, Google Play, Supabase-Production |

---

## 🎯 Core-Features (MVP)

### Must-Have
- [x] Registrierung (E-Mail + Passwort)
- [x] Login / Logout / "Angemeldet bleiben"
- [x] For-You-Feed (Algorithmus-basiert)
- [x] Following-Feed
- [x] Foto aufnehmen + komprimiert hochladen
- [x] Video aufnehmen + komprimiert hochladen (max 60s)
- [x] Galerie-Upload: **VERBOTEN** (kein Gallery-Picker)
- [x] Keine Filter / Effects
- [x] Caption schreiben
- [x] Likes geben
- [x] Kommentare schreiben
- [x] Teilen (intern)
- [x] Profil mit Avatar (nur Kamera!), Bio, Posts-Grid
- [x] Follow / Unfollow
- [x] EA-Content markieren (deutlicher Button!)
- [x] EA-Melde-Flow: 5 Meldungen → pending → Admin prüft → löschen
- [x] Benachrichtigungen (Likes, Comments, Follows)
- [x] Suche (User + Posts)

### Nice-to-Have (Phase 2)
- [ ] Push Notifications
- [ ] Admin-Dashboard (Web)
- [ ] Monetarisierung (Ads)
- [ ] Sound/Audio-Tracks
- [ ] Livestream

---

## 🚫 Was NICHT erlaubt ist (Hard Rules)

1. **Kein Galerie-Upload** — User dürfen nur Fotos/Videos verwenden die sie MIT der App aufnehmen
2. **Keine Filter/Effects** — das Original muss 1:1 veröffentlicht werden
3. **EXIF-Daten werden IMMER entfernt** — vor dem Upload
4. **Keine externen Links** im Caption (Spam-Schutz)
5. **Username ist unique** — 3-20 Zeichen, alphanumerisch + underscore

---

## 🔗 Wichtige Links

- [Supabase Dashboard](https://app.supabase.com) — DB, Auth, Storage
- [Flutter Docs](https://docs.flutter.dev)
- [Supabase Flutter SDK](https://supabase.com/docs/reference/dart/introduction)
- [figma.to/design](https://figma.to) — Design-Dateien (coming soon)

---

## 📅 Entwicklungs-Phasen

| Phase | Inhalt | Status |
|---|---|---|
| 1 | Projekt-Setup + Auth (Login/Register) | 🚧 Demnächst |
| 2 | Feed + Post-Card + Video-Player | 📋 Geplant |
| 3 | Kamera + Kompression + Post erstellen | 📋 Geplant |
| 4 | Profil + Follow-System | 📋 Geplant |
| 5 | EA-Moderation + Edge Functions | 📋 Geplant |
| 6 | Notifications + Suche | 📋 Geplant |
| 7 | Testing + Deployment | 📋 Geplant |
