import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/feed/screens/post_detail_screen.dart';
import '../../features/post/models/post_model.dart';
import '../../features/camera/screens/camera_screen.dart';
import '../../features/post/screens/create_post_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/shell/main_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authControllerProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;

      if (location == '/') return null;

      const publicRoutes = ['/login', '/register', '/forgot-password'];
      final isPublicRoute = publicRoutes.contains(location);

      if (isLoading) return null;

      if (!isAuthenticated && !isPublicRoute) {
        return '/login';
      }

      if (isAuthenticated && isPublicRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // ── Main App (mit Bottom Nav) ──
      ShellRoute(
        builder: (context, state, child) {
          // Welcher Tab ist aktiv?
          final loc = state.matchedLocation;
          int index = 0;
          if (loc.startsWith('/profile')) {
            index = 2;
          } else if (loc.startsWith('/home') || loc == '/home') {
            index = 0;
          }
          return MainShell(currentIndex: index, child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const FeedScreen(),
            routes: [
              GoRoute(
                path: 'post/:id',
                builder: (context, state) {
                  final post = state.extra as PostModel?;
                  return PostDetailScreen(post: post ?? PostModel.fromJson({}));
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) {
              final userId = state.uri.queryParameters['userId'];
              return ProfileScreen(userId: userId);
            },
          ),
        ],
      ),

      // ── Außerhalb der Shell (keine Bottom Nav) ──
      GoRoute(
        path: '/camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/post/create',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CreatePostScreen(
            mediaPath: extra?['mediaPath'] ?? '',
            mediaType: extra?['mediaType'] ?? 'photo',
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              'Seite nicht gefunden',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/'),
              child: const Text('Zurück zur Startseite'),
            ),
          ],
        ),
      ),
    ),
  );
});
