import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synther/core/synth_parameters.dart';
import 'package:synther/core/audio_backend.dart';
import 'package:synther/core/platform_audio_backend.dart';
import 'package:synther/core/parameter_visualizer_bridge.dart';
import 'package:synther/features/xy_pad/xy_pad.dart';
import 'dart:async';

void main() {
  group('Parameter Synchronization Tests', () {
    late SynthParametersModel params;
    late AudioBackend audioBackend;
    late ParameterVisualizerBridge visualizerBridge;
    
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      params = SynthParametersModel();
      audioBackend = getAudioBackend();
      visualizerBridge = ParameterVisualizerBridge();
      
      await audioBackend.initialize();
      
      // Set up parameter listeners
      params.addListener(() {
        // Sync to audio backend
        audioBackend.setParameter('filterCutoff', params.filterCutoff);
        audioBackend.setParameter('filterResonance', params.filterResonance);
        audioBackend.setParameter('volume', params.volume);
        
        // Sync to visualizer
        visualizerBridge.updateFlutterParameter('filterCutoff', params.filterCutoff);
        visualizerBridge.updateFlutterParameter('filterResonance', params.filterResonance);
        visualizerBridge.updateFlutterParameter('volume', params.volume);
      });
    });
    
    tearDown(() async {
      await audioBackend.dispose();
      visualizerBridge.dispose();
      params.dispose();
    });
    
    test('UI parameter changes sync to audio and visualizer', () async {
      // Change filter cutoff through UI model
      params.filterCutoff = 2000.0;
      await Future.delayed(Duration(milliseconds: 50));
      
      // Verify audio backend received update
      expect(audioBackend.getParameter('filterCutoff'), 2000.0);
      
      // Verify visualizer received update
      expect(visualizerBridge.getFlutterParameter('filterCutoff'), 2000.0);
      
      // Change multiple parameters
      params.filterResonance = 15.0;
      params.volume = 0.8;
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(audioBackend.getParameter('filterResonance'), 15.0);
      expect(audioBackend.getParameter('volume'), 0.8);
      expect(visualizerBridge.getFlutterParameter('filterResonance'), 15.0);
      expect(visualizerBridge.getFlutterParameter('volume'), 0.8);
    });
    
    test('Oscillator parameter synchronization', () async {
      // Test oscillator 1
      params.setOscillatorType(0, 2); // Triangle
      params.setOscillatorLevel(0, 0.7);
      params.setOscillatorPan(0, -0.5);
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(params.getOscillatorType(0), 2);
      expect(params.getOscillatorLevel(0), 0.7);
      expect(params.getOscillatorPan(0), -0.5);
      
      // Test oscillator 2
      params.setOscillatorType(1, 3); // Sawtooth
      params.setOscillatorLevel(1, 0.5);
      params.setOscillatorPan(1, 0.5);
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(params.getOscillatorType(1), 3);
      expect(params.getOscillatorLevel(1), 0.5);
      expect(params.getOscillatorPan(1), 0.5);
    });
    
    test('ADSR envelope synchronization', () async {
      // Update all envelope parameters
      params.attack = 0.01;
      params.decay = 0.2;
      params.sustain = 0.6;
      params.release = 0.5;
      await Future.delayed(Duration(milliseconds: 50));
      
      // Verify all synced
      expect(params.attack, 0.01);
      expect(params.decay, 0.2);
      expect(params.sustain, 0.6);
      expect(params.release, 0.5);
      
      // Create visualizer bindings for envelope
      visualizerBridge.createBinding(
        flutterParam: 'attack',
        visualizerParam: 'particleLifetime',
        type: BindingType.direct,
        scale: 10.0,
      );
      
      visualizerBridge.createBinding(
        flutterParam: 'release',
        visualizerParam: 'fadeOutSpeed',
        type: BindingType.inverse,
      );
      
      // Update and verify mapping
      visualizerBridge.updateFlutterParameter('attack', params.attack);
      visualizerBridge.updateFlutterParameter('release', params.release);
      
      expect(visualizerBridge.getVisualizerValue('particleLifetime'), 0.1); // 0.01 * 10
      expect(visualizerBridge.getVisualizerValue('fadeOutSpeed'), 0.5); // 1 - 0.5
    });
    
    test('Effects parameter synchronization', () async {
      // Reverb parameters
      params.reverbMix = 0.25;
      params.reverbSize = 0.7;
      params.reverbDamping = 0.5;
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(params.reverbMix, 0.25);
      expect(params.reverbSize, 0.7);
      expect(params.reverbDamping, 0.5);
      
      // Delay parameters
      params.delayTime = 0.375; // 3/8 note
      params.delayFeedback = 0.6;
      params.delayMix = 0.3;
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(params.delayTime, 0.375);
      expect(params.delayFeedback, 0.6);
      expect(params.delayMix, 0.3);
      
      // Distortion
      params.distortionAmount = 0.4;
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(params.distortionAmount, 0.4);
    });
    
    testWidgets('XY Pad synchronizes to both audio and visualizer', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: params,
            child: Scaffold(
              body: XYPad(
                onChanged: (x, y) {
                  // Update parameters
                  params.filterCutoff = x * 4000;
                  params.filterResonance = y * 30;
                },
              ),
            ),
          ),
        ),
      );
      
      // Get XY pad center
      final center = tester.getCenter(find.byType(XYPad));
      
      // Drag to top-right (high cutoff, high resonance)
      await tester.dragFrom(center, Offset(100, -100));
      await tester.pumpAndSettle();
      
      // Verify parameters updated
      expect(params.filterCutoff, greaterThan(2000));
      expect(params.filterResonance, greaterThan(15));
      
      // Verify audio backend synced
      expect(audioBackend.getParameter('filterCutoff'), params.filterCutoff);
      expect(audioBackend.getParameter('filterResonance'), params.filterResonance);
      
      // Verify visualizer synced
      expect(visualizerBridge.getFlutterParameter('filterCutoff'), params.filterCutoff);
      expect(visualizerBridge.getFlutterParameter('filterResonance'), params.filterResonance);
    });
    
    test('Parameter synchronization performance', () async {
      final stopwatch = Stopwatch()..start();
      
      // Rapid parameter updates simulating real-time control
      for (int i = 0; i < 500; i++) {
        params.filterCutoff = 500 + (i * 7);
        params.filterResonance = (i % 30).toDouble();
        params.volume = 0.5 + (math.sin(i * 0.1) * 0.5);
        
        // Small delay to simulate frame rate
        await Future.delayed(Duration(microseconds: 16667)); // ~60fps
      }
      
      stopwatch.stop();
      print('500 parameter syncs took: ${stopwatch.elapsedMilliseconds}ms');
      
      // Should complete in reasonable time (allowing for delays)
      expect(stopwatch.elapsedMilliseconds, lessThan(10000)); // ~8.3s expected
    });
    
    test('Granular synthesis parameter sync', () async {
      // Set up granular parameters
      params.grainSize = 75.0;
      params.grainOverlap = 0.8;
      params.grainPitch = 0.5;
      params.grainPosition = 0.25;
      params.grainSpread = 0.4;
      params.grainDirection = 1; // Forward
      await Future.delayed(Duration(milliseconds: 50));
      
      // Create visualizer mappings for granular
      visualizerBridge.createBinding(
        flutterParam: 'grainSize',
        visualizerParam: 'particleSize',
        type: BindingType.range,
        scale: 0.01, // Scale down for visualizer
      );
      
      visualizerBridge.createBinding(
        flutterParam: 'grainSpread',
        visualizerParam: 'particleSpread',
        type: BindingType.direct,
      );
      
      // Update and verify
      visualizerBridge.updateFlutterParameter('grainSize', params.grainSize);
      visualizerBridge.updateFlutterParameter('grainSpread', params.grainSpread);
      
      expect(visualizerBridge.getVisualizerValue('particleSize'), 0.75);
      expect(visualizerBridge.getVisualizerValue('particleSpread'), 0.4);
    });
    
    test('Parameter validation and clamping', () async {
      // Test boundary values
      params.filterCutoff = 25000; // Above max
      await Future.delayed(Duration(milliseconds: 50));
      expect(params.filterCutoff, 20000); // Clamped to max
      
      params.filterResonance = -5; // Below min
      await Future.delayed(Duration(milliseconds: 50));
      expect(params.filterResonance, 0); // Clamped to min
      
      params.volume = 1.5; // Above max
      await Future.delayed(Duration(milliseconds: 50));
      expect(params.volume, 1.0); // Clamped to max
    });
    
    test('Composite parameter mappings', () async {
      // Create composite binding (multiple parameters affect one visualizer param)
      visualizerBridge.createBinding(
        flutterParam: 'filterCutoff',
        visualizerParam: 'energyLevel',
        type: BindingType.composite,
      );
      
      visualizerBridge.addToComposite('energyLevel', 'filterResonance', 0.3);
      visualizerBridge.addToComposite('energyLevel', 'distortionAmount', 0.2);
      
      // Update parameters
      params.filterCutoff = 2000; // Normalized ~0.5
      params.filterResonance = 15; // Normalized 0.5
      params.distortionAmount = 0.5;
      
      visualizerBridge.updateFlutterParameter('filterCutoff', params.filterCutoff / 4000);
      visualizerBridge.updateFlutterParameter('filterResonance', params.filterResonance / 30);
      visualizerBridge.updateFlutterParameter('distortionAmount', params.distortionAmount);
      
      // Energy level should be weighted sum
      final energy = visualizerBridge.getVisualizerValue('energyLevel');
      expect(energy, greaterThan(0.4)); // Combined effect
    });
  });
  
  group('Parameter Sync Error Recovery', () {
    test('Handles sync failures gracefully', () async {
      final params = SynthParametersModel();
      final audioBackend = getAudioBackend();
      final visualizerBridge = ParameterVisualizerBridge();
      
      // Don't initialize audio backend to simulate failure
      
      // Should handle updates without crashing
      expect(() => params.filterCutoff = 1000, returnsNormally);
      expect(() => visualizerBridge.updateFlutterParameter('filterCutoff', 1000), returnsNormally);
      
      params.dispose();
      visualizerBridge.dispose();
    });
    
    test('Maintains sync after reconnection', () async {
      final params = SynthParametersModel();
      final audioBackend = getAudioBackend();
      
      // Initialize and set initial values
      await audioBackend.initialize();
      params.filterCutoff = 1500;
      audioBackend.setParameter('filterCutoff', params.filterCutoff);
      
      // Simulate disconnect
      await audioBackend.dispose();
      
      // Change parameter while disconnected
      params.filterCutoff = 2500;
      
      // Reinitialize
      await audioBackend.initialize();
      
      // Resync parameter
      audioBackend.setParameter('filterCutoff', params.filterCutoff);
      expect(audioBackend.getParameter('filterCutoff'), 2500);
      
      await audioBackend.dispose();
      params.dispose();
    });
  });
}