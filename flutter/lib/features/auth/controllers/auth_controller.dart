import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/user_model.dart';
import '../../../data/services/supabase_service.dart';
import '../../../core/constants/app_constants.dart';

// Auth-State
class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  bool get isAuthenticated => user != null;
}

// Auth-Controller
class AuthController extends StateNotifier<AuthState> {
  AuthController() : super(const AuthState()) {
    _init();
  }

  void _init() {
    final currentUser = SupabaseService.currentUser;
    if (currentUser != null) {
      _loadUserProfile(currentUser.id);
    }

    SupabaseService.authStateChanges.listen((data) {
      final event = data.event;
      final session = data.session;

      if (event == AuthChangeEvent.signedIn && session != null) {
        _loadUserProfile(session.user.id);
      } else if (event == AuthChangeEvent.signedOut) {
        state = const AuthState();
      } else if (event == AuthChangeEvent.tokenRefreshed && session != null) {
        _loadUserProfile(session.user.id);
      }
    });
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      final data = await SupabaseService.client
          .from(AppConstants.usersTable)
          .select()
          .eq('id', userId)
          .single();
      final user = UserModel.fromMap(data);
      state = state.copyWith(user: user, clearError: true);
    } catch (_) {
      // Profil existiert noch nicht — ignorieren
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await SupabaseService.client.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: 'Anmeldung fehlgeschlagen',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapAuthError(e.message),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ein unbekannter Fehler ist aufgetreten',
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Benutzername-Unique-Check
      final existing = await SupabaseService.client
          .from(AppConstants.usersTable)
          .select('id')
          .eq('username', username.trim())
          .maybeSingle();

      if (existing != null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Dieser Benutzername ist bereits vergeben',
        );
        return false;
      }

      final response = await SupabaseService.client.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'username': username.trim()},
      );

      if (response.user != null) {
        // User wird AUTOMATISCH vom DB-Trigger handle_new_user() angelegt
        // Hier nur noch lokales Profil laden
        await _loadUserProfile(response.user!.id);
        state = state.copyWith(isLoading: false);
        return true;
      }

      state = state.copyWith(
        isLoading: false,
        error: 'Registrierung fehlgeschlagen',
      );
      return false;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ein Fehler ist aufgetreten: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      await SupabaseService.client.auth.signOut();
      state = const AuthState();
    } catch (_) {
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email.trim());
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _mapAuthError(e.message),
      );
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Fehler beim Senden der E-Mail',
      );
      return false;
    }
  }

  Future<bool> checkUsernameAvailable(String username) async {
    try {
      final existing = await SupabaseService.client
          .from(AppConstants.usersTable)
          .select('id')
          .eq('username', username.trim())
          .maybeSingle();
      return existing == null;
    } catch (_) {
      return true;
    }
  }

  Future<bool> confirmSignup({
    required String token,
    required String email,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Token ist ein Secure-Token aus dem Bestätigungslink.
      // verifyOTP validiert und setzt email_confirmed = true
      await SupabaseService.client.auth.verifyOTP(
        email: email.trim(),
        token: token,
        type: OtpType.signup,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on AuthException catch (e) {
      // "already been consumed" = Token wurde bereits verwendet = E-Mail
      // ist bereits bestätigt → das ist OK, gilt als Erfolg
      if (e.message.toLowerCase().contains('already been consumed') ||
          e.message.toLowerCase().contains('invalid')) {
        state = state.copyWith(isLoading: false);
        return true;
      }
      state = state.copyWith(
        isLoading: false,
        error: _mapAuthError(e.message),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Bestätigung fehlgeschlagen: ${e.toString()}',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  String _mapAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return 'E-Mail oder Passwort falsch';
    }
    if (msg.contains('email not confirmed')) {
      return 'Bitte bestätige zuerst deine E-Mail-Adresse';
    }
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Diese E-Mail-Adresse ist bereits registriert';
    }
    if (msg.contains('password should be at least')) {
      return 'Passwort muss mindestens 8 Zeichen haben';
    }
    if (msg.contains('rate limit')) {
      return 'Zu viele Versuche. Bitte warte einen Moment';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Keine Internetverbindung';
    }
    return message;
  }
}

// Provider
final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);

// Convenience-Provider
final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authControllerProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isAuthenticated;
});
