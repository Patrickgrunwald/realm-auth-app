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

      final isWebBlob = kIsWeb && mediaPath.startsWith('blob:');
      if (isWebBlob) debugPrint('[Post] Web blob detected: $mediaPath');

      // Step 1: Read bytes
      Uint8List fileBytes = await _readMediaBytes(mediaPath);

      // Step 2: EXIF stripping (photos)
      if (type == 'photo') {
        fileBytes = Uint8List.fromList(_stripExifFromBytes(fileBytes));
      }

      // Step 3: Compress media
      Uint8List bytesToUpload = fileBytes;
      File? tempNativeFile;
      String? compressedPath;

      if (type == 'photo') {
        // Compress photos on ALL platforms (web + native) using pure Dart
        final compressed = await ImageCompressor.compressImageBytes(fileBytes);
        if (compressed != null && compressed.length < fileBytes.length) {
          bytesToUpload = compressed;
          debugPrint('[ImageCompressor] Photo: ${fileBytes.length} → ${bytesToUpload.length} bytes');
        } else {
          bytesToUpload = fileBytes; // compression failed, use original
        }
      } else if (type == 'video' && !kIsWeb) {
        // Compress video on native (iOS/Android)
        tempNativeFile = await _bytesToTempFile(fileBytes, 'mp4');
        compressedPath = await VideoCompressor.compressVideo(tempNativeFile.path);
        if (compressedPath != null && compressedPath != tempNativeFile.path) {
          debugPrint('[VideoCompressor] Native: compressed $compressedPath');
        }
      } else if (type == 'video' && kIsWeb) {
        // Compress video on web using ffmpeg.wasm
        final compressed = await FFmpegVideoCompressor.compressVideo(
          fileBytes,
          'input.mp4',
        );
        if (compressed != null && compressed.length < fileBytes.length) {
          bytesToUpload = compressed;
          debugPrint('[FFmpegVideoCompressor] Web: ${fileBytes.length} → ${bytesToUpload.length} bytes');
        }
      }

      // Step 4: Upload
      final ext = type == 'photo' ? 'jpg' : 'mp4';
      final fileName = '$currentUid/${DateTime.now().millisecondsSinceEpoch}.$ext';
      final bucket = AppConstants.storagePostsBucket;

      // Use compressed bytes for upload (all platforms)
      final Uint8List uploadBytes = bytesToUpload;
      final uploaded = await SupabaseService.client.storage
          .from(bucket)
          .uploadBinary(fileName, uploadBytes);

      // Step 5: Get public URL
      final publicUrl =
          SupabaseService.client.storage.from(bucket).getPublicUrl(uploaded);

      // Step 6: Insert post record
      await SupabaseService.client.from(AppConstants.postsTable).insert({
        'user_id': currentUid,
        'type': type,
        'media_url': publicUrl,
        'caption': caption.trim(),
        'is_ea_content': isEAMarked,
        'report_status': 'none',
      });

      // Step 7: Cleanup temp files
      if (!kIsWeb) {
        try {
          if (tempNativeFile != null) await tempNativeFile.delete();
        } catch (_) {}
        try {
          if (compressedPath != null) await File(compressedPath).delete();
        } catch (_) {}
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      debugPrint('Post erstellen fehlgeschlagen: $e');
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  List<int> _stripExifFromBytes(List<int> bytes) {
    if (bytes.length < 2 || bytes[0] != 0xFF || bytes[1] != 0xD8) {
      return bytes;
    }
    final stripped = <int>[0xFF, 0xD8];
    var i = 2;
    while (i < bytes.length - 1) {
      if (bytes[i] != 0xFF) {
        while (i < bytes.length) { stripped.add(bytes[i]); i++; }
        break;
      }
      final marker = bytes[i + 1];
      if (marker == 0xD8 || marker == 0xD9) {
        stripped.add(bytes[i]); stripped.add(bytes[i + 1]); i += 2; continue;
      }
      if (marker == 0xE1) {
        if (i + 3 < bytes.length) {
          var len = (bytes[i + 2] << 8) | bytes[i + 3];
          if (i + 7 < bytes.length &&
              bytes[i + 4] == 0x45 && bytes[i + 5] == 0x78 &&
              bytes[i + 6] == 0x69 && bytes[i + 7] == 0x66) {
            i += 2 + len; continue;
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

  Future<Uint8List> _readMediaBytes(String mediaPath) async {
    if (kIsWeb && mediaPath.startsWith('blob:')) {
      final response = await http.get(Uri.parse(mediaPath));
      if (response.statusCode != 200) {
        throw Exception('Konnte Medien nicht laden: ${response.statusCode}');
      }
      return response.bodyBytes;
    }
    return File(mediaPath).readAsBytes();
  }

  Future<File> _bytesToTempFile(Uint8List bytes, String type) async {
    final ext = type == 'photo' ? 'jpg' : 'mp4';
    final file = File('${Directory.systemTemp.path}/upload_${DateTime.now().millisecondsSinceEpoch}.$ext');
    await file.writeAsBytes(bytes);
    return file;
  }
}

final postControllerProvider =
    StateNotifierProvider<PostNotifier, AsyncValue<void>>((ref) {
  return PostNotifier();
});