import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/browser_url.dart';
import '../../../data/services/supabase_service.dart';

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
    try {
      // Vollständige URL inkl. Hash-Fragment direkt vom Browser holen
      // (GoRouter verschluckt das Fragment normalerweise)
      final fullUrl = getBrowserUrl();

      if (fullUrl.isEmpty) {
        _fail('Konnte URL nicht lesen. Bitte öffne den Bestätigungslink direkt im Browser.');
        return;
      }

      // getSessionFromUrl parst #token=... automatisch in Query-Parameter
      // Das Ergebnis wird nicht benötigt — wichtig ist der interne Session-Setzer
      await SupabaseService.client.auth.getSessionFromUrl(
        Uri.parse(fullUrl),
        storeSession: true,
      );

      if (!mounted) return;

      _succeed();
    } on AuthException catch (e) {
      if (!mounted) return;
      if (e.message.toLowerCase().contains('expired') ||
          e.message.toLowerCase().contains('invalid') ||
          e.message.toLowerCase().contains('otp_expired')) {
        _fail('Der Bestätigungslink ist abgelaufen oder bereits verwendet. Bitte registriere dich erneut.');
      } else {
        _fail(e.message);
      }
    } catch (e) {
      if (!mounted) return;
      _fail('Fehler: ${e.toString()}');
    }
  }

  void _fail(String msg) {
    setState(() {
      _isConfirming = false;
      _errorMessage = msg;
    });
  }

  void _succeed() {
    setState(() {
      _isConfirming = false;
      _success = true;
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) context.go('/login');
      });
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
