import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'synth_engine_bindings_generated.dart' as gen;

/// Simplified bindings wrapper
class SynthEngineBindings {
  late final gen.SynthEngineBindings _bindings;
  bool _isInitialized = false;
  String? _lastError;
  
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastError;
  
  Future<void> initialize() async {
    try {
      final lib = _loadLibrary();
      _bindings = gen.SynthEngineBindings(lib);
      
      final result = _bindings.InitializeSynthEngine(44100, 512, 0.75);
      if (result == 0) {
        _isInitialized = true;
      } else {
        throw Exception('Failed to initialize engine: $result');
      }
    } catch (e) {
      _lastError = e.toString();
      rethrow;
    }
  }
  
  void noteOn(int note, int velocity) {
    if (!_isInitialized) return;
    _bindings.ProcessMidiEvent(0x90, note, velocity);
  }
  
  void noteOff(int note) {
    if (!_isInitialized) return;
    _bindings.ProcessMidiEvent(0x80, note, 0);
  }
  
  void setParameter(int id, double value) {
    if (!_isInitialized) return;
    _bindings.SetParameter(id, value);
  }
  
  double getParameter(int id) {
    if (!_isInitialized) return 0.0;
    return _bindings.GetParameter(id);
  }
  
  void shutdown() {
    if (!_isInitialized) return;
    _bindings.ShutdownSynthEngine();
    _isInitialized = false;
  }
  
  int loadGranularBuffer(Float32List data) {
    // TODO: Implement when function is available
    return 0;
  }
  
  DynamicLibrary _loadLibrary() {
    if (Platform.isLinux) {
      try {
        // Try project directory first
        return DynamicLibrary.open('./libsynthengine.so');
      } catch (_) {
        // Try build directory
        return DynamicLibrary.open('./native/build/libsynthengine.so');
      }
    } else if (Platform.isWindows) {
      return DynamicLibrary.open('synthengine.dll');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libsynthengine.dylib');
    } else {
      throw UnsupportedError('Platform not supported');
    }
  }
}