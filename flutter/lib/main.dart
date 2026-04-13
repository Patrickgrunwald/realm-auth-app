import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'data/services/supabase_service.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // German locale for timeago
  timeago.setLocaleMessages('de', timeago.DeMessages());

  // Status-/Navigationsleiste transparent
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Nur Hochformat
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Supabase Credentials
  // Build-Flag Vorrang: --dart-define=SUPABASE_URL=... (für Web/Chrome Dev)
  // Sonst: .env Datei im Projekt-Root (native builds)
  String supabaseUrl;
  String supabaseAnonKey;

  const envUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const envKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (envUrl.isNotEmpty && envKey.isNotEmpty) {
    // Web Dev: --dart-define Werte direkt nutzen
    supabaseUrl = envUrl;
    supabaseAnonKey = envKey;
  } else {
    // Native: lade aus .env Datei
    try {
      await dotenv.load(fileName: ".env");
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    } catch (_) {
      // Keine .env gefunden — fehlende Konfiguration
      debugPrint('[main] FEHLER: Keine SUPABASE_URL konfiguriert.');
      debugPrint('[main] Bitte .env Datei anlegen oder --dart-define beim Build setzen.');
      return;
    }
  }

  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    debugPrint('[main] SUPABASE_URL oder SUPABASE_ANON_KEY fehlt in .env');
    return;
  }

  await SupabaseService.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(
    const ProviderScope(
      child: RealmAuthApp(),
    ),
  );
}
