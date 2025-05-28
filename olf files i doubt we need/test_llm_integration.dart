// Test script to verify LLM preset integration with audio engine
import 'package:flutter/material.dart';
import 'lib/core/synth_parameters.dart';
import 'lib/features/llm_presets/llm_preset_service.dart';
import 'lib/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('=== LLM Preset Integration Test ===\n');
  
  // 1. Create synth parameters model
  print('1. Creating SynthParametersModel...');
  final synthParams = SynthParametersModel();
  
  // Give it time to initialize
  await Future.delayed(Duration(seconds: 1));
  
  // Log initial state
  print('Initial parameters:');
  print('  - Frequency: ${synthParams.oscillators.first.frequency}');
  print('  - Oscillator Type: ${synthParams.oscillators.first.type}');
  print('  - Filter Cutoff: ${synthParams.filterCutoff}');
  print('  - Reverb Mix: ${synthParams.reverbMix}');
  
  // 2. Initialize LLM preset service
  print('\n2. Initializing LLM preset service...');
  final presetService = LlmPresetService();
  presetService.initialize(
    geminiApiKey: ApiConfig.geminiApiKey,
    huggingFaceApiKey: ApiConfig.huggingFaceApiKey,
    apiType: ApiType.huggingFace, // Use rule-based fallback
  );
  
  // 3. Generate a preset
  print('\n3. Generating preset for "deep bass with reverb"...');
  final generatedModel = await presetService.generatePreset('deep bass with reverb');
  
  if (generatedModel == null) {
    print('ERROR: Failed to generate preset!');
    return;
  }
  
  print('Generated model created successfully');
  
  // 4. Test direct parameter access
  print('\n4. Generated model parameters:');
  print('  - Frequency: ${generatedModel.oscillators.first.frequency}');
  print('  - Oscillator Type: ${generatedModel.oscillators.first.type}');
  print('  - Filter Cutoff: ${generatedModel.filterCutoff}');
  print('  - Reverb Mix: ${generatedModel.reverbMix}');
  
  // 5. Test JSON conversion
  print('\n5. Testing JSON conversion...');
  final json = generatedModel.toJson();
  print('JSON keys: ${json.keys.toList()}');
  
  // 6. Load into original model
  print('\n6. Loading generated parameters into original model...');
  synthParams.loadFromJson(json);
  
  // 7. Verify parameters were applied
  print('\n7. Parameters after loading:');
  print('  - Frequency: ${synthParams.oscillators.first.frequency}');
  print('  - Oscillator Type: ${synthParams.oscillators.first.type}');
  print('  - Filter Cutoff: ${synthParams.filterCutoff}');
  print('  - Reverb Mix: ${synthParams.reverbMix}');
  
  // 8. Check if parameters changed
  print('\n8. Verification:');
  if (synthParams.oscillators.first.frequency != 440.0) {
    print('✓ Frequency changed from default');
  } else {
    print('✗ Frequency unchanged');
  }
  
  if (synthParams.reverbMix > 0.3) {
    print('✓ Reverb mix increased (expected for "reverb" keyword)');
  } else {
    print('✗ Reverb mix not increased');
  }
  
  print('\n=== Test Complete ===');
}