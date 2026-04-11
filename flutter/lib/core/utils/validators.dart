import '../constants/app_constants.dart';

class Validators {
  Validators._();

  static String? isValidEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'E-Mail-Adresse ist erforderlich';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Ungültige E-Mail-Adresse';
    }
    return null;
  }

  static String? isValidUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Benutzername ist erforderlich';
    }
    final trimmed = value.trim();
    if (trimmed.length < AppConstants.minUsernameLength) {
      return 'Benutzername muss mindestens ${AppConstants.minUsernameLength} Zeichen haben';
    }
    if (trimmed.length > AppConstants.maxUsernameLength) {
      return 'Benutzername darf maximal ${AppConstants.maxUsernameLength} Zeichen haben';
    }
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(trimmed)) {
      return 'Nur Buchstaben, Zahlen und _ erlaubt';
    }
    return null;
  }

  static String? isValidPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Passwort ist erforderlich';
    }
    if (value.length < AppConstants.minPasswordLength) {
      return 'Passwort muss mindestens ${AppConstants.minPasswordLength} Zeichen haben';
    }
    return null;
  }

  static String? isValidPasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Passwortbestätigung ist erforderlich';
    }
    if (value != password) {
      return 'Passwörter stimmen nicht überein';
    }
    return null;
  }

  static String? isRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName ist erforderlich';
    }
    return null;
  }
}
