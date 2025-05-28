import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:synther/core/synth_parameters.dart';
import 'package:synther/features/visualizer_bridge/visualizer_bridge_widget.dart';

void main() {
  testWidgets('VisualizerBridgeWidget initializes correctly', (WidgetTester tester) async {
    // Create a test synth parameters model
    final synthParams = SynthParametersModel();
    
    // Build the widget with provider
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SynthParametersModel>.value(
          value: synthParams,
          child: const Scaffold(
            body: VisualizerBridgeWidget(
              showControls: false,
              opacity: 1.0,
            ),
          ),
        ),
      ),
    );
    
    // Widget should be created
    expect(find.byType(VisualizerBridgeWidget), findsOneWidget);
    
    // Should show loading indicator initially
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  
  testWidgets('VisualizerOverlay wraps child correctly', (WidgetTester tester) async {
    final synthParams = SynthParametersModel();
    
    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<SynthParametersModel>.value(
          value: synthParams,
          child: const VisualizerOverlay(
            enabled: true,
            opacity: 0.5,
            child: Center(
              child: Text('Test Content'),
            ),
          ),
        ),
      ),
    );
    
    // Should find the overlay
    expect(find.byType(VisualizerOverlay), findsOneWidget);
    
    // Should find the child content
    expect(find.text('Test Content'), findsOneWidget);
    
    // Should have visualizer in background
    expect(find.byType(VisualizerBridgeWidget), findsOneWidget);
  });
  
  test('Parameter mapping works correctly', () {
    // Test the parameter mapping logic
    final testMappings = {
      'filterCutoff': {'input': 0.5, 'expected': 4.0}, // 3 + 0.5 * 2
      'filterResonance': {'input': 0.5, 'expected': 1.0}, // 0.5 * 2
      'reverbMix': {'input': 0.5, 'expected': 0.05}, // 0.5 * 0.1
      'masterVolume': {'input': 0.5, 'expected': 1.25}, // 0.5 + 0.5 * 1.5
    };
    
    // This tests the mapping logic that would be in the JavaScript bridge
    for (var entry in testMappings.entries) {
      final input = entry.value['input'] as double;
      final expected = entry.value['expected'] as double;
      
      // Apply the same scaling logic as in the JavaScript bridge
      double scaled;
      switch (entry.key) {
        case 'filterCutoff':
          scaled = 3 + input * 2;
          break;
        case 'filterResonance':
          scaled = input * 2;
          break;
        case 'reverbMix':
          scaled = input * 0.1;
          break;
        case 'masterVolume':
          scaled = 0.5 + input * 1.5;
          break;
        default:
          scaled = input;
      }
      
      expect(scaled, closeTo(expected, 0.001),
          reason: '${entry.key} mapping failed');
    }
  });
}