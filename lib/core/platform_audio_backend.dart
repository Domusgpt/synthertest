import 'package:flutter/foundation.dart';
import 'audio_backend.dart';
import 'audio_backend_desktop.dart';
// Conditional import - web_audio_backend only available on web
import 'audio_backend_stub.dart' if (dart.library.html) 'web_audio_backend.dart';

/// Factory function to get the correct audio backend for the current platform
AudioBackend createAudioBackend() {
  if (kIsWeb) {
    // Use web audio backend for web only
    return WebAudioBackend();
  } else {
    // Use professional desktop audio backend for all other platforms
    return DesktopAudioBackend();
  }
}