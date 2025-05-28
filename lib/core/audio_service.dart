import 'package:flutter/foundation.dart';
import 'audio_backend.dart';
import 'platform_audio_backend.dart';

/// Service to manage the audio backend
class AudioService {
  static AudioService? _instance;
  late final AudioBackend _backend;
  bool _isInitialized = false;
  
  // Private constructor
  AudioService._() {
    _backend = createAudioBackend();
  }
  
  // Singleton instance
  static AudioService get instance {
    _instance ??= AudioService._();
    return _instance!;
  }
  
  // Initialize the audio backend
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _backend.initialize();
      _isInitialized = true;
      debugPrint('Audio service initialized');
    } catch (e) {
      debugPrint('Error initializing audio service: $e');
      rethrow;
    }
  }
  
  // Proxy methods to the backend
  void noteOn(int id, int note, double velocity) {
    if (!_isInitialized) {
      debugPrint('Warning: Audio service not initialized');
      return;
    }
    _backend.noteOn(id, note, velocity);
  }
  
  void noteOff(int id) {
    if (!_isInitialized) {
      debugPrint('Warning: Audio service not initialized');
      return;
    }
    _backend.noteOff(id);
  }
  
  void setParameter(int parameterId, double value) {
    if (!_isInitialized) {
      debugPrint('Warning: Audio service not initialized');
      return;
    }
    _backend.setParameter(parameterId, value);
  }
  
  double getParameter(int parameterId) {
    if (!_isInitialized) {
      debugPrint('Warning: Audio service not initialized');
      return 0.0;
    }
    return _backend.getParameter(parameterId);
  }
  
  void setScale(int scaleType, int rootNote) {
    if (!_isInitialized) {
      debugPrint('Warning: Audio service not initialized');
      return;
    }
    _backend.setScale(scaleType, rootNote);
  }
  
  int getCurrentScale() {
    if (!_isInitialized) {
      debugPrint('Warning: Audio service not initialized');
      return 0;
    }
    return _backend.getCurrentScale();
  }
  
  int loadGranularBuffer(List<double> audioData) {
    if (!_isInitialized) {
      debugPrint('Warning: Audio service not initialized');
      return -1;
    }
    return _backend.loadGranularBuffer(audioData);
  }
  
  void dispose() {
    if (_isInitialized) {
      _backend.dispose();
      _isInitialized = false;
    }
  }
  
  bool get isInitialized => _isInitialized;
}