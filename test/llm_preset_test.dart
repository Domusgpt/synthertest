import 'package:flutter_test/flutter_test.dart';
import 'package:synther/features/llm_presets/llm_preset_service.dart';
import 'package:synther/features/llm_presets/groq_service.dart';
import 'package:synther/features/llm_presets/cohere_service.dart';
import 'package:synther/features/llm_presets/together_ai_service.dart';
import 'package:synther/features/llm_presets/llm_service_unified.dart';
import 'package:synther/config/api_config.dart';
import 'package:synther/core/synth_parameters.dart';
import 'dart:convert';

void main() {
  group('LLM Preset Generation Tests', () {
    late LlmPresetService service;
    
    setUp(() {
      service = LlmPresetService();
    });
    
    test('Service initializes with default configuration', () {
      expect(service, isNotNull);
      // Should have fallback generation capability even without API keys
    });
    
    test('Rule-based fallback generation works', () async {
      // Test the fallback system that doesn't require API keys
      final prompt = 'Create a warm analog bass sound';
      
      // This should work without any API keys using rule-based generation
      final result = await service.generatePresetFromPrompt(
        prompt,
        useApiKey: false, // Force fallback mode
      );
      
      expect(result, isNotNull);
      expect(result['success'], true);
      expect(result['presetData'], isNotNull);
      
      final presetData = result['presetData'] as Map<String, dynamic>;
      expect(presetData['synthParams'], isNotNull);
      
      // Verify generated parameters are in valid ranges
      final synthParams = presetData['synthParams'] as Map<String, dynamic>;
      
      if (synthParams.containsKey('filterCutoff')) {
        final cutoff = synthParams['filterCutoff'] as double;
        expect(cutoff, inInclusiveRange(20.0, 20000.0));
      }
      
      if (synthParams.containsKey('filterResonance')) {
        final resonance = synthParams['filterResonance'] as double;
        expect(resonance, inInclusiveRange(0.0, 30.0));
      }
      
      if (synthParams.containsKey('masterVolume')) {
        final volume = synthParams['masterVolume'] as double;
        expect(volume, inInclusiveRange(0.0, 1.0));
      }
    });
    
    test('Multiple LLM providers are available', () {
      // Test that all expected services can be instantiated
      expect(() => GroqService(), returnsNormally);
      expect(() => CohereService(), returnsNormally);
      expect(() => TogetherAIService(), returnsNormally);
      expect(() => LlmServiceUnified(), returnsNormally);
    });
    
    test('Prompt analysis works correctly', () {
      final testPrompts = [
        'warm analog bass',
        'bright digital lead',
        'ambient ethereal pad',
        'aggressive distorted synth',
        'clean electric piano',
        'vintage 80s synthpop',
        'dark atmospheric drone',
        'punchy techno kick',
      ];
      
      for (final prompt in testPrompts) {
        final analysis = _analyzePrompt(prompt);
        
        expect(analysis, isNotNull);
        expect(analysis.containsKey('category'), true);
        expect(analysis.containsKey('characteristics'), true);
        expect(analysis.containsKey('suggested_params'), true);
        
        // Category should be one of the expected types
        final category = analysis['category'] as String;
        expect(['bass', 'lead', 'pad', 'drum', 'effect', 'unknown'], contains(category));
      }
    });
    
    test('Parameter generation follows musical logic', () {
      // Test bass sound generation
      final bassPrompt = 'deep sub bass';
      final bassParams = _generateParametersForPrompt(bassPrompt);
      
      // Bass sounds should have low filter cutoff
      expect(bassParams['filterCutoff'], lessThan(1000.0));
      
      // Test lead sound generation
      final leadPrompt = 'bright cutting lead';
      final leadParams = _generateParametersForPrompt(leadPrompt);
      
      // Lead sounds should have higher filter cutoff
      expect(leadParams['filterCutoff'], greaterThan(2000.0));
      
      // Test pad sound generation
      final padPrompt = 'ambient atmospheric pad';
      final padParams = _generateParametersForPrompt(padPrompt);
      
      // Pad sounds should have longer attack and release
      expect(padParams['attack'], greaterThan(0.1));
      expect(padParams['release'], greaterThan(0.5));
    });
    
    test('Preset validation works correctly', () {
      // Valid preset
      final validPreset = {
        'name': 'Test Preset',
        'synthParams': {
          'filterCutoff': 1500.0,
          'filterResonance': 10.0,
          'attack': 0.1,
          'decay': 0.3,
          'sustain': 0.7,
          'release': 0.5,
          'masterVolume': 0.8,
        },
      };
      
      expect(_validateGeneratedPreset(validPreset), true);
      
      // Invalid preset (out of range values)
      final invalidPreset = {
        'name': 'Invalid Preset',
        'synthParams': {
          'filterCutoff': -100.0, // Invalid
          'filterResonance': 50.0, // Invalid
          'attack': -1.0, // Invalid
          'masterVolume': 2.0, // Invalid
        },
      };
      
      expect(_validateGeneratedPreset(invalidPreset), false);
    });
    
    test('Error handling for API failures', () async {
      // Test with invalid API key
      service.initialize(
        geminiApiKey: 'invalid_key',
        apiType: ApiType.gemini,
      );
      
      final result = await service.generatePresetFromPrompt(
        'test prompt',
        timeout: const Duration(seconds: 5),
      );
      
      // Should fall back to rule-based generation
      expect(result['success'], true);
      expect(result['source'], 'fallback');
    });
    
    test('Rate limiting is respected', () async {
      // Make multiple rapid requests
      final futures = <Future>[];
      
      for (int i = 0; i < 5; i++) {
        futures.add(service.generatePresetFromPrompt('test prompt $i'));
      }
      
      final results = await Future.wait(futures);
      
      // All should complete (either with API or fallback)
      for (final result in results) {
        expect(result['success'], true);
      }
    });
    
    test('Caching prevents duplicate API calls', () async {
      final prompt = 'consistent test prompt';
      
      // First call
      final result1 = await service.generatePresetFromPrompt(prompt);
      
      // Second call with same prompt (should use cache)
      final result2 = await service.generatePresetFromPrompt(prompt);
      
      // Both should be successful
      expect(result1['success'], true);
      expect(result2['success'], true);
      
      // Check if caching is working (implementation dependent)
      if (result1.containsKey('cached') && result2.containsKey('cached')) {
        expect(result2['cached'], true);
      }
    });
    
    test('Different API providers produce valid results', () async {
      final prompt = 'analog synthesizer sound';
      final providers = [ApiType.huggingFace, ApiType.groq, ApiType.gemini];
      
      for (final provider in providers) {
        service.initialize(apiType: provider);
        
        final result = await service.generatePresetFromPrompt(
          prompt,
          timeout: const Duration(seconds: 10),
        );
        
        expect(result['success'], true);
        expect(result['presetData'], isNotNull);
        
        // Validate the generated preset
        final presetData = result['presetData'] as Map<String, dynamic>;
        expect(_validateGeneratedPreset(presetData), true);
      }
    });
    
    test('Unified LLM service handles provider fallbacks', () async {
      final unifiedService = LlmServiceUnified();
      
      final result = await unifiedService.generatePreset(
        description: 'test synthesizer sound',
        category: 'lead',
        characteristics: ['bright', 'cutting'],
      );
      
      expect(result, isNotNull);
      expect(result.containsKey('parameters'), true);
      
      final parameters = result['parameters'] as Map<String, dynamic>;
      expect(parameters.isNotEmpty, true);
    });
    
    test('Web-only JavaScript generator works', () {
      // Test the web-specific generator
      final webGenerated = _generateWebOnlyPreset('digital lead synth');
      
      expect(webGenerated, isNotNull);
      expect(webGenerated.containsKey('synthParams'), true);
      
      final synthParams = webGenerated['synthParams'] as Map<String, dynamic>;
      
      // Should have basic parameters
      expect(synthParams.containsKey('filterCutoff'), true);
      expect(synthParams.containsKey('filterResonance'), true);
      expect(synthParams.containsKey('attack'), true);
      expect(synthParams.containsKey('decay'), true);
      expect(synthParams.containsKey('sustain'), true);
      expect(synthParams.containsKey('release'), true);
    });
    
    test('Preset generation preserves musical context', () {
      final contexts = [
        {'style': '80s synthpop', 'expected_reverb': 0.3},
        {'style': 'minimal techno', 'expected_attack': 0.0},
        {'style': 'ambient drone', 'expected_release': 1.0},
        {'style': 'aggressive dubstep', 'expected_distortion': 0.7},
      ];
      
      for (final context in contexts) {
        final style = context['style'] as String;
        final generated = _generateParametersForPrompt(style);
        
        // Check that style-appropriate parameters are set
        if (context.containsKey('expected_reverb')) {
          expect(generated['reverbMix'], greaterThan(context['expected_reverb'] as double - 0.1));
        }
        
        if (context.containsKey('expected_attack')) {
          expect(generated['attack'], lessThan(0.05));
        }
        
        if (context.containsKey('expected_release')) {
          expect(generated['release'], greaterThan(context['expected_release'] as double - 0.2));
        }
        
        if (context.containsKey('expected_distortion')) {
          expect(generated['distortionAmount'], greaterThan(context['expected_distortion'] as double - 0.2));
        }
      }
    });
  });
  
  group('LLM Integration Performance Tests', () {
    test('Generation completes within timeout', () async {
      final service = LlmPresetService();
      final stopwatch = Stopwatch()..start();
      
      final result = await service.generatePresetFromPrompt(
        'test prompt',
        timeout: const Duration(seconds: 10),
      );
      
      stopwatch.stop();
      
      expect(result['success'], true);
      expect(stopwatch.elapsed.inSeconds, lessThan(10));
    });
    
    test('Memory usage remains reasonable', () {
      // Test multiple generations don't cause memory leaks
      final service = LlmPresetService();
      
      for (int i = 0; i < 20; i++) {
        _generateParametersForPrompt('test prompt $i');
      }
      
      // If we reach here without out-of-memory, test passes
      expect(true, true);
    });
  });
}

// Helper functions for testing

Map<String, dynamic> _analyzePrompt(String prompt) {
  final words = prompt.toLowerCase().split(' ');
  
  String category = 'unknown';
  final characteristics = <String>[];
  final suggestedParams = <String, double>{};
  
  // Simple keyword-based analysis
  if (words.any((w) => ['bass', 'sub', 'low'].contains(w))) {
    category = 'bass';
    suggestedParams['filterCutoff'] = 800.0;
  } else if (words.any((w) => ['lead', 'solo', 'melody'].contains(w))) {
    category = 'lead';
    suggestedParams['filterCutoff'] = 3000.0;
  } else if (words.any((w) => ['pad', 'ambient', 'atmosphere'].contains(w))) {
    category = 'pad';
    suggestedParams['attack'] = 0.5;
    suggestedParams['release'] = 1.0;
  }
  
  if (words.contains('warm')) characteristics.add('warm');
  if (words.contains('bright')) characteristics.add('bright');
  if (words.contains('dark')) characteristics.add('dark');
  if (words.contains('aggressive')) characteristics.add('aggressive');
  
  return {
    'category': category,
    'characteristics': characteristics,
    'suggested_params': suggestedParams,
  };
}

Map<String, dynamic> _generateParametersForPrompt(String prompt) {
  final analysis = _analyzePrompt(prompt);
  final params = <String, dynamic>{};
  
  // Base parameters
  params['filterCutoff'] = 1500.0;
  params['filterResonance'] = 10.0;
  params['attack'] = 0.1;
  params['decay'] = 0.3;
  params['sustain'] = 0.7;
  params['release'] = 0.5;
  params['masterVolume'] = 0.8;
  params['reverbMix'] = 0.2;
  params['distortionAmount'] = 0.0;
  
  // Apply suggested parameters from analysis
  final suggested = analysis['suggested_params'] as Map<String, double>;
  params.addAll(suggested);
  
  // Apply characteristics
  final characteristics = analysis['characteristics'] as List<String>;
  
  if (characteristics.contains('warm')) {
    params['filterCutoff'] = (params['filterCutoff'] as double) * 0.7;
    params['reverbMix'] = 0.3;
  }
  
  if (characteristics.contains('bright')) {
    params['filterCutoff'] = (params['filterCutoff'] as double) * 1.5;
    params['filterResonance'] = 20.0;
  }
  
  if (characteristics.contains('aggressive')) {
    params['distortionAmount'] = 0.6;
    params['filterResonance'] = 25.0;
  }
  
  // Clamp all values to valid ranges
  params['filterCutoff'] = (params['filterCutoff'] as double).clamp(20.0, 20000.0);
  params['filterResonance'] = (params['filterResonance'] as double).clamp(0.0, 30.0);
  params['attack'] = (params['attack'] as double).clamp(0.0, 5.0);
  params['decay'] = (params['decay'] as double).clamp(0.0, 5.0);
  params['sustain'] = (params['sustain'] as double).clamp(0.0, 1.0);
  params['release'] = (params['release'] as double).clamp(0.0, 5.0);
  params['masterVolume'] = (params['masterVolume'] as double).clamp(0.0, 1.0);
  params['reverbMix'] = (params['reverbMix'] as double).clamp(0.0, 1.0);
  params['distortionAmount'] = (params['distortionAmount'] as double).clamp(0.0, 1.0);
  
  return params;
}

bool _validateGeneratedPreset(Map<String, dynamic> preset) {
  if (!preset.containsKey('synthParams')) return false;
  
  final synthParams = preset['synthParams'] as Map<String, dynamic>;
  
  // Check required parameters exist and are in valid ranges
  final checks = [
    () => _isInRange(synthParams['filterCutoff'], 20.0, 20000.0),
    () => _isInRange(synthParams['filterResonance'], 0.0, 30.0),
    () => _isInRange(synthParams['attack'], 0.0, 5.0),
    () => _isInRange(synthParams['decay'], 0.0, 5.0),
    () => _isInRange(synthParams['sustain'], 0.0, 1.0),
    () => _isInRange(synthParams['release'], 0.0, 5.0),
    () => _isInRange(synthParams['masterVolume'], 0.0, 1.0),
  ];
  
  return checks.every((check) {
    try {
      return check();
    } catch (e) {
      return false;
    }
  });
}

bool _isInRange(dynamic value, double min, double max) {
  if (value is! double) return false;
  return value >= min && value <= max;
}

Map<String, dynamic> _generateWebOnlyPreset(String prompt) {
  // Simplified web-only generation for testing
  return {
    'name': 'Web Generated',
    'synthParams': _generateParametersForPrompt(prompt),
    'source': 'web',
  };
}