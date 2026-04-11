import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum CaptureMode { photo, video }

class CameraState {
  final CaptureMode mode;
  final bool isRecording;
  final int recordingSeconds;
  final String flashMode;
  final bool isFrontCamera;
  final bool isInitialized;
  final String? error;
  final String? capturedFilePath;
  final int cameraCount;

  const CameraState({
    this.mode = CaptureMode.photo,
    this.isRecording = false,
    this.recordingSeconds = 0,
    this.flashMode = 'off',
    this.isFrontCamera = false,
    this.isInitialized = false,
    this.error,
    this.capturedFilePath,
    this.cameraCount = 0,
  });

  CameraState copyWith({
    CaptureMode? mode,
    bool? isRecording,
    int? recordingSeconds,
    String? flashMode,
    bool? isFrontCamera,
    bool? isInitialized,
    String? error,
    String? capturedFilePath,
    int? cameraCount,
  }) {
    return CameraState(
      mode: mode ?? this.mode,
      isRecording: isRecording ?? this.isRecording,
      recordingSeconds: recordingSeconds ?? this.recordingSeconds,
      flashMode: flashMode ?? this.flashMode,
      isFrontCamera: isFrontCamera ?? this.isFrontCamera,
      isInitialized: isInitialized ?? this.isInitialized,
      error: error ?? this.error,
      capturedFilePath: capturedFilePath ?? this.capturedFilePath,
      cameraCount: cameraCount ?? this.cameraCount,
    );
  }
}

class CameraNotifier extends StateNotifier<CameraState> {
  CameraNotifier() : super(const CameraState());

  List<CameraDescription> _cameras = [];
  int _currentCameraIndex = 0;
  CameraController? _controller;
  Timer? _recordingTimer;

  List<CameraDescription> get cameras => _cameras;
  CameraController? get controller => _controller;

  Future<void> init() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        state = state.copyWith(error: 'Keine Kamera gefunden');
        return;
      }
      _currentCameraIndex = 0;
      await _initController();
    } catch (e) {
      state = state.copyWith(error: 'Kamera-Initialisierung fehlgeschlagen: $e');
    }
  }

  Future<void> _initController() async {
    await _controller?.dispose();
    _controller = null;

    final frontCameras = _cameras.where((c) => c.lensDirection == CameraLensDirection.front).toList();
    final backCameras = _cameras.where((c) => c.lensDirection == CameraLensDirection.back).toList();

    List<CameraDescription> candidates;
    if (state.isFrontCamera && frontCameras.isNotEmpty) {
      candidates = frontCameras;
    } else if (!state.isFrontCamera && backCameras.isNotEmpty) {
      candidates = backCameras;
    } else {
      candidates = _cameras;
    }

    if (candidates.isEmpty) {
      state = state.copyWith(error: 'Keine passende Kamera');
      return;
    }

    // Find index in original list
    final selectedCam = candidates.first;
    _currentCameraIndex = _cameras.indexOf(selectedCam);

    _controller = CameraController(
      selectedCam,
      ResolutionPreset.high,
      enableAudio: true,
    );

    try {
      await _controller!.initialize();
      state = state.copyWith(
        isInitialized: true,
        error: null,
        capturedFilePath: null,
        cameraCount: _cameras.length,
      );
    } catch (e) {
      state = state.copyWith(error: 'Kamera-Initialisierung fehlgeschlagen: $e');
    }
  }

  Future<void> switchCamera() async {
    if (_cameras.length < 2) return;

    // Toggle front/back
    final newIsFront = !state.isFrontCamera;
    state = state.copyWith(isInitialized: false, isFrontCamera: newIsFront);
    await _initController();
  }

  void toggleFlash() {
    final modes = ['auto', 'off', 'always'];
    final idx = (modes.indexOf(state.flashMode) + 1) % modes.length;
    final newMode = modes[idx];
    state = state.copyWith(flashMode: newMode);

    final fm = _flashModeFromString(newMode);
    _controller?.setFlashMode(fm);
  }

  void setMode(CaptureMode mode) {
    state = state.copyWith(mode: mode);
  }

  Future<String?> takePicture() async {
    if (_controller == null || !state.isInitialized) return null;
    try {
      final file = await _controller!.takePicture();
      state = state.copyWith(capturedFilePath: file.path);
      return file.path;
    } catch (e) {
      state = state.copyWith(error: 'Foto aufnahme fehlgeschlagen: $e');
      return null;
    }
  }

  Future<void> startRecording() async {
    if (_controller == null || !state.isInitialized) return;
    try {
      await _controller!.startVideoRecording();
      state = state.copyWith(isRecording: true, recordingSeconds: 0);
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (state.recordingSeconds >= 60) {
          stopRecording();
        } else {
          state = state.copyWith(recordingSeconds: state.recordingSeconds + 1);
        }
      });
    } catch (e) {
      state = state.copyWith(error: 'Video aufnahme fehlgeschlagen: $e');
    }
  }

  Future<String?> stopRecording() async {
    _recordingTimer?.cancel();
    _recordingTimer = null;
    if (_controller == null) return null;
    try {
      final file = await _controller!.stopVideoRecording();
      state = state.copyWith(isRecording: false, capturedFilePath: file.path);
      return file.path;
    } catch (e) {
      state = state.copyWith(isRecording: false, error: 'Video stop fehlgeschlagen: $e');
      return null;
    }
  }

  void clearCapture() {
    state = state.copyWith(capturedFilePath: null);
  }

  FlashMode _flashModeFromString(String mode) {
    switch (mode) {
      case 'auto':
        return FlashMode.auto;
      case 'always':
        return FlashMode.always;
      default:
        return FlashMode.off;
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }
}

final cameraControllerProvider = StateNotifierProvider<CameraNotifier, CameraState>((ref) {
  final notifier = CameraNotifier();
  ref.onDispose(() => notifier.dispose());
  return notifier;
});
