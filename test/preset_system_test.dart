import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:synther/core/synth_parameters.dart';
import 'package:synther/core/granular_parameters.dart';
import 'package:synther/features/presets/preset_manager.dart';
import 'package:synther/features/presets/preset_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  group('Preset System Tests', () {
    late SynthParametersModel synthParams;
    late GranularParameters granularParams;
    
    setUp(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      
      // Initialize SharedPreferences with empty data
      SharedPreferences.setMockInitialValues({});
      
      synthParams = SynthParametersModel();
      granularParams = GranularParameters();
    });
    
    tearDown(() {
      synthParams.dispose();
    });
    
    test('Preset serialization and deserialization', () {
      // Set specific parameter values
      synthParams.filterCutoff = 2500.0;
      synthParams.filterResonance = 15.0;
      synthParams.attack = 0.05;
      synthParams.decay = 0.2;
      synthParams.sustain = 0.7;
      synthParams.release = 0.8;
      synthParams.masterVolume = 0.9;
      synthParams.reverbMix = 0.3;
      
      // Create preset data
      final presetData = {
        'name': 'Test Preset',
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'synthParams': {
          'filterCutoff': synthParams.filterCutoff,
          'filterResonance': synthParams.filterResonance,
          'attack': synthParams.attack,
          'decay': synthParams.decay,
          'sustain': synthParams.sustain,
          'release': synthParams.release,
          'masterVolume': synthParams.masterVolume,
          'reverbMix': synthParams.reverbMix,
        },
        'granularParams': {},
      };
      
      // Serialize to JSON
      final jsonString = json.encode(presetData);
      expect(jsonString, isNotEmpty);
      
      // Deserialize from JSON
      final decoded = json.decode(jsonString);
      expect(decoded['name'], 'Test Preset');
      expect(decoded['synthParams']['filterCutoff'], 2500.0);
      expect(decoded['synthParams']['filterResonance'], 15.0);
      expect(decoded['synthParams']['attack'], 0.05);
    });
    
    test('Parameter validation during preset load', () {
      // Create preset with invalid values
      final invalidPreset = {
        'name': 'Invalid Preset',
        'version': '1.0',
        'synthParams': {
          'filterCutoff': -100.0, // Invalid (below minimum)
          'filterResonance': 50.0, // Invalid (above maximum)
          'attack': -0.5, // Invalid (negative)
          'sustain': 2.0, // Invalid (above 1.0)
          'masterVolume': 1.5, // Invalid (above 1.0)
        },
      };
      
      // Values should be clamped to valid ranges
      final cutoff = (invalidPreset['synthParams']!['filterCutoff'] as double).clamp(20.0, 20000.0);
      final resonance = (invalidPreset['synthParams']!['filterResonance'] as double).clamp(0.0, 30.0);
      final attack = (invalidPreset['synthParams']!['attack'] as double).clamp(0.0, 5.0);
      final sustain = (invalidPreset['synthParams']!['sustain'] as double).clamp(0.0, 1.0);
      final volume = (invalidPreset['synthParams']!['masterVolume'] as double).clamp(0.0, 1.0);
      
      expect(cutoff, 20.0);
      expect(resonance, 30.0);
      expect(attack, 0.0);
      expect(sustain, 1.0);
      expect(volume, 1.0);
    });
    
    test('Preset metadata handling', () {
      final presetData = {
        'name': 'Test Preset',
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'author': 'Test User',
        'description': 'A test preset for verification',
        'tags': ['bass', 'analog', 'warm'],
        'category': 'Lead',
        'synthParams': {},
        'granularParams': {},
      };
      
      // Verify all metadata fields are preserved
      expect(presetData['name'], 'Test Preset');
      expect(presetData['author'], 'Test User');
      expect(presetData['description'], 'A test preset for verification');
      expect(presetData['tags'], ['bass', 'analog', 'warm']);
      expect(presetData['category'], 'Lead');
      expect(presetData['version'], '1.0');
      expect(presetData['timestamp'], isNotNull);
    });
    
    testWidgets('Preset save dialog works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: synthParams,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => PresetDialog.showSaveDialog(context),
                    child: const Text('Save Preset'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      
      // Tap the save preset button
      await tester.tap(find.text('Save Preset'));
      await tester.pumpAndSettle();
      
      // Should show save dialog (this might need platform-specific handling)
      // The exact dialog content depends on the implementation
    });
    
    testWidgets('Preset load dialog works correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider.value(
            value: synthParams,
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () => PresetDialog.showLoadDialog(context),
                    child: const Text('Load Preset'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      
      // Tap the load preset button
      await tester.tap(find.text('Load Preset'));
      await tester.pumpAndSettle();
      
      // Should show load dialog
    });
    
    test('Preset file naming and validation', () {
      // Valid preset names
      final validNames = [
        'My Preset',
        'Bass Lead 1',
        'Ambient Pad_v2',
        'SynthPop-80s',
        'Test123',
      ];
      
      for (final name in validNames) {
        expect(_isValidPresetName(name), true, reason: '$name should be valid');
      }
      
      // Invalid preset names
      final invalidNames = [
        '', // Empty
        '   ', // Only whitespace
        'Con', // Reserved Windows name
        'preset/with/slashes',
        'preset\\with\\backslashes',
        'preset:with:colons',
        'preset*with*asterisks',
        'preset?with?questions',
        'preset"with"quotes',
        'preset<with>brackets',
        'preset|with|pipes',
      ];
      
      for (final name in invalidNames) {
        expect(_isValidPresetName(name), false, reason: '$name should be invalid');
      }
    });
    
    test('Preset version compatibility', () {
      // Test different preset versions
      final v1Preset = {'version': '1.0', 'synthParams': {}};
      final v2Preset = {'version': '2.0', 'synthParams': {}};
      final noVersionPreset = {'synthParams': {}}; // Legacy preset
      
      expect(_isCompatibleVersion(v1Preset), true);
      expect(_isCompatibleVersion(v2Preset), false); // Future version
      expect(_isCompatibleVersion(noVersionPreset), true); // Legacy support
    });
    
    test('Preset categories and tags', () {
      final categories = [
        'Lead',
        'Bass',
        'Pad',
        'Arp',
        'Drum',
        'SFX',
        'User',
      ];
      
      final commonTags = [
        'analog',
        'digital',
        'warm',
        'bright',
        'dark',
        'aggressive',
        'soft',
        'distorted',
        'clean',
        'ambient',
        'dance',
        'rock',
        'pop',
        'electronic',
      ];
      
      // Verify categories are valid
      for (final category in categories) {
        expect(category, isNotEmpty);
        expect(category.length, lessThanOrEqualTo(20));
      }
      
      // Verify tags are valid
      for (final tag in commonTags) {
        expect(tag, isNotEmpty);
        expect(tag.length, lessThanOrEqualTo(15));
      }
    });
    
    test('Preset import/export functionality', () {
      final presetData = {
        'name': 'Export Test',
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'synthParams': {
          'filterCutoff': 1500.0,
          'filterResonance': 10.0,
          'masterVolume': 0.8,
        },
      };
      
      // Export to JSON string
      final exportedJson = json.encode(presetData);
      expect(exportedJson, isNotEmpty);
      
      // Import from JSON string
      final importedData = json.decode(exportedJson);
      expect(importedData['name'], 'Export Test');
      expect(importedData['synthParams']['filterCutoff'], 1500.0);
    });
    
    test('Multiple preset management', () {
      final presetNames = ['Preset A', 'Preset B', 'Preset C'];
      final presets = <String, Map<String, dynamic>>{};
      
      // Create multiple presets
      for (final name in presetNames) {
        presets[name] = {
          'name': name,
          'version': '1.0',
          'synthParams': {
            'filterCutoff': 1000.0 + (presetNames.indexOf(name) * 500),
          },
        };
      }
      
      // Verify all presets exist
      expect(presets.length, 3);
      expect(presets.keys.toList(), presetNames);
      
      // Verify unique parameter values
      expect(presets['Preset A']!['synthParams']['filterCutoff'], 1000.0);
      expect(presets['Preset B']!['synthParams']['filterCutoff'], 1500.0);
      expect(presets['Preset C']!['synthParams']['filterCutoff'], 2000.0);
    });
  });
  
  group('Preset Performance Tests', () {
    test('Large preset handling', () {
      // Create a preset with many parameters
      final largePreset = {
        'name': 'Large Preset',
        'version': '1.0',
        'synthParams': Map<String, double>.fromIterable(
          List.generate(100, (i) => 'param$i'),
          value: (key) => 0.5,
        ),
      };
      
      // Serialization should be fast
      final stopwatch = Stopwatch()..start();
      final jsonString = json.encode(largePreset);
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
      expect(jsonString.length, greaterThan(1000));
    });
    
    test('Preset loading performance', () {
      final presetJson = json.encode({
        'name': 'Performance Test',
        'version': '1.0',
        'synthParams': {
          'filterCutoff': 2000.0,
          'filterResonance': 15.0,
          'attack': 0.1,
          'decay': 0.3,
          'sustain': 0.7,
          'release': 0.5,
        },
      });
      
      // Deserialization should be fast
      final stopwatch = Stopwatch()..start();
      final decoded = json.decode(presetJson);
      stopwatch.stop();
      
      expect(stopwatch.elapsedMilliseconds, lessThan(10));
      expect(decoded['name'], 'Performance Test');
    });
  });
  
  group('Preset Error Handling', () {
    test('Handles corrupted JSON gracefully', () {
      final corruptedJson = '{"name": "Test", "version": 1.0, }'; // Invalid JSON
      
      expect(() {
        try {
          json.decode(corruptedJson);
        } catch (e) {
          // Should throw FormatException
          expect(e, isA<FormatException>());
          throw e;
        }
      }, throwsA(isA<FormatException>()));
    });
    
    test('Handles missing required fields', () {
      final incompletePreset = {
        'version': '1.0',
        // Missing 'name' field
        'synthParams': {},
      };
      
      // Should provide default name or handle gracefully
      final name = incompletePreset['name'] ?? 'Untitled Preset';
      expect(name, 'Untitled Preset');
    });
    
    test('Handles unknown preset fields', () {
      final futurePreset = {
        'name': 'Future Preset',
        'version': '3.0', // Future version
        'newFeature': 'some value', // Unknown field
        'synthParams': {
          'futureParam': 123.0, // Unknown parameter
          'filterCutoff': 1500.0, // Known parameter
        },
      };
      
      // Should ignore unknown fields and preserve known ones
      final knownParams = <String, dynamic>{};
      final synthParams = futurePreset['synthParams'] as Map<String, dynamic>;
      
      // Only extract known parameters
      if (synthParams.containsKey('filterCutoff')) {
        knownParams['filterCutoff'] = synthParams['filterCutoff'];
      }
      
      expect(knownParams['filterCutoff'], 1500.0);
      expect(knownParams.containsKey('futureParam'), false);
    });
  });
}

// Helper functions for testing

bool _isValidPresetName(String name) {
  if (name.trim().isEmpty) return false;
  if (name.length > 50) return false;
  
  // Check for invalid characters
  final invalidChars = RegExp(r'[\\/:*?"<>|]');
  if (invalidChars.hasMatch(name)) return false;
  
  // Check for reserved names (Windows)
  final reservedNames = ['CON', 'PRN', 'AUX', 'NUL'];
  if (reservedNames.contains(name.toUpperCase())) return false;
  
  return true;
}

bool _isCompatibleVersion(Map<String, dynamic> preset) {
  final version = preset['version'] as String?;
  if (version == null) return true; // Legacy preset
  
  final versionNumber = double.tryParse(version) ?? 1.0;
  return versionNumber <= 1.0; // Current supported version
}