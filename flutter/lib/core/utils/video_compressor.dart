import 'package:flutter/foundation.dart';
import 'package:video_compress/video_compress.dart';

/// Native video compression. Only works on iOS/Android.
/// On web, returns the original file path (no compression).
class VideoCompressor {
  /// Compress video for upload (native only).
  /// Returns the compressed file path, or original if already small or on web.
  static Future<String?> compressVideo(
    String filePath, {
    int maxDimension = 720,
    int maxDurationSeconds = 60,
    VideoQuality quality = VideoQuality.MediumQuality,
  }) async {
    if (kIsWeb) return filePath; // No native compression on web

    final info = await VideoCompress.compressVideo(
      filePath,
      quality: quality,
      deleteOrigin: false,
      includeAudio: true,
    );

    return info?.path ?? filePath;
  }

  /// Clean up thumbnail files created during compression
  static Future<void> cancelCompression() async {
    await VideoCompress.cancelCompression();
  }
}
