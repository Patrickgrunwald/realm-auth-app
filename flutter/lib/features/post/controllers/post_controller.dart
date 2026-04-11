import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/exif_stripper.dart';
import '../../../core/utils/compression.dart';

class PostNotifier extends StateNotifier<AsyncValue<void>> {
  PostNotifier() : super(const AsyncValue.data(null));

  Future<bool> createPost({
    required String mediaPath,
    required String type,
    required String caption,
    required bool isEAMarked,
  }) async {
    state = const AsyncValue.loading();
    try {
      // EXIF strippen (wichtig für EA-Erkennung)
      final noExif = await stripExif(mediaPath);

      // Komprimieren (Bilder)
      File finalFile;
      if (type == 'photo') {
        finalFile = (await compressImage(noExif)) ?? noExif;
      } else {
        finalFile = File(mediaPath);
      }

      // Info loggen (später Supabase-Upload)
      print('=== POST ERSTELLT ===');
      print('Typ: $type');
      print('Caption: $caption');
      print('KI-Markierung: $isEAMarked');
      print('Datei: ${finalFile.path}');
      print('Größe: ${await finalFile.length()} bytes');
      print('========================');

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      print('Post erstellen fehlgeschlagen: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final postControllerProvider = StateNotifierProvider<PostNotifier, AsyncValue<void>>((ref) {
  return PostNotifier();
});
