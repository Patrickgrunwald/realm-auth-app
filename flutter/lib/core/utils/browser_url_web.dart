import 'dart:js_interop';
import 'package:flutter/foundation.dart';

/// Liest window.location.href inkl. Hash-Fragment (nur Web).
String getBrowserUrl() {
  if (!kIsWeb) return '';
  try {
    return (globalContext as dynamic).location?.href as String? ?? '';
  } catch (_) {
    return '';
  }
}
