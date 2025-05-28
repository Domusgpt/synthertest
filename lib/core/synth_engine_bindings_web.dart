// Web implementation stub for synth engine bindings
// This is needed because FFI is not available on web

import 'dart:async';
import 'package:flutter/foundation.dart';

/// A stub implementation of synth engine bindings for web platform
class SynthEngineBindings {
  // Singleton instance
  static SynthEngineBindings? _instance;
  
  // Status
  bool _isInitialized = false;
  
  // Error handling
  String? _lastErrorMessage;
  
  // Private constructor
  SynthEngineBindings._();
  
  // Factory constructor
  factory SynthEngineBindings() {
    _instance ??= SynthEngineBindings._();
    return _instance!;
  }
  
  Future<void> initialize() async {
    _isInitialized = true;
    print('[Web] SynthEngineBindings stub initialized');
  }
  
  void shutdown() {
    _isInitialized = false;
    print('[Web] SynthEngineBindings stub shutdown');
  }
  
  void noteOn(int note, int velocity) {
    print('[Web] Note on: $note, velocity: $velocity');
  }
  
  void noteOff(int note) {
    print('[Web] Note off: $note');
  }
  
  void setParameter(int parameterId, double value) {
    print('[Web] Set parameter: $parameterId = $value');
  }
  
  double getParameter(int parameterId) {
    return 0.0;
  }
  
  void setScale(int scaleType, int rootNote) {
    print('[Web] Set scale: $scaleType, root: $rootNote');
  }
  
  int getCurrentScale() {
    return 0;
  }
  
  int loadGranularBuffer(List<double> audioData) {
    print('[Web] Granular buffer loading not supported on web');
    return -1;
  }
  
  void dispose() {
    shutdown();
  }
  
  bool get isInitialized => _isInitialized;
  String? get lastError => _lastErrorMessage;
}