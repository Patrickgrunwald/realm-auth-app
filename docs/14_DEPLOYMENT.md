# 14 — Deployment

## iOS App Store

### Voraussetzungen
- Apple Developer Account (€99/Jahr)
- Mac mit Xcode
- App Icon (1024x1024 PNG)
- Screenshots für alle iPhone-Größen
- Datenschutzerklärung (URL)

### Schritte

**1. Version erhöhen**
```yaml
# pubspec.yaml
version: 1.0.0+1  →  1.0.0+2
```

**2. iOS Build erstellen**
```bash
cd flutter
flutter build ipa --release
# Output: build/ios/ipa/realm_auth_app.ipa
```

**3. App Store Connect**

1. https://appstoreconnect.apple.com öffnen
2. Neue App erstellen:
   - Name: Realm Auth
   - Sprache: Deutsch
   - Bundle ID: `com.realmauth.realm_auth_app`
   - User Access: Full Access
3. App-Informationen ausfüllen
4. Preise und Verfügbarkeit
5. Datenschutz: URL zur Datenschutzerklärung

**4. Build hochladen (Xcode)**
```bash
# Alternativ: Transporter App (Mac App Store)
# IPA-Datei ziehen und loslassen
```

Oder per CLI:
```bash
xcrun altool --upload-app -f realm_auth_app.ipa -t ios -u "apple@email.com" -p "app-specific-password"
```

**5. Review einreichen**
- Testflight: mindestens 1 externer Tester
- App Store Review: 24-48h Wartezeit (meist schneller)

### Typische Ablehnungs-Gründe vermeiden
- Kamera-Permission-Text muss klar sein
- Datenschutzerklärung muss erreichbar sein
- KEIN Galerie-Upload — in der Review-Notes erklären warum

---

## Google Play Store

### Voraussetzungen
- Google Play Developer Account (einmalig $25)
- App Icon (512x512 PNG)
- Screenshots (mind. 2)
- Datenschutzerklärung

### Schritte

**1. Version erhöhen**
```yaml
# pubspec.yaml
version: 1.0.0+1
```

**2. Android Build erstellen**
```bash
cd flutter
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

**3. Google Play Console**

1. https://play.google.com/console öffnen
2. Neue App erstellen
3. App-Informationen:
   - Kurze Beschreibung (max 80 Zeichen)
   - Vollständige Beschreibung (max 4000 Zeichen)
4. Screenshots: Telefon (min 2)
5. Datenschutzerklärung-URL
6. Inhalts-Rating: Ausfüllen (Quiz)
7. Preis: Kostenlos / Kostenpflichtig
8. Länder: Auswählen

**4. Release erstellen**
- Production → Neues Release → AAB-Datei hochladen
- Release-Notizen schreiben
- Review-Prüfung (automated)

**5. Review (interner Test → Produktion)**
- Internal Test: sofort verfügbar
- Closed Test: spezifische Tester
- Production: Review 1-7 Tage

---

## Supabase Production

### Production-Projekt

1. **Separat vom Dev-Projekt!** Neues Supabase-Projekt nur für Production
2. DB-Migration einspielen
3. RLS Policies aktivieren
4. Storage Buckets einrichten

### Environment-Variablen

```env
# .env.production
SUPABASE_URL=https://your-prod-project.supabase.co
SUPABASE_ANON_KEY=eyJhbGc...prod-anon-key
```

```dart
// lib/core/env/prod.dart
class Env {
  static const String supabaseUrl = 'https://xyz.supabase.co';
  static const String supabaseAnonKey = 'eyJ...';
}
```

### Security Checklist

- [ ] RLS Policies auf ALLEN Tabellen aktiviert
- [ ] SUPABASE_SERVICE_ROLE_KEY: NIEMALS in Flutter-App
- [ ] Storage Policies: Upload nur für authentifizierte User
- [ ] Rate Limiting in Edge Functions
- [ ] E-Mail-Verifizierung bei Registrierung (`--email-confirm: true`)

---

## Edge Functions Deployment

```bash
# Supabase CLI installieren
npm install -g supabase

# Login
supabase login

# Initialisieren
supabase init

# Production deployen
supabase functions deploy ea-moderation --project-ref your-project-ref

# Mit Secrets
supabase secrets set ADMIN_API_KEY=xxx --project-ref your-project-ref
```

---

## Monitoring

### Supabase
- Dashboard → Reports
- Edge Function Logs
- Database → Performance

### Flutter App
- Firebase Crashlytics (bei Fehlern benachrichtigen)
- Sentry (alternativ)

---

## Continuous Deployment (optional)

### GitHub Actions

```yaml
# .github/workflows/build.yml
name: Build

on:
  push:
    branches: [main]

jobs:
  build-ios:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build ipa --release
      - uses: actions/upload-artifact@v4
        with:
          name: ios-build
          path: build/ios/ipa/realm_auth_app.ipa

  build-android:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter build appbundle --release
      - uses: actions/upload-artifact@v4
        with:
          name: android-build
          path: build/app/outputs/bundle/release/app-release.aab
```

---

## Nach dem Launch

- [ ] App-Store-Seite pflegen (Screenshots aktuell halten)
- [ ] Reviews beantworten
- [ ] Crash-Reports prüfen
- [ ] User-Feedback sammeln
- [ ] Phase-2-Features planen

---

## Nächste Docs

← [13 SETUP](13_SETUP.md)
[Zurück zum Hauptmenü](../README.md)
