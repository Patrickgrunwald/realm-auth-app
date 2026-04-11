import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

/// Komprimiert ein Bild auf unter 500KB mit max 1080px.
/// Nutzt flutter_image_compress.
Future<File?> compressImage(File file) async {
  final result = await FlutterImageCompress.compressAndGetFile(
    file.absolute.path,       // input path
    '${file.path}_compressed.jpg',  // output path
    quality: 80,
    minWidth: 1080,
    minHeight: 1080,
    format: CompressFormat.jpeg,
  );
  if (result != null) {
    return File(result.path);
  }
  return null;
}

// TODO: Video-Kompression mit ffmpeg_kit_flutter
// Future<File?> compressVideo(File file) async {
//   // Nach Installation von ffmpeg_kit_flutter:
//   // ffmpeg -i input.mp4 -vcodec libx264 -crf 28 -vf "scale=-2:720"
//   //        -r 30 -preset fast -acodec aac -b:a 128k output.mp4
//   return file; // vorerst unkomprimiert
// }
