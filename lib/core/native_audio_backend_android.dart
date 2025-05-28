import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'audio_backend.dart';
import 'synth_parameters.dart';
import 'synth_engine_bindings.dart';

/// Android-specific implementation using Oboe for low-latency audio
class AndroidNativeAudioBackend implements AudioBackend {
  static const MethodChannel _channel = MethodChannel('synther/audio');
  
  SynthEngineBindings? _bindings;
  ffi.Pointer<ffi.Void>? _enginePtr;
  bool _isInitialized = false;
  bool _isPlaying = false;
  
  @override
  bool get isInitialized => _isInitialized;
  
  @override
  bool get isPlaying => _isPlaying;
  
  @override
  Future<bool> initialize() async {
    try {
      // Request audio permissions
      await _channel.invokeMethod('requestAudioPermissions');
      
      // Load the native library
      final library = ffi.DynamicLibrary.open('libsynthengine.so');
      _bindings = SynthEngineBindings(library);
      
      // Initialize the audio platform
      await _channel.invokeMethod('initializeAudio');
      
      // Create synth engine instance
      _enginePtr = _bindings!.createSynthEngine();
      if (_enginePtr == ffi.nullptr) {
        throw Exception('Failed to create synth engine');
      }
      
      // Initialize audio with Oboe
      final result = _bindings!.initializeAudio(_enginePtr!);
      if (result == 0) {
        throw Exception('Failed to initialize audio platform');
      }
      
      _isInitialized = true;
      print('Android native audio backend initialized successfully');
      return true;
      
    } catch (e) {
      print('Failed to initialize Android audio backend: $e');
      return false;
    }
  }
  
  @override
  Future<void> dispose() async {
    if (_isPlaying) {
      await stop();
    }
    
    if (_enginePtr != null && _bindings != null) {
      _bindings!.destroySynthEngine(_enginePtr!);
      _enginePtr = null;
    }
    
    _bindings = null;
    _isInitialized = false;
  }
  
  @override
  Future<bool> start() async {
    if (!_isInitialized || _bindings == null || _enginePtr == null) {
      print('Audio backend not initialized');
      return false;
    }
    
    try {
      // Start the audio stream
      final result = _bindings!.startAudio(_enginePtr!);
      if (result == 0) {
        throw Exception('Failed to start audio stream');
      }
      
      _isPlaying = true;
      print('Audio stream started');
      return true;
      
    } catch (e) {
      print('Failed to start audio: $e');
      return false;
    }
  }
  
  @override
  Future<bool> stop() async {
    if (!_isInitialized || _bindings == null || _enginePtr == null) {
      return true;
    }
    
    try {
      // Stop the audio stream
      final result = _bindings!.stopAudio(_enginePtr!);
      _isPlaying = false;
      print('Audio stream stopped');
      return result != 0;
      
    } catch (e) {
      print('Failed to stop audio: $e');
      return false;
    }
  }
  
  @override
  void noteOn(int note, double velocity) {
    if (!_isInitialized || _bindings == null || _enginePtr == null) return;
    
    try {
      _bindings!.noteOn(_enginePtr!, note, velocity);
    } catch (e) {
      print('Failed to send note on: $e');
    }
  }
  
  @override
  void noteOff(int note) {
    if (!_isInitialized || _bindings == null || _enginePtr == null) return;
    
    try {
      _bindings!.noteOff(_enginePtr!, note);
    } catch (e) {
      print('Failed to send note off: $e');
    }
  }
  
  @override
  void setParameter(String parameter, double value) {
    if (!_isInitialized || _bindings == null || _enginePtr == null) return;
    
    try {
      // Convert parameter name to C string
      final paramName = parameter.toNativeUtf8();
      _bindings!.setParameter(_enginePtr!, paramName.cast<ffi.Char>(), value);
      malloc.free(paramName);
    } catch (e) {
      print('Failed to set parameter $parameter: $e');
    }
  }
  
  @override
  void updateParameters(SynthParametersModel parameters) {
    if (!_isInitialized) return;
    
    // Update all parameters efficiently
    setParameter('masterVolume', parameters.masterVolume);
    setParameter('filterCutoff', parameters.filterCutoff);
    setParameter('filterResonance', parameters.filterResonance);
    setParameter('attackTime', parameters.attackTime);
    setParameter('decayTime', parameters.decayTime);
    setParameter('sustainLevel', parameters.sustainLevel);
    setParameter('releaseTime', parameters.releaseTime);
    setParameter('reverbMix', parameters.reverbMix);
    setParameter('delayMix', parameters.delayMix);
    setParameter('delayTime', parameters.delayTime);
    setParameter('delayFeedback', parameters.delayFeedback);
    
    // Update oscillator parameters
    for (int i = 0; i < parameters.oscillators.length; i++) {
      final osc = parameters.oscillators[i];
      setParameter('osc${i}_type', osc.type.index.toDouble());
      setParameter('osc${i}_volume', osc.volume);
      setParameter('osc${i}_detune', osc.detune);
      setParameter('osc${i}_phase', osc.phase);
    }
  }
  
  @override
  double getParameter(String parameter) {
    if (!_isInitialized || _bindings == null || _enginePtr == null) {
      return 0.0;
    }
    
    try {
      final paramName = parameter.toNativeUtf8();
      final result = _bindings!.getParameter(_enginePtr!, paramName.cast<ffi.Char>());
      malloc.free(paramName);
      return result;
    } catch (e) {
      print('Failed to get parameter $parameter: $e');
      return 0.0;
    }
  }
  
  /// Android-specific: Get current audio latency
  Future<double> getAudioLatency() async {
    try {
      final latency = await _channel.invokeMethod<double>('getAudioLatency');
      return latency ?? 0.0;
    } catch (e) {
      print('Failed to get audio latency: $e');
      return 0.0;
    }
  }
  
  /// Android-specific: Get buffer underrun count
  Future<int> getBufferUnderrunCount() async {
    try {
      final count = await _channel.invokeMethod<int>('getBufferUnderrunCount');
      return count ?? 0;
    } catch (e) {
      print('Failed to get buffer underrun count: $e');
      return 0;
    }
  }
  
  /// Android-specific: Request low-latency audio mode
  Future<bool> requestLowLatencyMode() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestLowLatencyMode');
      return result ?? false;
    } catch (e) {
      print('Failed to request low latency mode: $e');
      return false;
    }
  }
}