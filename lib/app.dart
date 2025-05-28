import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'core/synth_parameters.dart';
import 'core/firebase_manager.dart';
import 'features/xy_pad/xy_pad.dart';
import 'features/keyboard/keyboard_widget.dart';
import 'features/shared_controls/control_panel_widget.dart';
import 'features/microphone_input/mic_input_widget.dart';
import 'features/llm_presets/llm_preset_widget.dart';
import 'features/granular/granular_controls_widget.dart';
import 'features/presets/preset_dialog.dart';
import 'features/visualizer_bridge/visualizer_bridge_widget.dart';
import 'features/visualizer_bridge/visualizer_stub.dart'
    if (dart.library.html) 'features/visualizer_bridge/visualizer_web.dart';
import 'features/ads/ad_manager.dart';
import 'features/premium/premium_upgrade_screen.dart';
import 'utils/audio_ui_sync.dart';

class SynthesizerApp extends StatelessWidget {
  const SynthesizerApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Set preferred orientations
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    
    return MaterialApp(
      title: 'Sound Synthesizer',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.dark,
      home: const SynthesizerHomePage(),
    );
  }
}

class SynthesizerHomePage extends StatefulWidget {
  const SynthesizerHomePage({super.key});

  @override
  State<SynthesizerHomePage> createState() => _SynthesizerHomePageState();
}

class _SynthesizerHomePageState extends State<SynthesizerHomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  bool _showVisualizer = true;
  final AdManager _adManager = AdManager();
  DateTime? _sessionStartTime;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sessionStartTime = DateTime.now();
    
    // Check if we should show interstitial after delay
    Future.delayed(const Duration(seconds: 30), () {
      _checkAndShowInterstitial();
    });
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    
    // Track session end
    if (_sessionStartTime != null) {
      final sessionDuration = DateTime.now().difference(_sessionStartTime!);
      context.read<FirebaseManager>().trackSessionEnd(sessionDuration);
    }
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background, show interstitial when coming back
      _checkAndShowInterstitial();
    }
  }
  
  Future<void> _checkAndShowInterstitial() async {
    if (await _adManager.shouldShowInterstitialNow()) {
      await _adManager.showInterstitialAd(
        onDismissed: () {
          // Continue with app flow
        },
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Row(
          children: const [
            Text('Sound Synthesizer'),
            SizedBox(width: 16),
            AudioEngineStatusWidget(),
          ],
        ),
        backgroundColor: _showVisualizer 
          ? Colors.black.withOpacity(0.5)
          : Theme.of(context).colorScheme.inversePrimary,
        elevation: _showVisualizer ? 0 : 4,
        actions: [
          IconButton(
            icon: Icon(_showVisualizer ? Icons.visibility : Icons.visibility_off),
            tooltip: 'Toggle Visualizer',
            onPressed: () {
              setState(() {
                _showVisualizer = !_showVisualizer;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Save Preset',
            onPressed: () => PresetDialog.showSaveDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Load Preset',
            onPressed: () => PresetDialog.showLoadDialog(context),
          ),
          // Premium upgrade button for free users
          Consumer<FirebaseManager>(
            builder: (context, firebase, _) {
              final isPremium = firebase.userProfile?.premiumTier != PremiumTier.free;
              
              if (isPremium) {
                return IconButton(
                  icon: const Icon(Icons.star, color: Colors.amber),
                  tooltip: 'Premium Member',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumUpgradeScreen(),
                      ),
                    );
                  },
                );
              } else {
                return TextButton.icon(
                  icon: const Icon(Icons.star_outline, color: Colors.amber),
                  label: const Text('Upgrade', style: TextStyle(color: Colors.amber)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PremiumUpgradeScreen(),
                      ),
                    );
                  },
                );
              }
            },
          ),
          
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              // TODO: Implement settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background visualizer
          if (_showVisualizer)
            Positioned.fill(
              child: kIsWeb
                ? const VisualizerWeb(
                    opacity: 0.8,
                    showControls: false,
                  )
                : const VisualizerBridgeWidget(
                    opacity: 0.8,
                    showControls: false,
                  ),
            ),
          
          // Main content
          IndexedStack(
            index: _selectedIndex,
            children: [
              // XY Pad interface
              _buildXYPadInterface(),
              
              // Keyboard interface
              _buildKeyboardInterface(),
              
              // Settings interface
              _buildSettingsInterface(),
            ],
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Banner ad above navigation (for free users)
          const BannerAdWidget(),
          
          BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.grid_4x4),
                label: 'XY Pad',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.piano),
                label: 'Keyboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.tune),
                label: 'Controls',
              ),
            ],
            currentIndex: _selectedIndex,
            onTap: (index) {
              setState(() {
                _selectedIndex = index;
              });
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildXYPadInterface() {
    return Container(
      decoration: _showVisualizer ? BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ) : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // XY Pad
          const XYPad(
            height: 300,
            backgroundColor: Color(0xFF1D1D1D),
            gridColor: Colors.grey,
            cursorColor: Colors.green,
            label: 'XY Pad',
            octaveRange: 2,
            baseNote: 48, // C3
            scale: Scale.minorPentatonic,
          ),
          
          const SizedBox(height: 16),
          
          // Mini keyboard at the bottom for quick note input
          const KeyboardWidget(
            height: 120,
            startOctave: 4,
            numOctaves: 2,
            showLabels: false,
          ),
        ],
      ),
      ),
    );
  }
  
  Widget _buildKeyboardInterface() {
    return Container(
      decoration: _showVisualizer ? BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ) : null,
      child: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full-sized keyboard
          const KeyboardWidget(
            height: 200,
            startOctave: 3,
            numOctaves: 3,
            showLabels: true,
          ),
          
          const SizedBox(height: 24),
          
          // Mini XY Pad for quick control
          SizedBox(
            height: 200,
            child: Consumer<SynthParametersModel>(
              builder: (context, model, child) {
                return Row(
                  children: [
                    // Mini XY Pad on left
                    const Expanded(
                      flex: 2,
                      child: XYPad(
                        height: 200,
                        backgroundColor: Color(0xFF1D1D1D),
                        gridColor: Colors.grey,
                        cursorColor: Colors.green,
                        label: 'XY Pad',
                        octaveRange: 2,
                        scale: Scale.blues,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Quick control knobs on right
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Controls',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // Volume knob
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Slider(
                                      value: model.masterVolume,
                                      onChanged: (value) => model.setMasterVolume(value),
                                      activeColor: Theme.of(context).colorScheme.primary,
                                      inactiveColor: Colors.grey.shade800,
                                    ),
                                    const Text('Volume'),
                                  ],
                                ),
                                
                                // Filter cutoff knob
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Slider(
                                      value: model.filterCutoff.clamp(20, 20000) / 20000,
                                      onChanged: (value) => model.setFilterCutoff(value * 20000),
                                      activeColor: Theme.of(context).colorScheme.primary,
                                      inactiveColor: Colors.grey.shade800,
                                    ),
                                    const Text('Cutoff'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
  
  Widget _buildSettingsInterface() {
    return Container(
      decoration: _showVisualizer ? BoxDecoration(
        color: Colors.black.withOpacity(0.3),
      ) : null,
      child: const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Main control panel
          ControlPanelWidget(),
          
          SizedBox(height: 24),
          
          // Microphone input widget
          MicInputWidget(),
          
          SizedBox(height: 24),
          
          // LLM preset generation widget
          LlmPresetWidget(),
          
          SizedBox(height: 24),
          
          // Granular synthesis widget
          GranularControlsWidget(),
        ],
      ),
      ),
    );
  }
}