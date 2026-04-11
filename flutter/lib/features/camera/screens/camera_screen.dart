import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/camera_controller.dart';
import '../widgets/mode_toggle.dart';
import '../widgets/recording_indicator.dart';
import 'photo_review_screen.dart';
import 'video_review_screen.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({super.key});

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(cameraControllerProvider.notifier).init();
    });
  }

  Future<void> _onCaptureTap() async {
    final notifier = ref.read(cameraControllerProvider.notifier);
    final state = ref.read(cameraControllerProvider);

    if (state.mode == CaptureMode.photo) {
      final path = await notifier.takePicture();
      if (path != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PhotoReviewScreen(filePath: path),
          ),
        );
      }
    } else {
      if (state.isRecording) {
        final path = await notifier.stopRecording();
        if (path != null && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => VideoReviewScreen(filePath: path),
            ),
          );
        }
      } else {
        await notifier.startRecording();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cameraControllerProvider);
    final notifier = ref.read(cameraControllerProvider.notifier);
    final controller = notifier.controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Kamera-Vorschau
          if (state.isInitialized && controller != null)
            CameraPreview(controller)
          else if (state.error != null)
            Center(
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Obere Leiste
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // X-Button
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                // Flash + Kamera-Wechsel
                Row(
                  children: [
                    if (state.isInitialized)
                      IconButton(
                        icon: Icon(
                          _flashIcon(state.flashMode),
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () => notifier.toggleFlash(),
                      ),
                    if (state.cameraCount > 1)
                      IconButton(
                        icon: const Icon(
                          Icons.flip_camera_ios,
                          color: Colors.white,
                          size: 26,
                        ),
                        onPressed: () => notifier.switchCamera(),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Recording Indicator
          if (state.isRecording)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 0,
              right: 0,
              child: Center(
                child: RecordingIndicator(seconds: state.recordingSeconds),
              ),
            ),

          // Untere Leiste
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                bottom: MediaQuery.of(context).padding.bottom + 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black87],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Warnung: Kein Galerie-Upload
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt, color: Colors.red, size: 14),
                        SizedBox(width: 6),
                        Text(
                          'Nur Aufnahme — kein Galerie-Upload',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Mode-Toggle links
                      ModeToggle(
                        mode: state.mode,
                        onChange: (m) => notifier.setMode(m),
                      ),
                      // Aufnahme-Button mittig
                      _CaptureButton(
                        isRecording: state.isRecording,
                        isPhoto: state.mode == CaptureMode.photo,
                        onTap: state.isInitialized ? _onCaptureTap : null,
                      ),
                      // Platzhalter rechts (für Symmetrie)
                      const SizedBox(width: 80),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _flashIcon(String mode) {
    switch (mode) {
      case 'auto':
        return Icons.flash_auto;
      case 'always':
        return Icons.flash_on;
      default:
        return Icons.flash_off;
    }
  }
}

class _CaptureButton extends StatelessWidget {
  final bool isRecording;
  final bool isPhoto;
  final VoidCallback? onTap;

  const _CaptureButton({
    required this.isRecording,
    required this.isPhoto,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 4,
          ),
        ),
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isRecording ? 32 : 58,
            height: isRecording ? 32 : 58,
            decoration: BoxDecoration(
              color: isRecording ? Colors.red : Colors.white,
              borderRadius: isRecording ? BorderRadius.circular(8) : null,
              shape: isRecording ? BoxShape.rectangle : BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
