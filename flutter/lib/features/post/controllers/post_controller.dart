import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/exif_stripper.dart';
import '../../../core/utils/compression.dart';
import '../../../data/services/supabase_service.dart';

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
      final currentUid = SupabaseService.client.auth.currentUser?.id;
      if (currentUid == null) {
        throw Exception('Nicht angemeldet');
      }

      // EXIF strippen (wichtig für EA-Erkennung)
      final noExif = await stripExif(mediaPath);

      // Komprimieren (Bilder)
      File finalFile;
      if (type == 'photo') {
        finalFile = (await compressImage(noExif)) ?? noExif;
      } else {
        finalFile = File(mediaPath);
      }

      // Dateiname: posts/<userId>/<uuid>.<ext>
      final ext = finalFile.path.split('.').last.toLowerCase();
      final fileName =
          '$currentUid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bucket = AppConstants.storagePostsBucket;

      // Upload zu Supabase Storage
      final bytes = await finalFile.readAsBytes();
      final uploaded = await SupabaseService.client.storage
          .from(bucket)
          .uploadBinary(fileName, bytes);

      // Public URL holen
      final publicUrl =
          SupabaseService.client.storage.from(bucket).getPublicUrl(uploaded);

      // Post in DB schreiben
      await SupabaseService.client.from(AppConstants.postsTable).insert({
        'user_id': currentUid,
        'type': type,
        'media_url': publicUrl,
        'caption': caption.trim(),
        'is_ea_content': isEAMarked,
        'report_status': 'none',
      });

      // Temp-Dateien aufräumen
      if (noExif.path != mediaPath) await noExif.delete();
      if (finalFile.path != mediaPath && finalFile.path != noExif.path) {
        await finalFile.delete();
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('Post erstellen fehlgeschlagen: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final postControllerProvider =
    StateNotifierProvider<PostNotifier, AsyncValue<void>>((ref) {
  return PostNotifier();
});
