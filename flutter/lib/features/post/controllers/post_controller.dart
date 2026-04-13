import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/ffmpeg_video_compressor.dart';
import '../../../core/utils/image_compressor.dart';
import '../../../core/utils/video_compressor.dart';
import '../../../data/services/supabase_service.dart';

class PostNotifier extends StateNotifier<AsyncValue<void>> {
  PostNotifier() : super(const AsyncValue.data(null));

  /// Create a post:
  /// 1. Read media bytes (blob URL → http.get on web, File on native)
  /// 2. Strip EXIF (photos only)
  /// 3. Compress: ImageCompressor on all platforms; FFmpeg.wasm on web / VideoCompressor on native
  /// 4. Upload to Supabase Storage
  /// 5. Insert post record
  /// 6. Cleanup temp files
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

      // ── Step 1: Read bytes ──────────────────────────────────────────────
      debugPrint('[PostController] Step 1: reading bytes from $mediaPath');
      Uint8List fileBytes;

      if (kIsWeb && mediaPath.startsWith('blob:')) {
        final response = await http.get(Uri.parse(mediaPath));
        if (response.statusCode != 200) {
          throw Exception('Konnte Medien nicht laden: ${response.statusCode}');
        }
        fileBytes = response.bodyBytes;
        debugPrint('[PostController] Web blob → ${fileBytes.length} bytes');
      } else {
        fileBytes = await File(mediaPath).readAsBytes();
        debugPrint('[PostController] Native file → ${fileBytes.length} bytes');
      }

      // ── Step 2: EXIF stripping (photos) ─────────────────────────────────
      if (type == 'photo') {
        final stripped = _stripExifFromBytes(fileBytes);
        fileBytes = Uint8List.fromList(stripped);
        debugPrint('[PostController] EXIF stripped: ${fileBytes.length} bytes');
      }

      // ── Step 3: Compress ────────────────────────────────────────────────
      Uint8List bytesToUpload = fileBytes;
      File? tempNativeFile;
      String? compressedNativePath;

      if (type == 'photo') {
        // Photos: compress on ALL platforms (pure Dart ImageCompressor)
        debugPrint('[PostController] Step 3a: compressing photo (${fileBytes.length} bytes)...');
        final compressed = await ImageCompressor.compressImageBytes(fileBytes);
        if (compressed != null && compressed.length < fileBytes.length) {
          bytesToUpload = compressed;
          debugPrint('[ImageCompressor] Photo: ${fileBytes.length} → ${bytesToUpload.length} bytes');
        } else {
          bytesToUpload = fileBytes;
          debugPrint('[ImageCompressor] Photo: no compression benefit, using original');
        }
      } else if (type == 'video') {
        debugPrint('[PostController] Step 3b: compressing video...');
        if (kIsWeb) {
          // Web: use FFmpeg.wasm
          debugPrint('[PostController] Compressing video via FFmpeg.wasm...');
          final compressed = await FFmpegVideoCompressor.compressVideo(
            fileBytes,
            'input.mp4',
            onProgress: (p) {
              debugPrint('[FFmpeg] Progress: $p%');
            },
          );
          if (compressed != null && compressed.length < fileBytes.length) {
            bytesToUpload = compressed;
            debugPrint('[FFmpegVideoCompressor] Web: ${fileBytes.length} → ${bytesToUpload.length} bytes');
          } else {
            bytesToUpload = fileBytes;
            debugPrint('[FFmpegVideoCompressor] Web: no compression benefit');
          }
        } else {
          // Native: use VideoCompressor
          debugPrint('[PostController] Compressing video via native VideoCompressor...');
          tempNativeFile = await _bytesToTempFile(fileBytes, 'mp4');
          compressedNativePath = await VideoCompressor.compressVideo(tempNativeFile.path);
          if (compressedNativePath != null && compressedNativePath != tempNativeFile.path) {
            debugPrint('[VideoCompressor] Native: compressed to $compressedNativePath');
          }
        }
      }

      // ── Step 4: Upload ─────────────────────────────────────────────────
      debugPrint('[PostController] Step 4: uploading ${bytesToUpload.length} bytes...');
      final ext = type == 'photo' ? 'jpg' : 'mp4';
      final fileName = '$currentUid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bucket = AppConstants.storagePostsBucket;

      await SupabaseService.client.storage
          .from(bucket)
          .uploadBinary(fileName, bytesToUpload);

      // ── Step 5: Insert post record ─────────────────────────────────────
      debugPrint('[PostController] Step 5: inserting post record...');
      final publicUrl =
          SupabaseService.client.storage.from(bucket).getPublicUrl(fileName);

      await SupabaseService.client.from(AppConstants.postsTable).insert({
        'user_id': currentUid,
        'type': type,
        'media_url': publicUrl,
        'caption': caption.trim(),
        'is_ea_content': isEAMarked,
        'report_status': 'none',
      });

      // ── Step 6: Cleanup ────────────────────────────────────────────────
      if (!kIsWeb) {
        try {
          if (tempNativeFile != null) await tempNativeFile.delete();
        } catch (_) {}
        try {
          if (compressedNativePath != null) {
            await File(compressedNativePath).delete();
          }
        } catch (_) {}
      }

      debugPrint('[PostController] ✅ Post created successfully');
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('[PostController] ❌ Post creation failed: $e\n$st');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // ── Internal helpers ───────────────────────────────────────────────────────

  List<int> _stripExifFromBytes(List<int> bytes) {
    if (bytes.length < 2 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return bytes;
    }
    final stripped = <int>[0xFF, 0xD8];
    var i = 2;
    while (i < bytes.length - 1) {
      if (bytes[i] != 0xFF) {
        while (i < bytes.length) {
          stripped.add(bytes[i]);
          i++;
        }
        break;
      }
      final marker = bytes[i + 1];
      if (marker == 0xD8 || marker == 0xD9) {
        stripped.add(bytes[i]);
        stripped.add(bytes[i + 1]);
        i += 2;
        continue;
      }
      if (marker == 0xE1) {
        if (i + 3 < bytes.length) {
          var len = (bytes[i + 2] << 8) | bytes[i + 3];
          if (i + 7 < bytes.length &&
              bytes[i + 4] == 0x45 &&
              bytes[i + 5] == 0x78 &&
              bytes[i + 6] == 0x69 &&
              bytes[i + 7] == 0x66) {
            i += 2 + len;
            continue;
          }
        }
      }
      if (i + 3 < bytes.length) {
        var len = (bytes[i + 2] << 8) | bytes[i + 3];
        for (var j = 0; j < 2 + len && i + j < bytes.length; j++) {
          stripped.add(bytes[i + j]);
        }
        i += 2 + len;
      } else {
        break;
      }
    }
    return stripped;
  }

  Future<File> _bytesToTempFile(Uint8List bytes, String type) async {
    final ext = type == 'photo' ? 'jpg' : 'mp4';
    final file = File(
        '${Directory.systemTemp.path}/upload_${DateTime.now().millisecondsSinceEpoch}.$ext');
    await file.writeAsBytes(bytes);
    return file;
  }
}

final postControllerProvider =
    StateNotifierProvider<PostNotifier, AsyncValue<void>>((ref) {
  return PostNotifier();
});
