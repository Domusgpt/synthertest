# Claude Code Instructions - HyperAV Synthesizer

## 🎯 Primary Objective

Transform the current messy collection of files into a **unified, working synthesizer** that seamlessly integrates:
1. **Flutter UI** with XY Pad and keyboard controls
2. **C++ audio engine** for high-performance sound generation  
3. **HyperAV 4D visualizer** as the reactive background
4. **AI preset generation** for natural language sound creation
5. **Cross-platform compatibility** for all target devices

## 🏗️ Project Architecture Understanding

You are working with THREE main codebases that need to be **intelligently merged**:

### Current Components
- **Flutter App** (`lib/`, `android/`, `ios/`, etc.) - UI and app structure
- **C++ Audio Engine** (`native/` - needs to be created/organized from scattered files)
- **HyperAV Visualizer** (`WORKING_SYNTH.html`, `index.html`, web assets) - 4D reactive visuals
- **Build System** (various `CMakeLists.txt`, `build.gradle`, etc.)

### Target Integration
- HyperAV visualizer becomes the **background canvas** for the entire UI
- Flutter widgets are **overlaid transparently** on the 4D visuals
- Audio parameters **bidirectionally sync** between engine and visualizer
- Touch/mouse interactions affect **both UI controls AND 4D geometry**

## 🎵 Core Integration Strategy

### Phase 1: Project Structure Cleanup
1. **Organize native audio engine**:
   - Create proper `native/` directory structure
   - Move C++ source files from scattered locations
   - Set up CMake build system for all platforms
   - Ensure RTAudio integration works

2. **Integrate HyperAV visualizer**:
   - Embed the WebGL visualizer in Flutter using WebView/HtmlElementView
   - Create bidirectional JavaScript↔Dart communication bridge
   - Ensure visualizer responds to audio engine parameters in real-time

3. **Unified parameter system**:
   - Create `lib/core/parameter_bridge.dart` to sync:
     - Flutter UI controls ↔ C++ audio engine ↔ JavaScript visualizer
   - All three systems should react to the same parameter changes

### Phase 2: UI Integration
1. **Transparent overlay design**:
   - Make Flutter widgets semi-transparent with glassmorphism effects
   - Position UI elements to complement 4D visuals
   - Ensure XY Pad gestures control both audio AND 4D geometry

2. **Audio-reactive visuals**:
   - Map synthesizer parameters to 4D visualization properties:
     - **Filter cutoff** → 4D dimension morphing
     - **Resonance** → Geometric transformation intensity  
     - **Oscillator frequency** → Color spectrum
     - **Envelope** → Spatial dynamics
     - **Effects** → Visual effects (glitch, blur, etc.)

### Phase 3: Advanced Features
1. **Live input integration**:
   - Microphone input affects both audio processing AND visuals
   - Real-time audio analysis feeds the 4D visualizer
   - Visual feedback shows input levels and frequency content

2. **AI preset system**:
   - Natural language input generates both audio parameters AND visual presets
   - LLM creates cohesive audio-visual experiences
   - Save/load presets include both sound and visual settings

## 🛠️ Development Workflow

### Step 1: Environment Setup
```bash
# Ensure you have these tools available:
flutter doctor                    # Check Flutter installation
cmake --version                   # Verify CMake 3.16+
# Platform-specific SDKs as needed

# Project initialization
flutter create . --project-name hyperav_synthesizer
flutter pub get
```

### Step 2: Native Engine Organization
```bash
# Create proper native structure
mkdir -p native/src native/include native/build
# Move and organize C++ files from current scattered locations
# Set up CMakeLists.txt for cross-platform builds
# Test basic audio engine compilation
```

### Step 3: Visualizer Integration
```bash
# Create web assets directory structure
mkdir -p assets/web
# Move HyperAV visualizer files to proper Flutter asset location
# Set up WebView integration with bidirectional communication
# Test basic embedding and parameter passing
```

### Step 4: Parameter Synchronization
```bash
# Implement unified parameter bridge
# Test real-time sync between UI ↔ Audio ↔ Visuals
# Ensure smooth 60fps visual updates with audio changes
```

## 📋 Key Implementation Checklist

### Critical Success Criteria
- [ ] **Audio engine produces sound** on target platform
- [ ] **4D visualizer renders** and reacts to audio in real-time
- [ ] **UI controls affect both** audio parameters and visuals
- [ ] **Touch interactions** work on both UI elements and 4D canvas
- [ ] **Cross-platform builds** succeed for Android, iOS, Web
- [ ] **AI preset generation** creates working audio-visual presets
- [ ] **Performance** maintains 60fps visuals with low-latency audio

### Platform-Specific Requirements
- **Android**: NDK integration, audio permissions, WebView compatibility
- **iOS**: Framework setup, Metal rendering, WKWebView usage  
- **Web**: WebGL + Web Audio API, responsive design
- **Desktop**: Native audio drivers, OpenGL support

## 🎨 UI/UX Design Principles

### Visual Hierarchy
1. **4D visualizer** fills entire background (primary visual)
2. **Transparent UI panels** overlay key controls (secondary)
3. **XY Pad** integrates directly with 4D geometry (interactive)
4. **Keyboard** triggers both audio notes and visual harmonics

### Interaction Design
- **Single touch/click** affects multiple systems simultaneously
- **Gesture continuity** between UI controls and 4D canvas
- **Visual feedback** for all parameter changes
- **Smooth transitions** between different control modes

## 🔧 Technical Implementation Notes

### FFI Integration
```dart
// Example parameter bridge pattern
class ParameterBridge {
  void updateParameter(String param, double value) {
    // Update C++ audio engine
    AudioEngine.setParameter(param, value);
    // Update JavaScript visualizer  
    _webViewController.runJavaScript('updateVisualParameter("$param", $value)');
    // Update Flutter UI
    _parameterModel.setParameter(param, value);
  }
}
```

### WebView Communication
```javascript
// JavaScript side - receive parameter updates from Flutter
window.addEventListener('message', (event) => {
  const { parameter, value } = event.data;
  updateVisualization(parameter, value);
});

// Send touch interactions back to Flutter
function onCanvasTouch(x, y) {
  window.parent.postMessage({
    type: 'canvasTouch',
    x: x, y: y
  }, '*');
}
```

### Audio-Visual Mapping
```dart
// Map audio parameters to visual properties
final audioVisualMap = {
  'filterCutoff': 'dimension',      // Filter → 4D morphing
  'resonance': 'rotationSpeed',     // Resonance → Rotation
  'oscillatorFreq': 'colorShift',   // Pitch → Color
  'envelopeAttack': 'morphFactor',  // Envelope → Geometry
  'effectsWet': 'glitchIntensity',  // Effects → Visual FX
};
```

## 🚨 Common Pitfalls to Avoid

1. **Performance bottlenecks**: Don't update visuals on every audio sample - use 60fps update loop
2. **Platform fragmentation**: Test WebView behavior varies significantly across platforms
3. **Audio latency**: Ensure C++ engine bypasses Flutter for real-time audio
4. **Memory leaks**: Properly dispose WebView and audio resources
5. **Gesture conflicts**: Coordinate touch handling between Flutter and WebView

## 🎯 Success Metrics

### Minimum Viable Product
- ✅ Synthesizer produces audio on primary platform
- ✅ 4D visuals react to audio parameters  
- ✅ Basic UI controls work (keyboard, XY pad)
- ✅ One platform builds and runs successfully

### Production Ready
- ✅ All platforms build and deploy
- ✅ AI preset generation works with multiple LLM providers
- ✅ Microphone input processing and visualization
- ✅ Smooth 60fps performance with low audio latency
- ✅ Polished UI with proper error handling

## 🔄 Iterative Development Approach

1. **Get basic audio working first** - Even sine wave generation is a win
2. **Add simple visualizer** - Even static 4D cube shows integration works
3. **Connect one parameter** - Prove the bridge concept works
4. **Expand gradually** - Add more parameters and features incrementally
5. **Polish and optimize** - Performance tuning and visual improvements

## 💡 Creative Integration Ideas

- **Gesture recording**: Save and replay touch patterns that control both audio and visuals
- **Preset morphing**: Smoothly transition between different audio-visual combinations
- **Collaborative sessions**: Multiple users can interact with shared 4D space
- **Performance mode**: Full-screen visuals with minimal UI for live performance
- **Educational mode**: Show mathematical relationships between audio and 4D geometry

---

**Remember**: The goal is a **cohesive audio-visual instrument**, not separate audio and visual components. Every interaction should feel unified and responsive across all three layers (Flutter UI, C++ Audio, WebGL Visuals).