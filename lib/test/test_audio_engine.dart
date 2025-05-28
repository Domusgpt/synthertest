import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/synth_parameters.dart';
import '../core/audio_service.dart';
import '../core/parameter_definitions.dart';

/// Test widget to verify audio engine integration
class AudioEngineTestWidget extends StatefulWidget {
  const AudioEngineTestWidget({Key? key}) : super(key: key);

  @override
  State<AudioEngineTestWidget> createState() => _AudioEngineTestWidgetState();
}

class _AudioEngineTestWidgetState extends State<AudioEngineTestWidget> {
  final AudioService _audioService = AudioService.instance;
  bool _isInitialized = false;
  String _status = 'Not initialized';
  
  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }
  
  Future<void> _initializeAudio() async {
    try {
      setState(() {
        _status = 'Initializing audio...';
      });
      
      await _audioService.initialize();
      
      setState(() {
        _isInitialized = true;
        _status = 'Audio engine initialized successfully';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    }
  }
  
  void _testNoteOn() {
    if (!_isInitialized) return;
    
    final model = context.read<SynthParametersModel>();
    model.noteOn(60, 100); // Middle C, velocity 100
    
    setState(() {
      _status = 'Note ON - Middle C';
    });
    
    // Auto note off after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      model.noteOff(60);
      setState(() {
        _status = 'Note OFF';
      });
    });
  }
  
  void _testParameterUpdate() {
    if (!_isInitialized) return;
    
    final model = context.read<SynthParametersModel>();
    
    // Test various parameter updates
    model.setFilterCutoff(5000);
    model.setFilterResonance(0.7);
    model.setReverbMix(0.5);
    
    setState(() {
      _status = 'Parameters updated: Cutoff=5000Hz, Res=0.7, Reverb=0.5';
    });
  }
  
  void _testLLMPresetIntegration() async {
    if (!_isInitialized) return;
    
    final model = context.read<SynthParametersModel>();
    
    // Simulate LLM preset application
    final testPreset = {
      'masterVolume': 0.8,
      'filterCutoff': 2000.0,
      'filterResonance': 0.6,
      'reverbMix': 0.3,
      'oscillators': [
        {
          'type': 3, // Sawtooth
          'frequency': 440.0,
          'volume': 0.7,
          'detune': 0.0,
        }
      ],
      'envelope': {
        'attackTime': 0.05,
        'decayTime': 0.2,
        'sustainLevel': 0.6,
        'releaseTime': 0.8,
      }
    };
    
    model.loadFromJson(testPreset);
    
    setState(() {
      _status = 'LLM preset applied successfully';
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audio Engine Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Status display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isInitialized ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isInitialized ? Colors.green : Colors.orange,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _isInitialized ? Icons.check_circle : Icons.hourglass_empty,
                      color: _isInitialized ? Colors.green : Colors.orange,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _isInitialized ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Test buttons
              ElevatedButton.icon(
                onPressed: _isInitialized ? _testNoteOn : null,
                icon: const Icon(Icons.music_note),
                label: const Text('Test Note (Middle C)'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: _isInitialized ? _testParameterUpdate : null,
                icon: const Icon(Icons.tune),
                label: const Text('Test Parameters'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
              
              const SizedBox(height: 16),
              
              ElevatedButton.icon(
                onPressed: _isInitialized ? _testLLMPresetIntegration : null,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Test LLM Preset'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Parameter display
              if (_isInitialized)
                Consumer<SynthParametersModel>(
                  builder: (context, model, child) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Volume: ${(model.masterVolume * 100).toStringAsFixed(0)}%'),
                          Text('Filter Cutoff: ${model.filterCutoff.toStringAsFixed(0)} Hz'),
                          Text('Filter Resonance: ${(model.filterResonance * 100).toStringAsFixed(0)}%'),
                          Text('Reverb: ${(model.reverbMix * 100).toStringAsFixed(0)}%'),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}