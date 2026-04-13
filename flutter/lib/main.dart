import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'data/services/supabase_service.dart';
import 'src/credentials.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('[main] START — version=hardcoded_credentials');

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

  debugPrint('[main] SUPABASE_URL: $supabaseUrl');
  debugPrint('[main] SUPABASE_ANON_KEY: ${supabaseAnonKey.substring(0, 20)}...');

  try {
    await SupabaseService.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
    debugPrint('[main] SupabaseService.initialize() — DONE');
  } catch (e, st) {
    debugPrint('[main] SupabaseService.initialize() FAILED: $e');
    debugPrint('[main] STACK: $st');
    return;
  }

  runApp(
    const ProviderScope(
      child: RealmAuthApp(),
    ),
  );
  debugPrint('[main] runApp() called');
}
