import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

/// Generates a JPEG thumbnail from a video at the 1-second mark.
/// On web, returns null (handled by Supabase auto-thumbnail or UI placeholder).
class VideoThumbnail {
  /// Generate a JPEG thumbnail from a video at the 1-second mark.
  /// Returns JPEG bytes, or null on web / if it fails.
  static Future<Uint8List?> generateThumbnail(String filePath) async {
    if (kIsWeb) return null;
    try {
      // quality: 1-100, position: milliseconds (-1 = auto/keyframe)
      final data = await VideoCompress.getByteThumbnail(
        filePath,
        quality: 50,
        position: 1000, // 1 second into video
      );
      return data;
    } catch (_) {
      return null;
    }
  }
}
