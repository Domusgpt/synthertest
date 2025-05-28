# CLAUDE_UI.md - FLUTTER UI SPECIALIST

**🎨 SPECIALIST ROLE:** Flutter UI & Integration Developer  
**🎯 MISSION:** Perfect the Flutter UI and integrate with working audio engine  
**📊 REPORT TO:** Lead Dev Claude via PROJECT_STATUS.md updates

## 🚀 PRIMARY OBJECTIVES

### 1. POLISH EXISTING FLUTTER UI
- Refine XY Pad responsiveness and visual feedback
- Enhance keyboard widget with better touch handling
- Optimize control panels for intuitive parameter adjustment
- Ensure smooth UI performance across all target platforms

### 2. INTEGRATE WITH AUDIO ENGINE
- Connect UI controls to working C++ audio engine via FFI
- Implement real-time parameter updates without audio dropouts
- Add visual feedback for audio engine status and errors
- Create seamless audio-UI synchronization

### 3. PREPARE FOR VISUALIZER & LLM INTEGRATION
- Design UI layout to accommodate embedded WebGL visualizer
- Create transparent/glassmorphic UI elements for overlay design
- Implement parameter bridge architecture for 3-way sync (UI ↔ Audio ↔ Visualizer)
- **Ensure LLM preset system integration points are preserved and functional**

## 🏗️ TECHNICAL SPECIFICATIONS

### UI INTEGRATION ARCHITECTURE:
```
Flutter UI Layer
├── app.dart                    # Main UI with visualizer background space
├── features/
│   ├── xy_pad/                # Enhanced XY pad with audio feedback  
│   ├── keyboard/              # Optimized keyboard with velocity sensitivity
│   ├── shared_controls/       # Real-time parameter controls
│   └── visualizer_bridge/     # NEW: WebView communication layer
├── core/
│   ├── synth_parameters.dart  # Enhanced with visualizer params
│   ├── audio_service.dart     # Connects to working native engine
│   └── parameter_bridge.dart  # NEW: 3-way parameter synchronization
└── utils/
    ├── ui_performance.dart    # NEW: UI optimization utilities
    └── audio_ui_sync.dart     # NEW: Audio-UI coordination
```

### INTEGRATION REQUIREMENTS:
1. **Real-time Audio Sync:** UI updates must not cause audio dropouts
2. **Visual Feedback:** All audio parameters show visual response
3. **Touch Responsiveness:** XY pad and keyboard feel immediate
4. **Visualizer Ready:** UI designed for transparent overlay on 4D visuals
5. **LLM Preset Ready:** Existing LLM preset system (`lib/features/llm_presets/`) must remain functional
6. **Cross-Platform:** Consistent behavior on Android, iOS, Web, Desktop

## 🎛️ CRITICAL SUCCESS CRITERIA

### AUDIO-UI INTEGRATION:
- [ ] XY Pad movements instantly affect audio parameters
- [ ] Keyboard notes trigger audio engine with proper velocity
- [ ] All control knobs/sliders update audio in real-time
- [ ] Visual feedback shows current audio engine state
- [ ] No audio dropouts during intensive UI interaction
- [ ] **LLM preset widget (`LlmPresetWidget`) remains functional and integrated**

### VISUALIZER PREPARATION:
- [ ] UI layout accommodates full-screen background visualizer
- [ ] UI elements use transparent/glassmorphic styling
- [ ] Parameter bridge ready for 3-way sync (UI ↔ Audio ↔ Viz)
- [ ] Touch handling coordinates with visualizer canvas
- [ ] Performance maintains 60fps with background visualizer

## 📋 DETAILED WORK INSTRUCTIONS

### PHASE 0: PRESERVE EXISTING LLM PRESET SYSTEM (Priority 1)
```dart
// CRITICAL: Do NOT break existing LLM preset functionality
// The following components must remain working:
// - lib/features/llm_presets/llm_preset_widget.dart
// - lib/features/llm_presets/llm_preset_service.dart  
// - All LLM API integrations (Hugging Face, Groq, Gemini, etc.)
// - Preset generation and application to SynthParametersModel

// Test that LLM presets still work after audio integration:
void testLLMPresetIntegration() {
  // 1. Generate preset via LLM
  // 2. Apply to SynthParametersModel
  // 3. Verify audio engine receives parameters
  // 4. Confirm preset works end-to-end
}
```

### PHASE 1: AUDIO ENGINE INTEGRATION (Priority 1)
```dart
// 1. Update SynthParametersModel to use working audio engine
// FROM: Placeholder audio backend
// TO: Real native audio engine with working FFI

// 2. Add real-time parameter validation
class SynthParametersModel extends ChangeNotifier {
  void setFilterCutoff(double value) {
    // Add audio engine validation
    if (!_engine.isInitialized) return;
    // Ensure parameter updates don't block audio thread
    _engine.setParameterAsync(SynthParameterId.filterCutoff, value);
    notifyListeners();
  }
}

// 3. Add audio engine status monitoring
void _monitorAudioEngineStatus() {
  // Show user if audio engine has problems
  // Provide helpful error messages
  // Auto-reconnect if audio engine restarts
}
```

### PHASE 2: UI PERFORMANCE OPTIMIZATION (Priority 1)
```dart
// 1. Optimize XY Pad for high-frequency updates
class XYPad extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    // Use RepaintBoundary to isolate repaints
    // Implement gesture debouncing for performance
    // Add visual feedback for parameter changes
  }
}

// 2. Create 60fps parameter update system
class ParameterUpdateManager {
  // Batch UI updates to match audio engine timing
  // Prevent UI flooding from rapid parameter changes
  // Ensure smooth visual transitions
}

// 3. Add performance monitoring
class UIPerformanceMonitor {
  // Track frame rate during intensive operations
  // Identify performance bottlenecks
  // Auto-adjust update frequency if needed
}
```

### PHASE 3: VISUALIZER PREPARATION (Priority 2)
```dart
// 1. Design glassmorphic UI overlay system
class TransparentControlPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        // Control widgets here
      ),
    );
  }
}

// 2. Create parameter bridge for 3-way sync
class ParameterBridge {
  void updateParameter(String param, double value) {
    // Update audio engine
    _audioEngine.setParameter(param, value);
    // Update UI
    _synthParameters.setParameter(param, value);
    // Prepare visualizer update (stub for now)
    _prepareVisualizerUpdate(param, value);
  }
}

// 3. Design touch coordination system
class TouchCoordinator {
  // Manage touches between Flutter widgets and WebView
  // Prevent conflicts between UI controls and visualizer canvas
  // Enable smooth gesture transitions
}
```

## 🚨 INTEGRATION CHALLENGES & SOLUTIONS

### CHALLENGE: Audio Thread vs UI Thread
**SOLUTION:** Use async parameter updates, never block audio thread

### CHALLENGE: High-frequency XY Pad updates
**SOLUTION:** Implement gesture debouncing, batch updates at 60fps

### CHALLENGE: Cross-platform UI consistency  
**SOLUTION:** Test on multiple platforms, use Flutter's adaptive widgets

### CHALLENGE: Preparing for visualizer overlay
**SOLUTION:** Design with transparency in mind, test with placeholder WebView

## 📊 REPORTING PROTOCOL

Update PROJECT_STATUS.md with:

```markdown
@REPORT: CLAUDE_UI - [STATUS] - [timestamp]
- Progress: [What UI improvements were made]
- Audio Integration: [How well UI connects to audio engine]
- Performance: [Frame rate, responsiveness metrics]
- Issues: [Any UI or integration problems]
- Solutions: [How problems were resolved]
- Visualizer Readiness: [How prepared UI is for visualizer overlay]
- @HANDOFF: [What CLAUDE_VIZ needs for visualizer integration]
```

## 🔄 HANDOFF TO VISUALIZER SPECIALIST

When UI integration is complete, provide visualizer specialist with:
1. **Parameter Bridge Interface** - How to sync with UI and audio
2. **UI Layout Specifications** - Where visualizer fits in the app
3. **Touch Handling Protocol** - How UI and visualizer coordinate touches
4. **Performance Benchmarks** - Current UI performance baseline
5. **Integration Test Results** - Demonstrating stable UI + audio
6. **LLM Preset Compatibility** - Confirm presets work with new audio engine

---
**🎨 Your mission: Create a beautiful, responsive UI that feels unified with the audio engine. Focus on performance and prepare for visual magic!**