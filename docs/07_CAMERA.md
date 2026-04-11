# 07 — Kamera & Medien-Aufnahme

## Kern-Regel

> **Galerie-Upload ist VERBOTEN.** Medien werden IMMER über die interne Kamera aufgenommen.

## Kamera-Screen

```
┌────────────────────────────────┐
│ [X]              [⚡] [⟲]    │  ← Schließen, Blitz, Kamera-Wechsel
│                                │
│                                │
│                                │
│         [VORSCHAU]              │  ← Live Kamera-Bild
│                                │
│                                │
│                                │
│   [FOTO]      ●      [VIDEO]   │  ← Modus-Toggle (Foto/Video)
│                                │
│  ─────────────────────────────  │
│  [GALERIE-ICON: DEAKTIVIERT]   │  ← Deutlich durchgestrichen/ausgegraut
└────────────────────────────────┘
```

**Der Galerie-Button ist NICHT vorhanden oder fest deaktiviert.**

## Kamera-Initialisierung

```dart
// camera_service.dart
class CameraService {
  List<CameraDescription> cameras = [];

  Future<void> initializeCameras() async {
    cameras = await availableCameras();
  }

  CameraController? controller;

  Future<void> initController(CameraDescription camera) async {
    controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: true,
    );
    await controller!.initialize();
  }
}
```

## Foto aufnehmen

```dart
// Kamera-Screen
Future<void> takePicture() async {
  final file = await controller.takePicture();
  
  // EXIF strippen
  final strippedFile = await ExifStripper.stripExif(file.path);
  
  // Komprimieren: < 500KB, max 1080px, 80% Qualität
  final compressed = await ImageCompress.compressAndGetFile(
    strippedFile.path,
    quality: 80,
    minWidth: 1080,
    minHeight: 1080,
    format: CompressFormat.jpeg,
  );
  
  // → Weiter zu create_post_screen.dart
  Get.to(CreatePostScreen(mediaFile: compressed));
}
```

## Video aufnehmen

```dart
// Video: max 60 Sekunden
bool isRecording = false;
int recordingSeconds = 0;
Timer? recordingTimer;

Future<void> toggleRecording() async {
  if (isRecording) {
    await controller.stopVideoRecording();
    recordingTimer?.cancel();
  } else {
    await controller.startVideoRecording();
    isRecording = true;
    recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      recordingSeconds++;
      if (recordingSeconds >= 60) {
        stopRecording(); // Auto-Stop bei 60s
      }
    });
  }
}
```

## Video-Kompression (nach Aufnahme)

```dart
// compression.dart
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

Future<File?> compressVideo(File inputFile) async {
  // Ziel: < 5MB, 720p, H.264, 30fps
  final outputPath = '${inputFile.path}_compressed.mp4';
  
  final command = '-i ${inputFile.path} '
    '-vcodec libx264 '
    '-crf 28 '           // Qualität (23-28 gut für Social)
    '-vf "scale=-2:720" ' // 720p Höhe, Breite behalten
    '-r 30 '             // 30fps
    '-preset fast '      // Schnellere Kompression
    '-acodec aac '
    '-b:a 128k '
    '-y $outputPath';
  
  final session = await FFmpegKit.execute(command);
  final returnCode = await session.getReturnCode();
  
  if (ReturnCode.isSuccess(returnCode)) {
    return File(outputPath);
  } else {
    return null;
  }
}
```

## EXIF-Stripping

```dart
// exif_stripper.dart
import 'dart:io';
import 'dart:typed_data';

Future<File> stripExif(String filePath) async {
  final file = File(filePath);
  final bytes = await file.readAsBytes();
  
  // Einfach: JPEG-Marker neu schreiben (APP1/EXIF entfernen)
  // Alternativ: exif package nutzen
  
  final stripped = _removeExifFromJpeg(bytes);
  
  final strippedFile = File('${filePath}_noexif.jpg');
  await strippedFile.writeAsBytes(stripped);
  return strippedFile;
}
```

## Thumbnail für Videos generieren

```dart
// Video-Thumbnail mit ffmpeg
Future<File?> generateThumbnail(File videoFile) async {
  final outputPath = '${videoFile.path}_thumb.jpg';
  
  final command = '-i ${videoFile.path} '
    '-ss 00:00:01 '       // Erstes Frame nach 1s
    '-vframes 1 '
    '-vf "scale=400:-1" '
    '-y $outputPath';
  
  final session = await FFmpegKit.execute(command);
  if (ReturnCode.isSuccess(await session.getReturnCode())) {
    return File(outputPath);
  }
  return null;
}
```

## Kamera: Foto oder Video auswählen

```dart
// mode_toggle.dart
enum CaptureMode { photo, video }

Widget modeToggle(CaptureMode mode, Function(CaptureMode) onChange) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(30),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ModeButton(
          label: 'FOTO',
          isSelected: mode == CaptureMode.photo,
          onTap: () => onChange(CaptureMode.photo),
        ),
        _ModeButton(
          label: 'VIDEO',
          isSelected: mode == CaptureMode.video,
          onTap: () => onChange(CaptureMode.video),
        ),
      ],
    ),
  );
}
```

## Flash / Kamera-Wechsel

```dart
// Kamera-Controls
Row(
  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  children: [
    // Blitz
    IconButton(
      icon: Icon(Icons.flash_auto),
      onPressed: () => controller.setFlashMode(FlashMode.auto),
      // cycles: auto → on → off
    ),
    
    // Kamera wechseln
    IconButton(
      icon: Icon(Icons.flip_camera_ios),
      onPressed: () => _switchCamera(),
    ),
  ],
)
```

## Review-Screen (nach Aufnahme)

```
┌────────────────────────────────┐
│ [X]              [Weiter →]   │
│                                │
│        [FOTO/VIDEO]            │  ← Aufgenommenes Medium
│                                │
│                                │
│  [🔄 Erneut aufnehmen]         │  ← Links
└────────────────────────────────┘
```

---

## Nächste Docs

← [06 FEED](06_FEED.md)
→ [08 POSTS](08_POSTS.md)
