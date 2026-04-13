import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Browser-native image compression using Dart pure library.
/// Works on all platforms (web + native) — no native dependencies.
/// Used by post_controller.dart for photo pre-upload compression.
class ImageCompressor {
  /// Compress image bytes to JPEG.
  /// - maxDimension: longest side in pixels (default 1080)
  /// - quality: 0-100 JPEG quality (default 85)
  /// - strips EXIF automatically (decodeImage removes it)
  /// - target: <400KB for feed thumbnails
  static Future<Uint8List?> compressImageBytes(
    Uint8List bytes, {
    int maxDimension = 1080,
    int quality = 85,
  }) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      img.Image resized = image;
      if (image.width > maxDimension || image.height > maxDimension) {
        if (image.width > image.height) {
          resized = img.copyResize(image, width: maxDimension);
        } else {
          resized = img.copyResize(image, height: maxDimension);
        }
      }

      // Encode as JPEG (EXIF automatically stripped during decode→encode)
      final jpeg = img.encodeJpg(resized, quality: quality);
      return Uint8List.fromList(jpeg);
    } catch (e) {
      debugPrint('[ImageCompressor] Compression failed: $e');
      return null;
    }
  }

  /// Create a thumbnail from image bytes.
  /// Returns a square JPEG thumbnail (324x324px), ~30KB.
  static Future<Uint8List?> createThumbnail(
    Uint8List bytes, {
    int size = 324,
  }) async {
    try {
      final image = img.decodeImage(bytes);
      if (image == null) return null;

      // Square crop from center
      final cropSize = image.width < image.height ? image.width : image.height;
      final x = (image.width - cropSize) ~/ 2;
      final y = (image.height - cropSize) ~/ 2;
      final cropped = img.copyCrop(image, x: x, y: y, width: cropSize, height: cropSize);

      // Resize to thumbnail size
      final thumb = img.copyResize(cropped, width: size, height: size);

      final jpeg = img.encodeJpg(thumb, quality: 80);
      return Uint8List.fromList(jpeg);
    } catch (e) {
      debugPrint('[ImageCompressor] Thumbnail creation failed: $e');
      return null;
    }
  }

  /// Check if bytes are already small enough (no compression needed).
  static bool needsCompression(Uint8List bytes, {int maxSizeKb = 500}) {
    return bytes.length > maxSizeKb * 1024;
  }
}