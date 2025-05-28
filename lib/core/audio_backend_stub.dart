import 'audio_backend.dart';
import 'synth_parameters.dart';

/// Stub audio backend for desktop platforms
/// Provides a silent backend that implements all methods but produces no audio
/// Used as fallback when native audio isn't available
class StubAudioBackend implements AudioBackend {
  bool _initialized = false;
  String? _lastErrorMessage;
  
  @override
  bool get isInitialized => _initialized;
  
  @override
  String? get lastError => _lastErrorMessage;
  
  @override
  Future<void> initialize() async {
    _initialized = true;
    print('StubAudioBackend: Initialized (silent mode)');
  }
  
  @override
  Future<void> dispose() async {
    _initialized = false;
    print('StubAudioBackend: Disposed');
  }
  
  @override
  void noteOn(int id, int note, double velocity) {
    if (!_initialized) return;
    print('StubAudioBackend: Note On - ID: $id, Note: $note, Velocity: $velocity');
  }
  
  @override
  void noteOff(int id) {
    if (!_initialized) return;
    print('StubAudioBackend: Note Off - ID: $id');
  }
  
  @override
  void setParameter(int parameterId, double value) {
    if (!_initialized) return;
    print('StubAudioBackend: Set Parameter - ID: $parameterId, Value: $value');
  }
  
  @override
  double getParameter(int parameterId) {
    if (!_initialized) return 0.0;
    return 0.0; // Return default value
  }
  
  @override
  void setScale(int scaleIndex, int rootNote) {
    print('StubAudioBackend: Set Scale - Index: $scaleIndex, Root: $rootNote');
  }
  
  @override
  int getCurrentScale() {
    return 0; // Chromatic scale
  }
  
  @override
  int loadGranularBuffer(List<double> audioData) {
    print('StubAudioBackend: Load Granular Buffer - ${audioData.length} samples');
    return 1; // Return dummy buffer ID
  }
  
  @override
  void shutdown() {
    dispose();
  }
  
  @override
  void updateParameters(SynthParametersModel parameters) {
    print('StubAudioBackend: Update Parameters');
    // Silent update - just log
  }
}

/// Alias for web compatibility
class WebAudioBackend extends StubAudioBackend {}