import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synther/core/synth_parameters.dart';
import 'package:synther/core/audio_backend.dart';
import 'package:synther/core/platform_audio_backend.dart';
import 'package:synther/features/xy_pad/xy_pad.dart';
import 'package:synther/features/keyboard/keyboard_widget.dart';
import 'package:synther/features/shared_controls/control_panel_widget.dart';
import 'package:synther/core/parameter_bridge.dart';
import 'dart:async';

void main() {
  group('Audio System Integration Tests', () {
    late SynthParametersModel params;
    late AudioBackend audioBackend;
    
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      params = SynthParametersModel();
      audioBackend = getAudioBackend();
    });
    
    tearDown(() async {
      await audioBackend.dispose();
    });
    
    test('Audio backend initializes correctly', () async {
      expect(audioBackend.initialize(), completes);
      
      // Test initial state
      expect(audioBackend.isInitialized, false);
      
      // Initialize
      await audioBackend.initialize();
      expect(audioBackend.isInitialized, true);
    });
    
    test('Parameter updates propagate to audio engine', () async {
      await audioBackend.initialize();
      
      // Test oscillator parameters
      params.setOscillatorType(0, 1); // Square wave
      await Future.delayed(Duration(milliseconds: 50));
      expect(params.getOscillatorType(0), 1);
      
      // Test filter parameters
      params.filterCutoff = 2000.0;
      await Future.delayed(Duration(milliseconds: 50));
      expect(params.filterCutoff, 2000.0);
      
      // Test envelope parameters
      params.attack = 0.5;
      params.decay = 0.3;
      params.sustain = 0.7;
      params.release = 1.0;
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(params.attack, 0.5);
      expect(params.decay, 0.3);
      expect(params.sustain, 0.7);
      expect(params.release, 1.0);
    });
    
    test('Note on/off functions work correctly', () async {
      await audioBackend.initialize();
      
      // Test note on
      audioBackend.noteOn(60, 100); // Middle C, velocity 100
      expect(() => audioBackend.noteOn(60, 100), returnsNormally);
      
      // Test multiple notes (polyphony)
      audioBackend.noteOn(64, 80); // E
      audioBackend.noteOn(67, 90); // G
      
      // Test note off
      audioBackend.noteOff(60);
      expect(() => audioBackend.noteOff(60), returnsNormally);
      
      // Test all notes off
      audioBackend.allNotesOff();
      expect(() => audioBackend.allNotesOff(), returnsNormally);
    });
    
    test('Effects parameters update correctly', () async {
      await audioBackend.initialize();
      
      // Test reverb
      params.reverbMix = 0.3;
      audioBackend.setParameter('reverbMix', 0.3);
      await Future.delayed(Duration(milliseconds: 50));
      expect(params.reverbMix, 0.3);
      
      // Test delay
      params.delayTime = 0.25;
      params.delayFeedback = 0.4;
      params.delayMix = 0.2;
      audioBackend.setParameter('delayTime', 0.25);
      audioBackend.setParameter('delayFeedback', 0.4);
      audioBackend.setParameter('delayMix', 0.2);
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(params.delayTime, 0.25);
      expect(params.delayFeedback, 0.4);
      expect(params.delayMix, 0.2);
      
      // Test distortion
      params.distortionAmount = 0.5;
      audioBackend.setParameter('distortionAmount', 0.5);
      await Future.delayed(Duration(milliseconds: 50));
      expect(params.distortionAmount, 0.5);
    });
    
    testWidgets('XY Pad controls audio parameters', (tester) async {
      await audioBackend.initialize();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: params,
            child: Scaffold(
              body: XYPad(
                onChanged: (x, y) {
                  params.filterCutoff = x * 4000;
                  params.filterResonance = y * 30;
                },
              ),
            ),
          ),
        ),
      );
      
      // Simulate drag on XY pad
      final center = tester.getCenter(find.byType(XYPad));
      await tester.dragFrom(center, Offset(100, -50));
      await tester.pumpAndSettle();
      
      // Verify parameters changed
      expect(params.filterCutoff, greaterThan(2000));
      expect(params.filterResonance, greaterThan(10));
    });
    
    testWidgets('Keyboard triggers notes correctly', (tester) async {
      await audioBackend.initialize();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: params,
            child: Scaffold(
              body: KeyboardWidget(
                audioBackend: audioBackend,
              ),
            ),
          ),
        ),
      );
      
      // Find middle C key
      final middleC = find.byKey(Key('key_60'));
      expect(middleC, findsOneWidget);
      
      // Press and release key
      await tester.press(middleC);
      await tester.pumpAndSettle();
      
      await tester.longPress(middleC);
      await tester.pumpAndSettle();
    });
    
    test('Parameter bridge synchronizes correctly', () async {
      await audioBackend.initialize();
      final bridge = ParameterBridge();
      
      // Test parameter mapping
      bridge.mapParameter('osc1Type', 'oscillator1Type');
      bridge.mapParameter('filterCutoff', 'filter_cutoff');
      
      // Update through bridge
      bridge.updateParameter('osc1Type', 2); // Triangle
      bridge.updateParameter('filterCutoff', 1500.0);
      
      await Future.delayed(Duration(milliseconds: 100));
      
      // Verify synchronization
      expect(bridge.getParameter('osc1Type'), 2);
      expect(bridge.getParameter('filterCutoff'), 1500.0);
    });
    
    test('Audio performance metrics', () async {
      await audioBackend.initialize();
      final stopwatch = Stopwatch()..start();
      
      // Stress test with rapid parameter changes
      for (int i = 0; i < 100; i++) {
        audioBackend.setParameter('filterCutoff', 500 + i * 20);
        audioBackend.setParameter('filterResonance', i % 30);
      }
      
      stopwatch.stop();
      print('100 parameter updates took: ${stopwatch.elapsedMilliseconds}ms');
      
      // Should complete in reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
      
      // Test polyphony stress
      stopwatch.reset();
      stopwatch.start();
      
      // Play 16 notes (full polyphony)
      for (int i = 0; i < 16; i++) {
        audioBackend.noteOn(48 + i, 80);
      }
      
      stopwatch.stop();
      print('16 note polyphony took: ${stopwatch.elapsedMilliseconds}ms');
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      
      // Clean up
      audioBackend.allNotesOff();
    });
    
    test('Granular synthesis parameters', () async {
      await audioBackend.initialize();
      
      // Test granular parameters
      params.grainSize = 50.0;
      params.grainOverlap = 0.7;
      params.grainPitch = 1.2;
      params.grainPosition = 0.5;
      params.grainSpread = 0.3;
      
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(params.grainSize, 50.0);
      expect(params.grainOverlap, 0.7);
      expect(params.grainPitch, 1.2);
      expect(params.grainPosition, 0.5);
      expect(params.grainSpread, 0.3);
    });
    
    test('Wavetable synthesis parameters', () async {
      await audioBackend.initialize();
      
      // Test wavetable selection
      params.wavetableIndex = 3;
      params.wavetablePosition = 0.6;
      
      await Future.delayed(Duration(milliseconds: 50));
      
      expect(params.wavetableIndex, 3);
      expect(params.wavetablePosition, 0.6);
    });
  });
  
  group('Audio Error Handling', () {
    test('Handles invalid parameter values gracefully', () async {
      final audioBackend = getAudioBackend();
      await audioBackend.initialize();
      
      // Test boundary values
      expect(() => audioBackend.setParameter('filterCutoff', -100), returnsNormally);
      expect(() => audioBackend.setParameter('filterCutoff', 30000), returnsNormally);
      expect(() => audioBackend.setParameter('volume', -1), returnsNormally);
      expect(() => audioBackend.setParameter('volume', 2), returnsNormally);
      
      // Test invalid parameter names
      expect(() => audioBackend.setParameter('invalidParam', 0.5), returnsNormally);
      
      await audioBackend.dispose();
    });
    
    test('Handles rapid note on/off', () async {
      final audioBackend = getAudioBackend();
      await audioBackend.initialize();
      
      // Rapid fire notes
      for (int i = 0; i < 50; i++) {
        audioBackend.noteOn(60 + (i % 12), 100);
        await Future.delayed(Duration(milliseconds: 10));
        audioBackend.noteOff(60 + (i % 12));
      }
      
      expect(() => audioBackend.allNotesOff(), returnsNormally);
      
      await audioBackend.dispose();
    });
  });
}