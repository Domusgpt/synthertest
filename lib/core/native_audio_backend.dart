import 'dart:io';
import 'audio_backend.dart';
import 'synth_parameters.dart';

// Platform-specific imports
import 'native_audio_backend_android.dart' if (dart.library.html) 'web_audio_backend.dart';
import 'native_audio_backend_ios.dart' if (dart.library.html) 'web_audio_backend.dart';
import 'web_audio_backend.dart' if (dart.library.io) 'native_audio_backend_android.dart';

/// Native audio backend implementation using platform-specific implementations
class NativeAudioBackend implements AudioBackend {
  late final AudioBackend _platformBackend;
  
  NativeAudioBackend() {
    // Choose platform-specific implementation
    if (Platform.isAndroid) {
      _platformBackend = AndroidNativeAudioBackend();
    } else if (Platform.isIOS) {
      _platformBackend = IOSNativeAudioBackend();
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // TODO: Implement desktop native backends
      throw UnsupportedError('Desktop native audio backends not yet implemented');
    } else {
      throw UnsupportedError('Platform not supported for native audio');
    }
  }
  
  @override
  bool get isInitialized => _platformBackend.isInitialized;
  
  @override
  bool get isPlaying => _platformBackend.isPlaying;
  
  @override
  Future<bool> initialize() => _platformBackend.initialize();
  
  @override
  Future<void> dispose() => _platformBackend.dispose();
  
  @override
  Future<bool> start() => _platformBackend.start();
  
  @override
  Future<bool> stop() => _platformBackend.stop();
  
  @override
  void noteOn(int note, double velocity) => _platformBackend.noteOn(note, velocity);
  
  @override
  void noteOff(int note) => _platformBackend.noteOff(note);
  
  @override
  void setParameter(String parameter, double value) => _platformBackend.setParameter(parameter, value);
  
  @override
  double getParameter(String parameter) => _platformBackend.getParameter(parameter);
  
  @override
  void updateParameters(SynthParametersModel parameters) => _platformBackend.updateParameters(parameters);
}

/// Factory function for conditional imports
AudioBackend createBackend() => NativeAudioBackend();