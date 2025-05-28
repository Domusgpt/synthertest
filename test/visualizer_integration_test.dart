import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synther/core/synth_parameters.dart';
import 'package:synther/features/visualizer_bridge/visualizer_bridge_widget.dart';
import 'package:synther/core/parameter_visualizer_bridge.dart';
import 'package:synther/design_system/layout/performance_mode_manager.dart';
import 'dart:async';

void main() {
  group('Visualizer Integration Tests', () {
    late SynthParametersModel params;
    late ParameterVisualizerBridge bridge;
    late PerformanceModeManager performanceManager;
    
    setUp(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      params = SynthParametersModel();
      bridge = ParameterVisualizerBridge();
      performanceManager = PerformanceModeManager();
    });
    
    tearDown(() {
      bridge.dispose();
      performanceManager.dispose();
    });
    
    test('Visualizer bridge initializes with default bindings', () {
      // Check default bindings exist
      expect(bridge.bindings.length, greaterThan(0));
      
      // Verify core parameter mappings
      expect(bridge.hasBinding('filterCutoff'), true);
      expect(bridge.hasBinding('filterResonance'), true);
      expect(bridge.hasBinding('volume'), true);
    });
    
    test('Parameter to visualizer mapping works correctly', () {
      // Create custom binding
      bridge.createBinding(
        flutterParam: 'attack',
        visualizerParam: 'rotationSpeed',
        type: BindingType.range,
        scale: 2.0,
      );
      
      // Update parameter
      bridge.updateFlutterParameter('attack', 0.5);
      
      // Check transformed value
      final visualizerValue = bridge.getVisualizerValue('rotationSpeed');
      expect(visualizerValue, 1.0); // 0.5 * 2.0 = 1.0
    });
    
    test('Binding types transform values correctly', () {
      // Test direct binding
      bridge.createBinding(
        flutterParam: 'volume',
        visualizerParam: 'brightness',
        type: BindingType.direct,
      );
      bridge.updateFlutterParameter('volume', 0.7);
      expect(bridge.getVisualizerValue('brightness'), 0.7);
      
      // Test inverse binding
      bridge.createBinding(
        flutterParam: 'decay',
        visualizerParam: 'speed',
        type: BindingType.inverse,
      );
      bridge.updateFlutterParameter('decay', 0.3);
      expect(bridge.getVisualizerValue('speed'), 0.7); // 1 - 0.3
      
      // Test threshold binding
      bridge.createBinding(
        flutterParam: 'distortionAmount',
        visualizerParam: 'glitchEffect',
        type: BindingType.threshold,
        scale: 0.5, // threshold
      );
      bridge.updateFlutterParameter('distortionAmount', 0.3);
      expect(bridge.getVisualizerValue('glitchEffect'), 0.0);
      
      bridge.updateFlutterParameter('distortionAmount', 0.7);
      expect(bridge.getVisualizerValue('glitchEffect'), 1.0);
    });
    
    testWidgets('Visualizer widget renders correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: params),
              ChangeNotifierProvider.value(value: bridge),
            ],
            child: Scaffold(
              body: Stack(
                children: [
                  VisualizerBridge(
                    webUrl: 'assets/visualizer/index-flutter.html',
                  ),
                  Container(
                    color: Colors.black.withOpacity(0.3),
                    child: Center(
                      child: Text(
                        'UI Overlay',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      
      // Verify visualizer widget exists
      expect(find.byType(VisualizerBridge), findsOneWidget);
      
      // Verify overlay renders on top
      expect(find.text('UI Overlay'), findsOneWidget);
    });
    
    test('Performance mode affects visualizer', () {
      // Test normal mode
      performanceManager.setMode(PerformanceMode.normal);
      expect(performanceManager.shouldShowVisualizer(), true);
      expect(performanceManager.getVisualizerOpacity(), 1.0);
      
      // Test minimal mode
      performanceManager.setMode(PerformanceMode.minimal);
      expect(performanceManager.shouldShowVisualizer(), true);
      expect(performanceManager.getVisualizerOpacity(), 0.7);
      
      // Test visualizer only mode
      performanceManager.setMode(PerformanceMode.visualizerOnly);
      expect(performanceManager.shouldShowVisualizer(), true);
      expect(performanceManager.getVisualizerOpacity(), 1.0);
    });
    
    test('Parameter activity tracking', () async {
      // Enable activity tracking
      bridge.enableActivityTracking();
      
      // Simulate parameter changes
      bridge.updateFlutterParameter('filterCutoff', 1000);
      bridge.updateFlutterParameter('filterCutoff', 1500);
      bridge.updateFlutterParameter('filterCutoff', 2000);
      
      // Check activity level
      final activity = bridge.getParameterActivity('filterCutoff');
      expect(activity, greaterThan(0));
      
      // Wait for decay
      await Future.delayed(Duration(seconds: 2));
      final decayedActivity = bridge.getParameterActivity('filterCutoff');
      expect(decayedActivity, lessThan(activity));
    });
    
    test('Visualizer parameter validation', () {
      // Test valid visualizer parameters
      expect(bridge.isVisualizerParameter('dimensionMorph'), true);
      expect(bridge.isVisualizerParameter('rotationX'), true);
      expect(bridge.isVisualizerParameter('colorHue'), true);
      expect(bridge.isVisualizerParameter('geometryComplexity'), true);
      
      // Test invalid parameters
      expect(bridge.isVisualizerParameter('invalidParam'), false);
      expect(bridge.isVisualizerParameter(''), false);
    });
    
    test('Batch parameter updates', () {
      final updates = {
        'filterCutoff': 2500.0,
        'filterResonance': 15.0,
        'attack': 0.1,
        'release': 0.8,
      };
      
      // Create bindings for all parameters
      updates.keys.forEach((param) {
        bridge.createBinding(
          flutterParam: param,
          visualizerParam: 'test_$param',
          type: BindingType.direct,
        );
      });
      
      // Batch update
      bridge.batchUpdateParameters(updates);
      
      // Verify all updates applied
      updates.forEach((param, value) {
        expect(bridge.getVisualizerValue('test_$param'), value);
      });
    });
    
    test('UI tinting based on parameters', () {
      // Test filter-based tinting
      bridge.updateFlutterParameter('filterCutoff', 4000); // High cutoff
      final highCutoffTint = bridge.getUITintColor();
      expect(highCutoffTint.blue, greaterThan(highCutoffTint.red));
      
      bridge.updateFlutterParameter('filterCutoff', 200); // Low cutoff
      final lowCutoffTint = bridge.getUITintColor();
      expect(lowCutoffTint.red, greaterThan(lowCutoffTint.blue));
      
      // Test resonance-based intensity
      bridge.updateFlutterParameter('filterResonance', 25); // High resonance
      final highResTint = bridge.getUITintColor();
      expect(highResTint.opacity, greaterThan(0.5));
    });
    
    test('Visualizer performance monitoring', () async {
      final stopwatch = Stopwatch()..start();
      
      // Simulate rapid parameter updates
      for (int i = 0; i < 1000; i++) {
        bridge.updateFlutterParameter('filterCutoff', 1000 + i);
        bridge.updateFlutterParameter('filterResonance', (i % 30).toDouble());
        bridge.updateFlutterParameter('volume', (i % 100) / 100.0);
      }
      
      stopwatch.stop();
      print('1000 visualizer updates took: ${stopwatch.elapsedMilliseconds}ms');
      
      // Should maintain 60fps (16ms per frame)
      expect(stopwatch.elapsedMilliseconds / 1000, lessThan(16));
      
      // Check if throttling is working
      expect(bridge.updateCount, lessThan(1000)); // Some updates should be throttled
    });
    
    test('Preset visualization mappings', () {
      // Load performance preset
      final performancePreset = {
        'filterCutoff': 'dimensionMorph',
        'filterResonance': 'rotationSpeed',
        'volume': 'brightness',
        'attack': 'particleDensity',
      };
      
      bridge.loadPresetMappings(performancePreset);
      
      // Verify mappings loaded
      performancePreset.forEach((flutter, viz) {
        expect(bridge.hasBinding(flutter), true);
        final binding = bridge.getBinding(flutter);
        expect(binding?.visualizerParam, viz);
      });
    });
  });
  
  group('Visualizer Error Handling', () {
    test('Handles invalid parameter ranges', () {
      final bridge = ParameterVisualizerBridge();
      
      // Test out of range values
      expect(() => bridge.updateFlutterParameter('volume', -1), returnsNormally);
      expect(() => bridge.updateFlutterParameter('volume', 2), returnsNormally);
      
      // Values should be clamped
      bridge.updateFlutterParameter('volume', -1);
      expect(bridge.getVisualizerValue('brightness'), 0.0);
      
      bridge.updateFlutterParameter('volume', 2);
      expect(bridge.getVisualizerValue('brightness'), 1.0);
    });
    
    test('Handles missing bindings gracefully', () {
      final bridge = ParameterVisualizerBridge();
      
      // Update parameter with no binding
      expect(() => bridge.updateFlutterParameter('unmappedParam', 0.5), returnsNormally);
      
      // Get value for non-existent binding
      expect(bridge.getVisualizerValue('unmappedViz'), null);
    });
  });
}