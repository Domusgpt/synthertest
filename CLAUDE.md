# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Synther is a PROFESSIONAL-GRADE AUDIO SYNTHESIZER with revolutionary 4D polytope projection visualizations and AI-powered preset generation.**

### 🎨 Core Vision
- **Professional Audio Quality**: Studio-grade synthesis engine with <10ms latency, matching hardware synths
- **Revolutionary Visuals**: Real-time 4D polytope projections (hypercubes, hyperspheres, hypertetrahedra) that morph and react to audio
- **Aesthetic**: Vaporwave-inspired holographic UI with skeuomorphic + glassmorphic design language
- **AI Integration**: Natural language preset generation ("make a warm analog bass with subtle movement")
- **Cross-Platform**: One codebase for Android, iOS, Web, Windows, macOS, Linux

### 🏗️ Technical Architecture

1. **Flutter UI** - Glassmorphic interface floating over 4D visualizer
   - XY Pad: Kaoss-style performance controller mapped to 4D geometry
   - Keyboard: Velocity-sensitive with visual feedback
   - Morphing Controls: Parameters that transform both sound AND 4D shapes
   
2. **C++ Audio Engine** - Professional DSP with platform-specific optimization
   - Oboe (Android): Hardware-accelerated, <10ms latency
   - Core Audio (iOS): AudioUnit integration for pro audio
   - Web Audio API (Web): Full synthesis in browser
   - RTAudio (Desktop): ASIO/CoreAudio/JACK support
   
3. **HyperAV 4D Visualizer** - Mathematical beauty meets music
   - WebGL-powered polytope rendering engine
   - Real-time audio analysis drives dimensional morphing
   - Touch interactions affect both visuals and sound
   - 60fps synchronized with audio parameters
   
4. **Monetization Stack** - Sustainable freemium model
   - Firebase backend for cloud sync and analytics
   - AdMob with smart placement (non-intrusive)
   - Premium tiers: Plus ($25), Pro ($99), Studio ($199)
   - Target: 100K MAU, $100K+ revenue Year 1
   
5. **AI Preset System** - Multiple LLM providers with intelligent fallbacks
   - Natural language → synthesizer parameters
   - Learns from user preferences
   - Works offline with rule-based generation

## PROJECT STATUS (Updated: Current Session)

### ✅ COMPLETED IMPLEMENTATIONS

#### 1. Web Audio Backend (FIXED)
- **File**: `lib/core/web_audio_backend.dart`
- Complete Web Audio API implementation replacing broken volume-only version
- Full synthesis: oscillators, filters, ADSR envelopes, reverb, delay, distortion
- Proper parameter mapping and real-time control
- **Status**: Working, tested in browser

#### 2. Visualizer Integration (FIXED)
- **Files**: 
  - `assets/visualizer/index-flutter.html` - Flutter-specific bridge
  - `lib/features/visualizer_bridge/visualizer_bridge_widget_web.dart`
- Fixed iframe path issues (was looking for double "assets" path)
- Created Flutter↔JavaScript message bridge for parameter sync
- Basic WebGL hypercube visualization responding to audio parameters
- **Status**: Ready for testing, needs full HyperAV engine integration

#### 3. Android Native Build (COMPLETE)
- **Files**:
  - `android/app/src/main/cpp/CMakeLists.txt` - Oboe integration
  - `android/app/src/main/cpp/audio_platform_oboe.cpp` - Low-latency implementation
  - `android/app/src/main/kotlin/.../MainActivity.kt` - Permission handling
  - `android/app/src/main/kotlin/.../AudioChannelHandler.kt` - Platform channel
  - `lib/core/native_audio_backend_android.dart` - Dart bindings
- Oboe audio engine for <10ms latency
- Proper audio permissions and session management
- Native library loading and FFI bridge
- **Status**: Build-ready, needs testing on device

#### 4. iOS Native Build (COMPLETE)
- **Files**:
  - `ios/Runner/CMakeLists.txt` - Core Audio configuration
  - `ios/Runner/audio_platform_coreaudio.mm` - Low-latency implementation
  - `lib/core/native_audio_backend_ios.dart` - Dart bindings
  - `ios/Runner/Info.plist` - Audio permissions and background modes
- Core Audio implementation with AudioUnit
- Low-latency audio session configuration
- Background audio support
- **Status**: Build-ready, needs testing on device

#### 5. Firebase Backend (COMPLETE)
- **File**: `lib/core/firebase_manager.dart`
- Complete Firebase integration: Auth, Firestore, Analytics, Storage
- User profiles with premium tiers (Free, Plus $25, Pro $99, Studio $199)
- Cloud preset storage and sharing
- Usage analytics and session tracking
- Feature limits based on tier
- **Status**: Implementation complete, needs Firebase project setup

#### 6. Morph-UI System (COMPLETE) 🆕
- **Revolutionary UI System**: 4D visualizer as foundation with glassmorphic floating UI
- **Parameter-to-Visualizer Binding Engine**:
  - Dynamic mapping of audio parameters to visual effects
  - 16 visualizer parameters with 5 binding types
  - Real-time bidirectional synchronization
- **Layout Preset Manager**:
  - JSON-based persistence with SharedPreferences
  - Built-in presets: Default, Performance, Sound Design, Touch Grid
  - Import/export functionality for sharing
- **Performance Mode System**:
  - 4 modes: Normal, Performance, Minimal, Visualizer Only
  - Collapsible UI with edge swipes and pinch gestures
  - Auto-hide functionality with configurable timer
- **Advanced Gesture Recognition**:
  - 8 gesture types including multi-touch and rotation
  - Haptic feedback integration
  - Edge detection zones for UI control
- **Files Created**:
  - `lib/design_system/components/performance_mode_switcher.dart`
  - `lib/design_system/layout/collapsible_ui_controller.dart`
  - `lib/design_system/gestures/advanced_gesture_recognizer.dart`
  - `test/morph_ui_integration_test.dart`
- **Status**: Complete implementation with comprehensive testing

### 🚧 IN PROGRESS

#### 6. AdMob Integration (NEXT)
- Need to create `lib/features/ads/ad_manager.dart`
- Banner, interstitial, and rewarded ads
- Mediation with Meta Audience Network
- Frequency capping to prevent ad fatigue
- Premium users see no ads

#### 7. In-App Purchase Implementation
- Need to create `lib/features/premium/premium_manager.dart`
- Three subscription tiers matching Firebase model
- Receipt validation and restoration
- Integration with Firebase for premium status

### 📋 TODO LIST

1. **Enhanced LLM Preset System**
   - Multiple providers: Hugging Face, Groq, Together, Cohere, Mistral
   - Advanced local generation algorithms
   - Provider reliability tracking

2. **Granular Synthesis**
   - File loading and grain management
   - Real-time granular processing
   - Integration with main synthesis engine

3. **MIDI Export**
   - Premium feature for Pro/Studio tiers
   - Export performances as MIDI files
   - Integration with DAWs

### 🏗️ BUILD & DEPLOYMENT STRATEGY

#### Phase 1: Core Functionality (Current)
- ✅ Fix web audio synthesis
- ✅ Fix visualizer integration
- ✅ Android native build with Oboe
- ✅ iOS native build with Core Audio
- ✅ Firebase backend infrastructure
- 🚧 AdMob integration
- 🚧 IAP implementation

#### Phase 2: Monetization Launch
- App store listings (Google Play, Apple App Store)
- Web deployment with limited features
- Marketing campaign launch
- A/B testing ad placements
- Premium tier optimization

#### Phase 3: Growth & Enhancement
- Enhanced LLM presets
- Granular synthesis
- MIDI export
- Social features
- Collaboration tools

### 📊 TARGET METRICS (Year 1)
- **Users**: 100,000 MAU
- **Conversion**: 3-5% to premium
- **Revenue**: $100,000+ (ads + subscriptions)
- **Premium Distribution**:
  - Plus ($25): 60% of premium users
  - Pro ($99): 30% of premium users
  - Studio ($199): 10% of premium users

### 🔧 TECHNICAL DEBT & ISSUES
1. Need to properly organize native/ directory structure
2. Desktop platforms (Windows, Linux, macOS) not implemented
3. Full HyperAV visualizer modules need copying to assets
4. Need comprehensive error handling in audio backends
5. Memory management optimization needed

### 🚀 IMMEDIATE NEXT STEPS (CRITICAL PRIORITIES)

#### TODAY's Focus (from ULTIMATE_DEVELOPMENT_PLAN.md)
1. **Fix Web Audio** (4 hours) - CRITICAL
   - Web build only controls volume, needs full synthesis implementation
   - Implement oscillators, filters, envelopes, effects in `lib/core/web_audio_backend.dart`
   - Test in browser with `flutter run -d chrome`

2. **Android Native Build** (4 hours) - CRITICAL  
   - Set up NDK and compile C++ engine for Android
   - Configure Oboe for low-latency audio
   - Test on physical device

3. **Visualizer Integration** (2 hours) - CRITICAL
   - Fix iframe path issues (currently broken)
   - Implement Flutter↔JavaScript parameter sync
   - Map audio parameters to 4D visual properties

#### Next Phase
1. Complete AdMob integration with mediation
2. Implement IAP with subscription handling  
3. Set up Firebase project and backend
4. Create app store assets
5. Beta test with 100-500 users

## Development Commands

### Quick Start Testing
```bash
# Windows: Quick Android test
test_android.bat

# Mac/Linux: Quick Android test  
./test_android.sh

# Or manually:
flutter run
```

### Building and Running
```bash
# Install Flutter dependencies
flutter pub get

# Run on current platform (debug mode)
flutter run

# Run specific platforms
flutter run -d android        # Android device/emulator
flutter run -d ios           # iOS device/simulator  
flutter run -d chrome        # Web browser
flutter run -d linux         # Linux desktop
flutter run -d windows       # Windows desktop
flutter run -d macos         # macOS desktop

# Build for production
flutter build apk --release             # Android APK
flutter build appbundle --release       # Android App Bundle
flutter build ios --release             # iOS
flutter build web --release             # Web
flutter build linux --release           # Linux
flutter build windows --release         # Windows
flutter build macos --release           # macOS
```

### Native Audio Engine
```bash
# Build C++ audio engine (from native_audio - Copy/ directory)
cd "native_audio - Copy"
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)

# For Android cross-compilation
cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
         -DANDROID_ABI=arm64-v8a \
         -DANDROID_PLATFORM=android-21
make -j$(nproc)
```

### Testing
```bash
# Run all Dart tests
flutter test

# Run specific test suites
flutter test test/complete_app_test.dart      # Full app integration test
flutter test test/audio_integration_test.dart  # Audio engine tests
flutter test test/llm_preset_test.dart        # LLM preset generation
flutter test test/parameter_sync_test.dart    # Parameter synchronization
flutter test test/preset_system_test.dart     # Preset save/load
flutter test test/visualizer_integration_test.dart  # Visualizer bridge

# Test native engine (if built)
cd "native_audio - Copy/build"
make test

# Real device testing script
./run_real_tests.sh  # Comprehensive test suite
```

### Web Visualizer
```bash
# Serve standalone HyperAV visualizer
cd "Visualizer files"
python -m http.server 8000
# Visit http://localhost:8000

# Or use the working synthesizer
open WORKING_SYNTH.html
```

## Architecture Overview

### Core Integration Strategy
The project follows a **unified parameter system** where:
- Flutter UI controls trigger parameter changes
- Parameters are synchronized to C++ audio engine via FFI
- Same parameters drive WebGL visualizer updates
- All three systems react to the same parameter changes in real-time

### Directory Structure
```
lib/
├── main.dart                    # App entry point with multi-provider setup
├── app.dart                     # Main UI with bottom navigation (XY Pad, Keyboard, Controls)
├── core/                        # Audio engine integration layer
│   ├── synth_parameters.dart    # Central parameter model (ChangeNotifier)
│   ├── audio_backend.dart       # Abstract audio backend interface
│   ├── native_audio_backend.dart # Native C++ engine integration
│   ├── web_audio_backend.dart   # Web Audio API implementation
│   └── platform_audio_backend.dart # Platform-specific backend selection
├── features/                    # UI components and feature modules
│   ├── xy_pad/                  # Kaoss-style XY control pad
│   ├── keyboard/                # Piano keyboard widget
│   ├── shared_controls/         # Parameter control panels
│   ├── llm_presets/            # AI preset generation (multiple LLM APIs)
│   ├── microphone_input/       # Live audio input processing
│   └── presets/                # Preset save/load system
└── utils/                      # Platform utilities and helpers

native_audio - Copy/            # C++ audio engine source
├── src/
│   ├── synth_engine.cpp        # Main synthesis engine
│   ├── ffi_bridge.cpp          # Dart FFI interface
│   ├── audio_platform*.cpp    # RTAudio platform integration
│   ├── oscillator.h            # Oscillator implementations
│   ├── filter.h                # State-variable filter
│   ├── envelope.h              # ADSR envelope generator
│   └── reverb.h, delay.h       # Effects processing
└── CMakeLists.txt              # Cross-platform build configuration

Visualizer files/               # HyperAV 4D visualization engine
├── core/
│   ├── HypercubeCore.js        # 4D geometry mathematics
│   ├── GeometryManager.js      # Shape generation and morphing
│   ├── ProjectionManager.js    # 4D→2D projection system
│   └── ShaderManager.js        # WebGL shader management
├── js/visualizer-main.js       # Audio analysis and parameter mapping
└── css/                        # Neumorphic styling system
```

### Parameter Synchronization Flow
```
UI Control Input → SynthParametersModel.setParameter() 
                ↓
        [Parameter Validation & Clamping]
                ↓
        AudioBackend.setParameter() → C++ Engine (via FFI)
                ↓
        notifyListeners() → UI Updates
                ↓
        [Future: WebView bridge] → JavaScript Visualizer
```

## Key Implementation Details

### FFI Integration Pattern
The project uses Dart FFI to bridge Flutter and C++:
- `synth_engine_bindings.dart` - Generated FFI bindings
- `ffi_bridge.cpp` - C wrapper for C++ synthesis engine
- Platform-specific backends handle initialization and audio I/O

### Audio Engine Features
- **Oscillators**: Anti-aliased waveforms (sine, square, triangle, sawtooth, noise, pulse)
- **Filters**: State-variable filter with multiple modes (LP, HP, BP, notch, shelving)
- **Envelopes**: ADSR with curve types (linear, exponential, logarithmic, S-curve)
- **Effects**: Delay and reverb with parameter control
- **Real-time**: Thread-safe parameter updates, low-latency audio processing

### LLM Preset Generation
Multiple API support with fallbacks:
- Hugging Face (Free tier with Mistral-7B)
- Groq (Fast inference, free tier)
- Gemini (Google, requires API key)
- Rule-based fallback (no API required)
- Web-only JavaScript generator for browser builds

Configure API keys in `lib/config/api_config.dart`.

### Cross-Platform Considerations
- **Android**: NDK integration, audio permissions, minimum SDK 21
- **iOS**: Framework setup, Metal rendering, minimum iOS 12.0
- **Web**: WebGL + Web Audio API, browser compatibility
- **Desktop**: Native audio drivers, OpenGL support

## Future Integration Work

### Phase 1: Core Unification
1. **Native Engine Organization**
   - Move scattered C++ files to proper `native/` structure
   - Ensure CMake builds work for all platforms
   - Test basic audio output on target platforms

2. **Visualizer Embedding**
   - Embed HyperAV WebGL visualizer in Flutter using WebView
   - Create bidirectional JavaScript↔Dart communication bridge
   - Map audio parameters to 4D visual properties

3. **Unified Parameter Bridge**
   - Create `lib/core/parameter_bridge.dart` to sync all three systems
   - Ensure UI controls affect both audio engine and visualizer
   - Implement smooth 60fps visual updates

### Phase 2: Advanced Features
1. **Audio-Visual Mapping**
   - Filter cutoff → 4D dimension morphing
   - Resonance → Geometric transformation intensity
   - Oscillator frequency → Color spectrum
   - Envelope → Spatial dynamics
   - Effects → Visual effects (glitch, blur)

2. **Touch Integration**
   - XY Pad gestures control both audio AND 4D geometry
   - Coordinate touch handling between Flutter and WebView
   - Visual feedback for all parameter changes

3. **Performance Optimization**
   - Maintain 60fps visuals with low-latency audio
   - Optimize WebView behavior across platforms
   - Memory management for audio and visual resources

## Development Workflow

### Getting Started
1. Ensure Flutter SDK and platform tools are installed
2. Run `flutter doctor` to verify setup
3. Test basic app launch: `flutter run`
4. Build native engine separately to verify C++ compilation
5. Test on target platforms incrementally

### Debugging
```bash
# Enable detailed logging
flutter run --debug --verbose

# Audio engine debugging
cmake .. -DCMAKE_BUILD_TYPE=Debug -DENABLE_AUDIO_DEBUG=ON

# Platform-specific debugging
flutter run -d android --debug    # Android debugging
flutter run -d ios --debug        # iOS debugging
```

### Common Issues & Solutions

#### Audio Not Working
- Check platform permissions (microphone access required)
- Verify audio session is properly initialized
- Restart the app
- For web: ensure browser supports Web Audio API

#### Build Failures  
```bash
# Clean rebuild
flutter clean
flutter pub get
flutter run
```
- Verify all dependencies and platform SDKs
- Check Flutter doctor: `flutter doctor -v`
- For Android: ensure NDK is installed
- For iOS: run `pod install` in ios/ directory

#### Visual/Performance Issues
- Update graphics drivers
- Reduce visual quality settings in app
- Check for memory leaks with Flutter DevTools
- Monitor frame rate - should maintain 60fps

#### Platform-Specific Issues
- **Android**: Enable USB debugging, accept permissions
- **iOS**: Trust developer certificate, check provisioning
- **Web**: Use Chrome/Edge for best WebGL performance
- **Desktop**: Install platform-specific audio drivers

## Critical Success Metrics
- [ ] Audio engine produces sound on primary platform
- [ ] 4D visualizer renders and reacts to audio parameters
- [ ] UI controls affect both audio and visual systems
- [ ] Cross-platform builds succeed (Android, iOS, Web minimum)
- [ ] AI preset generation creates working presets
- [ ] Performance maintains 60fps visuals with low audio latency

## Autonomous Development System

### Specialist Claude Coordination
This project uses an **autonomous coordination system** with specialized Claude instances:
- **CLAUDE_NATIVE.md** - Audio engine specialist (C++/FFI expert)
- **CLAUDE_UI.md** - Flutter UI specialist (includes LLM preset preservation)
- **CLAUDE_VIZ.md** - Visualizer integration specialist (WebGL/4D graphics)
- **CLAUDE_BUILD.md** - Cross-platform build specialist
- **PROJECT_STATUS.md** - Central coordination hub
- **COORDINATION_PROTOCOL.md** - Autonomous system protocols

### How to Use the System
1. Run specialist Claudes in sequence: `claude-code --memory CLAUDE_NATIVE.md`
2. Each specialist reports progress and integration status
3. Lead Dev Claude (main CLAUDE.md) coordinates handoffs and resolves issues
4. 95% autonomous operation - only strategic decisions escalated to user

### LLM Preset System Integration
- **Preserved Components**: All existing LLM preset functionality in `lib/features/llm_presets/`
- **Integration Point**: LLM presets → SynthParametersModel → Audio engine
- **API Support**: Hugging Face, Groq, Gemini, rule-based fallback, web-only JS generator
- **Testing Required**: Verify LLM presets work with new audio engine integration

## Notes for Future Development
- Focus on **unified experience** - every interaction should feel cohesive across UI, audio, and visuals
- Test frequently on target platforms - WebView behavior varies significantly
- Prioritize audio latency over visual complexity if trade-offs are needed
- The goal is an **audio-visual instrument**, not separate audio and visual components
- **LLM presets must remain functional** throughout all integration phases

## SESSION SUMMARY FOR /clear

### What We Accomplished
1. **Fixed Critical Issues**:
   - Web audio now has full synthesis (was only controlling volume)
   - Visualizer iframe path corrected and Flutter bridge created
   - Both issues were blocking basic functionality

2. **Implemented Platform-Specific Audio**:
   - Android: Oboe integration for <10ms latency
   - iOS: Core Audio with AudioUnit for professional audio
   - Proper permission handling and audio session management
   - Platform-specific Dart backends with FFI bridge

3. **Built Monetization Infrastructure**:
   - Complete Firebase backend (Auth, Firestore, Analytics, Storage)
   - User profiles with premium tier system
   - Cloud preset storage and sharing
   - Usage tracking and analytics
   - Foundation for $100K revenue target

4. **Project Structure**:
   - Updated pubspec.yaml with all required dependencies
   - Created proper platform-specific implementations
   - Maintained clean separation of concerns

### Key Files Created/Modified
- `lib/core/web_audio_backend.dart` - Complete Web Audio synthesis
- `assets/visualizer/index-flutter.html` - Flutter-WebGL bridge
- `android/app/src/main/cpp/audio_platform_oboe.cpp` - Android audio
- `ios/Runner/audio_platform_coreaudio.mm` - iOS audio
- `lib/core/firebase_manager.dart` - Complete Firebase integration
- `lib/core/native_audio_backend_android.dart` - Android Dart backend
- `lib/core/native_audio_backend_ios.dart` - iOS Dart backend

### What's Left to Do
1. **Immediate** (for MVP):
   - AdMob integration with mediation
   - In-app purchase implementation
   - Test builds on physical devices
   - Set up Firebase project

2. **Phase 2** (for launch):
   - Enhanced LLM preset system
   - App store listings
   - Marketing materials
   - Beta testing program

3. **Phase 3** (post-launch):
   - Granular synthesis
   - MIDI export
   - Desktop platform support
   - Social features

### Technical Notes
- The project now has a solid foundation for monetization
- Audio latency should be excellent on mobile platforms
- Web version works but native versions will perform better
- All code follows the original architecture patterns
- Firebase provides scalable backend infrastructure

### Ready for Next Session
The project is now in a state where you can:
1. Run `flutter build apk` for Android testing
2. Run `flutter build ios` for iOS testing  
3. Test web version with `flutter run -d chrome`
4. Continue with AdMob/IAP implementation
5. Begin app store preparation

The comprehensive monetization strategy from the deployment docs has been fully considered and partially implemented. The foundation is solid for achieving the 100K MAU and $100K revenue targets.