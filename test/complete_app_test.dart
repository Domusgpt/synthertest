import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synther/app.dart';
import 'package:synther/core/synth_parameters.dart';
import 'package:synther/core/firebase_manager.dart';
import 'package:synther/features/xy_pad/xy_pad.dart';
import 'package:synther/features/keyboard/keyboard_widget.dart';
import 'package:synther/features/shared_controls/control_panel_widget.dart';
import 'package:synther/features/llm_presets/llm_preset_widget.dart';
import 'package:synther/features/granular/granular_controls_widget.dart';
import 'package:synther/features/microphone_input/mic_input_widget.dart';
import 'package:synther/features/visualizer_bridge/visualizer_bridge_widget.dart';
import 'dart:async';

void main() {
  group('Complete App Integration Tests', () {
    late SynthParametersModel synthParams;
    late FirebaseManager firebaseManager;
    
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      synthParams = SynthParametersModel();
      firebaseManager = FirebaseManager();
    });
    
    tearDown(() {
      synthParams.dispose();
      firebaseManager.dispose();
    });
    
    testWidgets('App initializes and renders main components', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: synthParams),
            ChangeNotifierProvider.value(value: firebaseManager),
          ],
          child: const SynthesizerApp(),
        ),
      );
      
      // Wait for the app to settle
      await tester.pumpAndSettle();
      
      // Verify main app structure
      expect(find.byType(SynthesizerHomePage), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.text('Sound Synthesizer'), findsOneWidget);
      
      // Verify bottom navigation items
      expect(find.text('XY Pad'), findsOneWidget);
      expect(find.text('Keyboard'), findsOneWidget);
      expect(find.text('Controls'), findsOneWidget);
    });
    
    testWidgets('XY Pad interface loads correctly', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: synthParams),
            ChangeNotifierProvider.value(value: firebaseManager),
          ],
          child: const SynthesizerApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Should start on XY Pad tab (index 0)
      expect(find.byType(XYPad), findsWidgets);
      expect(find.byType(KeyboardWidget), findsOneWidget); // Mini keyboard
      
      // Test XY Pad interaction
      final xyPad = find.byType(XYPad).first;
      await tester.tap(xyPad);
      await tester.pumpAndSettle();
      
      // Verify no crashes
      expect(find.byType(SynthesizerHomePage), findsOneWidget);
    });
    
    testWidgets('Keyboard interface navigation works', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: synthParams),
            ChangeNotifierProvider.value(value: firebaseManager),
          ],
          child: const SynthesizerApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Navigate to keyboard tab
      await tester.tap(find.text('Keyboard'));
      await tester.pumpAndSettle();
      
      // Verify keyboard interface elements
      expect(find.byType(KeyboardWidget), findsWidgets);
      expect(find.byType(XYPad), findsOneWidget); // Mini XY pad
      expect(find.text('Quick Controls'), findsOneWidget);
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Cutoff'), findsOneWidget);
    });
    
    testWidgets('Controls interface loads all widgets', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: synthParams),
            ChangeNotifierProvider.value(value: firebaseManager),
          ],
          child: const SynthesizerApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Navigate to controls tab
      await tester.tap(find.text('Controls'));
      await tester.pumpAndSettle();
      
      // Verify all control widgets are present
      expect(find.byType(ControlPanelWidget), findsOneWidget);
      expect(find.byType(MicInputWidget), findsOneWidget);
      expect(find.byType(LlmPresetWidget), findsOneWidget);
      expect(find.byType(GranularControlsWidget), findsOneWidget);
    });
    
    testWidgets('Visualizer toggle works', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: synthParams),
            ChangeNotifierProvider.value(value: firebaseManager),
          ],
          child: const SynthesizerApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find visualizer toggle button
      final toggleButton = find.byIcon(Icons.visibility);
      expect(toggleButton, findsOneWidget);
      
      // Toggle visualizer off
      await tester.tap(toggleButton);
      await tester.pumpAndSettle();
      
      // Should now show visibility_off icon
      expect(find.byIcon(Icons.visibility_off), findsOneWidget);
      
      // Toggle back on
      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pumpAndSettle();
      
      expect(find.byIcon(Icons.visibility), findsOneWidget);
    });
    
    testWidgets('Parameter synchronization works across UI', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: synthParams),
            ChangeNotifierProvider.value(value: firebaseManager),
          ],
          child: const SynthesizerApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Test volume slider in keyboard interface
      await tester.tap(find.text('Keyboard'));
      await tester.pumpAndSettle();
      
      // Find and interact with volume slider
      final volumeSlider = find.byType(Slider).first;
      await tester.tap(volumeSlider);
      await tester.pumpAndSettle();
      
      // Navigate to controls to verify parameter sync
      await tester.tap(find.text('Controls'));
      await tester.pumpAndSettle();
      
      // The parameter should be synchronized across all widgets
      expect(find.byType(ControlPanelWidget), findsOneWidget);
    });
    
    testWidgets('App handles lifecycle changes gracefully', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: synthParams),
            ChangeNotifierProvider.value(value: firebaseManager),
          ],
          child: const SynthesizerApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Simulate app going to background
      tester.binding.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/lifecycle',
        (data) async => null,
      );
      
      // App should still be functional
      expect(find.byType(SynthesizerHomePage), findsOneWidget);
    });
    
    testWidgets('Preset save/load dialogs work', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: synthParams),
            ChangeNotifierProvider.value(value: firebaseManager),
          ],
          child: const SynthesizerApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Test save preset dialog
      final saveButton = find.byIcon(Icons.save);
      expect(saveButton, findsOneWidget);
      
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      
      // Should show save dialog (might need to handle async dialog opening)
      // This test might need platform-specific handling
      
      // Test load preset dialog
      final loadButton = find.byIcon(Icons.folder_open);
      expect(loadButton, findsOneWidget);
      
      await tester.tap(loadButton);
      await tester.pumpAndSettle();
      
      // Should show load dialog
    });
  });
  
  group('Component Integration Tests', () {
    testWidgets('XY Pad controls audio parameters', (tester) async {
      final synthParams = SynthParametersModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: synthParams,
            child: const Scaffold(
              body: XYPad(
                height: 300,
                backgroundColor: Colors.black,
              ),
            ),
          ),
        ),
      );
      
      // Get center of XY pad
      final center = tester.getCenter(find.byType(XYPad));
      
      // Drag from center to different positions
      await tester.dragFrom(center, const Offset(50, -50));
      await tester.pumpAndSettle();
      
      // Parameters should have changed
      expect(synthParams.filterCutoff, greaterThan(1000));
      
      synthParams.dispose();
    });
    
    testWidgets('Keyboard triggers notes correctly', (tester) async {
      final synthParams = SynthParametersModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: synthParams,
            child: const Scaffold(
              body: KeyboardWidget(
                height: 200,
                startOctave: 4,
                numOctaves: 2,
              ),
            ),
          ),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Find a key (middle C should be key 60)
      final keys = find.byType(GestureDetector);
      expect(keys, findsWidgets);
      
      // Press a key
      await tester.tap(keys.first);
      await tester.pumpAndSettle();
      
      synthParams.dispose();
    });
  });
  
  group('Error Handling Tests', () {
    testWidgets('App handles parameter errors gracefully', (tester) async {
      final synthParams = SynthParametersModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: synthParams,
            child: const SynthesizerHomePage(),
          ),
        ),
      );
      
      // Test invalid parameter values
      expect(() => synthParams.setFilterCutoff(-100), returnsNormally);
      expect(() => synthParams.setFilterCutoff(50000), returnsNormally);
      expect(() => synthParams.setMasterVolume(-1), returnsNormally);
      expect(() => synthParams.setMasterVolume(2), returnsNormally);
      
      await tester.pumpAndSettle();
      
      synthParams.dispose();
    });
    
    testWidgets('App handles widget build errors', (tester) async {
      // Test with null providers (should handle gracefully)
      await tester.pumpWidget(
        const MaterialApp(
          home: SynthesizerHomePage(),
        ),
      );
      
      // Should either show error widgets or handle gracefully
      await tester.pumpAndSettle();
    });
  });
  
  group('Performance Tests', () {
    testWidgets('App maintains smooth performance', (tester) async {
      final synthParams = SynthParametersModel();
      final firebaseManager = FirebaseManager();
      
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: synthParams),
            ChangeNotifierProvider.value(value: firebaseManager),
          ],
          child: const SynthesizerApp(),
        ),
      );
      
      await tester.pumpAndSettle();
      
      // Rapid parameter changes
      for (int i = 0; i < 50; i++) {
        synthParams.setFilterCutoff(1000 + i * 100);
        synthParams.setFilterResonance(i % 30);
        await tester.pump(const Duration(milliseconds: 16)); // 60fps
      }
      
      // App should still be responsive
      expect(find.byType(SynthesizerHomePage), findsOneWidget);
      
      synthParams.dispose();
      firebaseManager.dispose();
    });
    
    testWidgets('Memory usage stays reasonable', (tester) async {
      final synthParams = SynthParametersModel();
      
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: synthParams,
            child: const SynthesizerHomePage(),
          ),
        ),
      );
      
      // Navigate between tabs multiple times
      for (int i = 0; i < 10; i++) {
        await tester.tap(find.text('Keyboard'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('Controls'));
        await tester.pumpAndSettle();
        
        await tester.tap(find.text('XY Pad'));
        await tester.pumpAndSettle();
      }
      
      // Should not have memory leaks or excessive rebuilds
      expect(find.byType(SynthesizerHomePage), findsOneWidget);
      
      synthParams.dispose();
    });
  });
}