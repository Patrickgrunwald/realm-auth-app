import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/auth_controller.dart';

class ConfirmSignupScreen extends ConsumerStatefulWidget {
  const ConfirmSignupScreen({super.key});

  @override
  ConsumerState<ConfirmSignupScreen> createState() =>
      _ConfirmSignupScreenState();
}

class _ConfirmSignupScreenState extends ConsumerState<ConfirmSignupScreen> {
  bool _isConfirming = true;
  bool _success = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _confirmSignup());
  }

  Future<void> _confirmSignup() async {
    // Supabase sendet Bestätigungslinks als:
    // /confirm-signup?token=xxx&email=yyy
    // oder als Hash: /confirm-signup#token=xxx&email=yyy
    final uri = GoRouterState.of(context).uri;

    // Versuche query params (token, email)
    var token = uri.queryParameters['token'];
    var email = uri.queryParameters['email'];

    // Fallback: Hash-Fragment (z.B. #token=xxx&email=yyy)
    if ((token == null || token.isEmpty) && uri.fragment.isNotEmpty) {
      final params = Uri.splitQueryString(uri.fragment);
      token ??= params['token'];
      email ??= params['email'];
    }

    // Alternativ: token aus fullPath extrahieren wenn es im Pfad ist
    if ((token == null || token.isEmpty)) {
      final tokenMatch =
          RegExp(r'[?&]token=([^&]+)').firstMatch(uri.toString());
      token ??= tokenMatch?.group(1);
    }

    if (token == null || token.isEmpty) {
      setState(() {
        _isConfirming = false;
        _errorMessage = 'Kein Bestätigungstoken gefunden. Bitte nutze den Link aus der E-Mail.';
      });
      return;
    }

    // E-Mail aus Query oder Hash
    if (email == null || email.isEmpty) {
      final emailMatch =
          RegExp(r'[?&]email=([^&]+)').firstMatch(uri.toString());
      email = emailMatch?.group(1);
      // URL-decode
      if (email != null) email = Uri.decodeComponent(email);
    }

    final result = await ref.read(authControllerProvider.notifier).confirmSignup(
          token: token,
          email: email ?? '',
        );

    if (!mounted) return;

    setState(() {
      _isConfirming = false;
      if (result) {
        _success = true;
        // Automatisch zum Login nach 3s
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) context.go('/login');
        });
      } else {
        final err = ref.read(authControllerProvider).error;
        _errorMessage = err ?? 'Unbekannter Fehler bei der Bestätigung.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isConfirming) ...[
                const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.accent,
                  size: 72,
                ),
                const SizedBox(height: 24),
                const Text(
                  'E-Mail wird bestätigt...',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.accent,
                  ),
                ),
              ] else if (_success) ...[
                const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 72,
                ),
                const SizedBox(height: 24),
                const Text(
                  'E-Mail bestätigt! 🎉',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Du wirst automatisch zum Login weitergeleitet...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ] else ...[
                const Icon(
                  Icons.error_outline,
                  color: AppColors.error,
                  size: 72,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Bestätigung fehlgeschlagen',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Zum Login'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}