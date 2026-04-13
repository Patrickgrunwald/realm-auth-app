import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate after a short delay — no animation dependencies
    Future.delayed(const Duration(milliseconds: 800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final authState = ref.read(authControllerProvider);
    debugPrint('[SplashScreen] auth check — isAuthenticated=${authState.isAuthenticated}');
    if (authState.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_circle_outline_rounded, color: AppColors.accent, size: 80),
            SizedBox(height: 20),
            Text('Realm Auth', style: TextStyle(color: AppColors.accent, fontSize: 32, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent)),
          ],
        ),
      ),
    );
  }
}
