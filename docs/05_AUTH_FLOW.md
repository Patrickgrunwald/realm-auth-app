# 05 — Auth-Flow

## Auth-Provider

Supabase Auth übernimmt:
- E-Mail + Passwort Registrierung
- E-Mail + Passwort Login
- Session-Management (Access Token + Refresh Token)
- "Angemeldet bleiben" (Refresh Token persistent)
- Passwort vergessen / Reset per E-Mail

## Registrierung

### Flow

```
1. User gibt ein: E-Mail, Passwort, Username
2. Client: Validierung
   - E-Mail: gültiges Format
   - Passwort: min. 8 Zeichen
   - Username: 3-20 Zeichen, alphanumerisch + underscore, unique
3. Client: supabase.auth.signUp()
4. Supabase Auth: Account erstellen → E-Mail-Bestätigung schicken
5. User klickt Link in E-Mail → bestätigt
6. Trigger: handle_new_user() → users-Tabelle-Eintrag erstellen
7. User wird zu App weitergeleitet → Login-Screen
```

### Registrierungs-Screen (register_screen.dart)

```
┌──────────────────────────────┐
│  ← Zurück                    │
│                              │
│     [Realm Auth Logo]        │
│                              │
│  ┌────────────────────────┐  │
│  │ Username                │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ E-Mail                  │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ Passwort                │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ Passwort bestätigen    │  │
│  └────────────────────────┘  │
│                              │
│  [   Konto erstellen   ]     │
│                              │
│  Hast du schon ein Konto?    │
│  → Jetzt anmelden            │
└──────────────────────────────┘
```

### Code

```dart
// auth_repository.dart
class AuthRepository {
  final SupabaseClient _supabase;

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    // 1. Check ob Username schon vergeben
    final exists = await _supabase
      .from('users')
      .select('id')
      .eq('username', username)
      .maybeSingle();

    if (exists != null) {
      throw AuthException('Username bereits vergeben');
    }

    // 2. Sign Up bei Supabase Auth
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'username': username,
        'display_name': username,
      }
    );

    return response;
  }
}
```

## Login

### Flow

```
1. User gibt ein: E-Mail, Passwort
2. Client: supabase.auth.signInWithPassword()
3. Bei Erfolg: Session speichern (automatisch durch Supabase SDK)
4. Redirect zu Feed
```

### Login-Screen (login_screen.dart)

```
┌──────────────────────────────┐
│                              │
│     [Realm Auth Logo]        │
│                              │
│  ┌────────────────────────┐  │
│  │ E-Mail                  │  │
│  └────────────────────────┘  │
│                              │
│  ┌────────────────────────┐  │
│  │ Passwort                │  │
│  └────────────────────────┘  │
│                              │
│  [    Anmelden    ]          │
│                              │
│  → Passwort vergessen?       │
│                              │
│  Noch kein Konto?            │
│  → Registrieren              │
└──────────────────────────────┘
```

## Passwort vergessen

### Flow

```
1. User gibt E-Mail ein
2. supabase.auth.resetPasswordForEmail()
3. Supabase schickt Reset-Link an E-Mail
4. User klickt Link → öffnet App auf Reset-Screen
5. Neues Passwort eingeben → supabase.auth.updateUser()
```

## Session-Management

### Token-Speicherung

Supabase SDK speichert Tokens automatisch:
- **Access Token** → Flutter Secure Storage (verschlüsselt)
- **Refresh Token** → Flutter Secure Storage

### Session-Wiederherstellung

Beim App-Start prüft Supabase automatisch:
```dart
await Supabase.initialize(...);
// → Liest Session aus Secure Storage
// → Validiert Refresh Token
// → Stellt Session wieder her oder logout
```

### Auth-State-Listener

```dart
supabase.auth.onAuthStateChange((event, session) {
  if (event == AuthChangeEvent.signedIn) {
    // → Navigate zu Feed
  } else if (event == AuthChangeEvent.signedOut) {
    // → Navigate zu Login
  }
});
```

## Geschützte Routes

Wenn User nicht eingeloggt → automatisch zu Login redirect:

```dart
// app_router.dart
final router = GoRouter(
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentUser != null;
    final isAuthRoute = state.uri.path in ['/login', '/register'];

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/';
    return null;
  },
  routes: [...],
);
```

## Avatar-Upload bei Registrierung

Nach erstem Login wird User aufgefordert, ein Avatar-Foto zu machen:
- **KEIN Galerie-Upload!** → Kamera-Pflicht
- Nacher erklärt

---

## Nächste Docs

← [04 FRONTEND_STRUCTURE](04_FRONTEND_STRUCTURE.md)
→ [06 FEED](06_FEED.md)
