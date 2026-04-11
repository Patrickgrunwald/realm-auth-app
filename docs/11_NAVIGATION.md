# 11 — Navigation & Routing

## Bottom Navigation

```
┌────────────────────────────────┐
│                                │
│        [SCREEN CONTENT]        │
│                                │
│                                │
│                                │
├────────────────────────────────┤
│   [🏠]      [➕]      [🔔]    │  ← Bottom Nav
│   Feed    Kamera    Profil    │
│                                │
│   [Suche versteckt in Feed]   │
└────────────────────────────────┘
```

**Kein Such-Tab in Bottom Nav** — Suche ist ein Icon im Feed-Screen Header.

## Tab-Struktur

| Tab | Screen | Icon |
|---|---|---|
| Feed | FeedScreen | `Icons.home` |
| Kamera | CameraScreen | `Icons.add_box` (mittlerer Tab, prominent) |
| Profil | ProfileScreen | `Icons.person` |

## GoRouter Setup

```dart
// app_router.dart
import 'package:go_router/go_router.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    final isLoggedIn = supabase.auth.currentUser != null;
    final isAuthRoute = ['/login', '/register', '/forgot-password']
      .contains(state.uri.path);

    if (!isLoggedIn && !isAuthRoute) return '/login';
    if (isLoggedIn && isAuthRoute) return '/';
    return null;
  },
  routes: [
    // Auth Routes
    GoRoute(
      path: '/login',
      builder: (_, __) => LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (_, __) => RegisterScreen(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (_, __) => ForgotPasswordScreen(),
    ),

    // Main App Shell (mit Bottom Nav)
    ShellRoute(
      builder: (_, __, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => FeedScreen(),
          routes: [
            GoRoute(
              path: 'post/:postId',
              builder: (_, state) => PostDetailScreen(
                postId: state.pathParameters['postId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/camera',
          builder: (_, __) => CameraScreen(),
          routes: [
            GoRoute(
              path: 'review',
              builder: (_, state) {
                final extra = state.extra as Map<String, dynamic>;
                return ReviewScreen(
                  mediaFile: extra['file'],
                  type: extra['type'],
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: '/profile',
          builder: (_, __) => ProfileScreen(), // Eigenes Profil
          routes: [
            GoRoute(
              path: 'edit',
              builder: (_, __) => EditProfileScreen(),
            ),
            GoRoute(
              path: 'followers/:userId',
              builder: (_, state) => FollowersScreen(
                userId: state.pathParameters['userId']!,
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/user/:userId',
          builder: (_, state) => UserProfileScreen(
            userId: state.pathParameters['userId']!,
          ),
        ),
        GoRoute(
          path: '/notifications',
          builder: (_, __) => NotificationsScreen(),
        ),
        GoRoute(
          path: '/search',
          builder: (_, __) => SearchScreen(),
        ),
      ],
    ),
  ],
);
```

## MainShell (Bottom Nav Wrapper)

```dart
// main_shell.dart
class MainShell extends StatelessWidget {
  final Widget child;

  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculateSelectedIndex(context),
        onTap: (index) => _onItemTapped(index, context),
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Feed',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Kamera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
```

## Deep Links

```
realm-auth://
├── realm-auth://post/{postId}       → Post öffnen
├── realm-auth://user/{userId}      → Profil öffnen
├── realm-auth://camera             → Kamera öffnen

https://realmauth.app
├── /post/{postId}                  → Post öffnen (Universal Link)
├── /user/{userId}                 → Profil öffnen
```

## Push Notification Deep Links

Wenn Push-Notification geklickt wird → App öffnet entsprechenden Screen:

```dart
// Beim Initialisieren der App
FirebaseMessaging.onMessageOpenedApp.listen((message) {
  final data = message.data;
  if (data['type'] == 'like') {
    GoRouter.of(context).push('/post/${data['postId']}');
  } else if (data['type'] == 'follow') {
    GoRouter.of(context).push('/user/${data['actorId']}');
  }
});
```

---

## Nächste Docs

← [10 EA_MODERATION](10_EA_MODERATION.md)
→ [12 DESIGN](12_DESIGN.md)
