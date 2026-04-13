import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// FFmpeg.wasm video compression — Web only.
/// Falls back to null (no compression) if ffmpeg.wasm is unavailable.
/// Requires COOP/COEP headers in web/index.html for SharedArrayBuffer support.
class FFmpegVideoCompressor {
  /// Compress video in browser using ffmpeg.wasm.
  ///
  /// Input: raw video bytes + original filename (e.g. "video.mp4")
  /// Output: H.264 720p MP4 bytes (CRF 28, AAC 128k, faststart)
  /// Progress: optional callback with 0-100 percent
  ///
  /// Returns null if browser doesn't support ffmpeg.wasm
  /// (SharedArrayBuffer required → crossOriginIsolated must be true).
  static Future<Uint8List?> compressVideo(
    Uint8List videoBytes,
    String fileName, {
    void Function(int progress)? onProgress,
  }) async {
    if (!kIsWeb) return null;

    try {
      final supported = await isSupported();
      if (!supported) return null;

      return await _compressInBrowser(videoBytes, fileName, onProgress);
    } catch (e, st) {
      debugPrint('[FFmpegVideoCompressor] Error: $e\n$st');
      return null;
    }
  }

  /// Check if this browser supports ffmpeg.wasm.
  /// Requires: crossOriginIsolated (COOP/COEP headers) + our JS wrapper loaded.
  static Future<bool> isSupported() async {
    if (!kIsWeb) return false;
    try {
      if (!web.window.crossOriginIsolated) return false;
      return _hasJsFunction('loadFFmpeg');
    } catch (e) {
      debugPrint('[FFmpegVideoCompressor] Support check failed: $e');
      return false;
    }
  }

  /// TikTok-recommended compression preset.
  static const preset = _FFmpegPreset.tiktok;
}

// ─── Internal helpers ────────────────────────────────────────────────────────

bool _hasJsFunction(String name) {
  try {
    final win = web.window as dynamic;
    return (win.hasOwnProperty(name) as bool?) ?? false;
  } catch (_) {
    return false;
  }
}

dynamic _getJsFunction(String name) {
  try {
    final win = web.window as dynamic;
    final has = (win.hasOwnProperty(name) as bool?) ?? false;
    return has ? win[name] : null;
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _compressInBrowser(
  Uint8List videoBytes,
  String fileName,
  void Function(int)? onProgress,
) async {
  try {
    final compressFn = _getJsFunction('compressVideoWithFFmpeg');
    if (compressFn == null) {
      debugPrint('[FFmpegVideoCompressor] compressVideoWithFFmpeg not found');
      return null;
    }

    // Convert Dart Uint8List to JS Uint8Array using toJS extension
    final jsInput = videoBytes.toJS;

    // Call the JS function — returns Promise<Uint8Array>
    // ignore: avoid_dynamic_calls
    final jsResult = await _jsPromiseToDart(compressFn.call(jsInput, fileName));

    if (jsResult == null) return null;
    return _jsUint8ToDart(jsResult);
  } catch (e) {
    debugPrint('[FFmpegVideoCompressor] JS compression failed: $e');
    return null;
  }
}

/// Convert a JS Promise to a Dart Future.
Future<dynamic> _jsPromiseToDart(dynamic jsPromise) {
  final completer = Completer<dynamic>();
  // ignore: avoid_dynamic_calls
  jsPromise.then((v) => completer.complete(v)).catchError(
    (e) => completer.completeError(e),
  );
  return completer.future;
}

/// Convert JavaScript Uint8Array to Dart Uint8List.
Uint8List? _jsUint8ToDart(dynamic jsArray) {
  try {
    final len = (jsArray as dynamic).length as int;
    final result = Uint8List(len);
    for (var i = 0; i < len; i++) {
      result[i] = (jsArray as dynamic)[i] as int;
    }
    return result;
  } catch (e) {
    debugPrint('[FFmpegVideoCompressor] JS→Dart conversion error: $e');
    return null;
  }
}

/// Compression preset for ffmpeg command.
class _FFmpegPreset {
  final int videoBitrateKbps;
  final int audioBitrateKbps;
  final int resolutionHeight;
  final int crf;
  final String preset;

  const _FFmpegPreset({
    required this.videoBitrateKbps,
    required this.audioBitrateKbps,
    required this.resolutionHeight,
    required this.crf,
    required this.preset,
  });

  static const tiktok = _FFmpegPreset(
    videoBitrateKbps: 1500,
    audioBitrateKbps: 128,
    resolutionHeight: 720,
    crf: 28,
    preset: 'fast',
  );
}