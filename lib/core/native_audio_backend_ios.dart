import 'dart:ffi' as ffi;
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/services.dart';
import 'audio_backend.dart';
import 'synth_parameters.dart';
import 'synth_engine_bindings.dart';

/// iOS-specific implementation using Core Audio for low-latency audio
class IOSNativeAudioBackend implements AudioBackend {
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
      // Request audio session permissions
      await _channel.invokeMethod('requestAudioPermissions');
      
      // Load the native framework
      final library = ffi.DynamicLibrary.open('SynthEngine.framework/SynthEngine');
      _bindings = SynthEngineBindings(library);
      
      // Initialize the audio session
      await _channel.invokeMethod('initializeAudioSession');
      
      // Create synth engine instance
      _enginePtr = _bindings!.createSynthEngine();
      if (_enginePtr == ffi.nullptr) {
        throw Exception('Failed to create synth engine');
      }
      
      // Initialize audio with Core Audio
      final result = _bindings!.initializeAudio(_enginePtr!);
      if (result == 0) {
        throw Exception('Failed to initialize audio platform');
      }
      
      _isInitialized = true;
      print('iOS native audio backend initialized successfully');
      return true;
      
    } catch (e) {
      print('Failed to initialize iOS audio backend: $e');
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
      // Activate audio session
      await _channel.invokeMethod('activateAudioSession');
      
      // Start the audio unit
      final result = _bindings!.startAudio(_enginePtr!);
      if (result == 0) {
        throw Exception('Failed to start audio unit');
      }
      
      _isPlaying = true;
      print('Audio unit started');
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
      // Stop the audio unit
      final result = _bindings!.stopAudio(_enginePtr!);
      
      // Deactivate audio session
      await _channel.invokeMethod('deactivateAudioSession');
      
      _isPlaying = false;
      print('Audio unit stopped');
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
  
  /// iOS-specific: Get current audio session latency
  Future<double> getAudioLatency() async {
    try {
      final latency = await _channel.invokeMethod<double>('getAudioLatency');
      return latency ?? 0.0;
    } catch (e) {
      print('Failed to get audio latency: $e');
      return 0.0;
    }
  }
  
  /// iOS-specific: Get buffer underrun count
  Future<int> getBufferUnderrunCount() async {
    try {
      final count = await _channel.invokeMethod<int>('getBufferUnderrunCount');
      return count ?? 0;
    } catch (e) {
      print('Failed to get buffer underrun count: $e');
      return 0;
    }
  }
  
  /// iOS-specific: Check if low-latency mode is available
  Future<bool> isLowLatencyModeAvailable() async {
    try {
      final available = await _channel.invokeMethod<bool>('isLowLatencyModeAvailable');
      return available ?? false;
    } catch (e) {
      print('Failed to check low latency mode availability: $e');
      return false;
    }
  }
  
  /// iOS-specific: Set audio session category for different use cases
  Future<bool> setAudioSessionCategory(String category) async {
    try {
      final result = await _channel.invokeMethod<bool>('setAudioSessionCategory', {
        'category': category,
      });
      return result ?? false;
    } catch (e) {
      print('Failed to set audio session category: $e');
      return false;
    }
  }
}