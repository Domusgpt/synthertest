/// Abstract interface for audio backend implementation
/// This allows platform-specific implementations (native vs web)
abstract class AudioBackend {
  // Basic audio operations
  Future<void> initialize();
  void noteOn(int id, int note, double velocity);
  void noteOff(int id);
  void setParameter(int parameterId, double value);
  double getParameter(int parameterId);
  void setScale(int scaleIndex, int rootNote);
  int getCurrentScale();
  void dispose();
  
  // Properties
  bool get isInitialized;
  String? get lastError;
  
  // Granular synthesis operations
  int loadGranularBuffer(List<double> audioData);
  
  // Utility methods
  void shutdown() => dispose();
  
  // Factory method to get platform-specific implementation
  static AudioBackend getPlatformBackend() {
    // This will be implemented with conditional imports
    throw UnimplementedError('Use conditional imports to provide platform-specific implementation');
  }
}

// Parameter IDs (shared between platforms)
abstract class AudioParameters {
  static const int masterVolume = 0;
  static const int oscType = 1;
  static const int oscVolume = 2;
  static const int filterType = 10;
  static const int filterCutoff = 11;
  static const int filterResonance = 12;
  static const int adsrAttack = 20;
  static const int adsrDecay = 21;
  static const int adsrSustain = 22;
  static const int adsrRelease = 23;
  static const int delayTime = 30;
  static const int delayFeedback = 31;
  static const int delayMix = 32;
  static const int reverbSize = 40;
  static const int reverbDamping = 41;
  static const int reverbWet = 42;
  static const int wavetablePosition = 50;
  static const int granularGrainSize = 60;
  static const int granularOverlap = 61;
  static const int granularPosition = 62;
  static const int micVolume = 70;
}

// Oscillator types
abstract class OscillatorType {
  static const int sine = 0;
  static const int triangle = 1;
  static const int square = 2;
  static const int sawtooth = 3;
  static const int noise = 4;
  static const int pulse = 5;
  static const int wavetable = 6;
  static const int granular = 7;
}

// Filter types
abstract class FilterType {
  static const int lowpass = 0;
  static const int highpass = 1;
  static const int bandpass = 2;
  static const int notch = 3;
}

// Scale types
abstract class ScaleType {
  static const int chromatic = 0;
  static const int major = 1;
  static const int minor = 2;
  static const int pentatonic = 3;
  static const int blues = 4;
  static const int dorian = 5;
  static const int mixolydian = 6;
}