import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class MediaCompressor {
  /// Compresses an image file bytes for upload.
  /// Works on ALL platforms (web + native).
  /// - maxDimension: longest side in pixels (default 1080)
  /// - quality: 0-100 JPEG quality (default 82)
  /// Returns compressed bytes, strips EXIF automatically.
  static Future<Uint8List?> compressImageBytes(
    Uint8List bytes, {
    int maxDimension = 1080,
    int quality = 82,
  }) async {
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

    final jpeg = img.encodeJpg(resized, quality: quality);
    return Uint8List.fromList(jpeg);
  }
}
