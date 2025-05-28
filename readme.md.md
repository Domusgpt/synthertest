# HyperAV Synthesizer

A next-generation audio synthesizer that combines high-performance C++ audio processing with stunning 4D audio-reactive visualizations. Features intuitive touch controls, AI-powered preset generation, and cross-platform support.

## 🎵 Key Features

- **Intuitive UI**: Morphing XY Pad and flexible keyboard interface built over reactive 4D visualizations
- **High-Performance Audio**: Low-latency C++ audio engine with Flutter FFI integration
- **Live Input Processing**: Real-time microphone input analysis and visualization
- **AI-Powered Presets**: Natural language generation of synthesizer presets using LLM integration
- **4D Audio Visualization**: HyperAV engine renders hypercubes, hyperspheres, and hypertetrahedra that react to audio in real-time
- **Cross-Platform**: Native performance on iOS, Android, Web, macOS, Windows, and Linux

## 🏗️ Architecture Overview

### Core Components

1. **Flutter UI Layer** (`lib/`)
   - XY Pad with musical scale mapping and 4D visual integration
   - Piano keyboard with multi-touch support
   - Parameter control panels overlaid on visualizations
   - Cross-platform responsive design

2. **C++ Audio Engine** (`native/`)
   - Real-time oscillators with anti-aliasing
   - State-variable filters with multiple modes
   - ADSR envelopes with curve types
   - Effects processing (delay, reverb)
   - RTAudio integration for cross-platform audio I/O

3. **HyperAV Visualizer** (`web/` and embedded in Flutter)
   - WebGL-powered 4D geometry rendering
   - Real-time audio analysis and visualization mapping
   - Direct canvas interaction for parameter control
   - Responsive design for mobile and desktop

4. **LLM Preset Engine** (`lib/features/llm_presets/`)
   - Natural language to synthesizer parameter mapping
   - Multiple API support (Hugging Face, Groq, Gemini)
   - Intelligent preset generation and suggestion

### Project Structure

```
/
├── README.md                          # This file
├── CLAUDE.md                          # Claude Code instructions
├── lib/                              # Flutter/Dart source
│   ├── main.dart                     # App entry point
│   ├── app.dart                      # Main app widget
│   ├── core/                         # Core engine integration
│   ├── features/                     # UI components and features
│   └── utils/                        # Platform utilities
├── native/                           # C++ audio engine
│   ├── CMakeLists.txt               # Build configuration
│   └── src/                         # Engine source code
├── web/                             # HyperAV visualizer assets
│   ├── index.html                   # Standalone visualizer
│   ├── core/                        # WebGL engine
│   ├── js/                          # Audio analysis & UI
│   └── css/                         # Styling system
├── android/                         # Android platform files
├── ios/                            # iOS platform files
├── linux/                          # Linux platform files
├── macos/                          # macOS platform files
├── windows/                        # Windows platform files
└── docs/                           # Development documentation
```

## 🚀 Quick Start

### Prerequisites

1. **Flutter SDK** (latest stable)
2. **CMake** 3.16+
3. **Platform-specific tools**:
   - **Android**: Android Studio, NDK 25+
   - **iOS**: Xcode, CocoaPods
   - **Desktop**: Platform SDK (MSVC/GCC/Clang)

### Development Setup

```bash
# Clone and setup
git clone <repository-url>
cd hyperav-synthesizer

# Install Flutter dependencies
flutter pub get

# Build native audio engine
cd native
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
cd ../..

# Run on your target platform
flutter run                    # Current platform
flutter run -d chrome         # Web version
flutter run -d android        # Android device
flutter run -d ios            # iOS device
```

### Web-Only Version

For development or web-only deployment:

```bash
# Serve the HyperAV visualizer directly
cd web
python -m http.server 8000
# Visit http://localhost:8000
```

## 🎛️ Usage

### Basic Operation

1. **Enable Audio**: Grant microphone permissions for live input analysis
2. **Play Notes**: Use the piano keyboard or XY pad to generate sounds
3. **Visual Interaction**: Touch/click the 4D visualization to control parameters
4. **Generate Presets**: Use natural language to create new sounds ("warm bass with reverb")

### XY Pad Controls

- **X-Axis**: Musical pitch/frequency (mapped to 4D dimension morphing)
- **Y-Axis**: Filter cutoff/resonance (mapped to 4D geometric transformations)
- **Visual Feedback**: Real-time 4D geometry reacts to both audio and touch input

### Audio Visualization Mapping

- **Bass Frequencies** → Structural changes (dimension morphing, grid density)
- **Mid Frequencies** → Rotation speed and morphing intensity
- **High Frequencies** → Fine details (line thickness, glitch effects)
- **Musical Notes** → Color spectrum and geometric patterns
- **Audio Amplitude** → Overall visual intensity and scale

## 🛠️ Development

### Key Integration Points

1. **Audio Engine FFI**: `lib/core/audio_service.dart` bridges Flutter ↔ C++
2. **Visualizer Integration**: WebView embeds HyperAV with bidirectional communication
3. **Parameter Synchronization**: Unified parameter model drives both audio and visuals
4. **Cross-Platform Audio**: RTAudio provides consistent API across platforms

### Building for Production

```bash
# Android APK/Bundle
flutter build apk --release
flutter build appbundle --release

# iOS App Store
flutter build ios --release

# Desktop Applications
flutter build linux --release
flutter build macos --release
flutter build windows --release

# Web Application
flutter build web --release
```

### Testing

```bash
# Run all tests
flutter test

# Test audio engine separately
cd native/build
make test

# Test LLM integration
dart test/test_llm_api.dart
```

## 🎨 Customization

### Adding New Visualizations

1. Extend `core/GeometryManager.js` with new 4D primitives
2. Update shader programs in `core/ShaderManager.js`
3. Map new audio parameters in `js/visualizer-main.js`

### Audio Engine Extensions

1. Add new oscillator types in `native/src/synth_engine.cpp`
2. Implement effects in the effects chain
3. Update FFI bindings in `native/src/ffi_bridge.cpp`

### LLM Preset Expansion

1. Enhance prompt engineering in `lib/features/llm_presets/`
2. Add new parameter mapping logic
3. Integrate additional LLM providers

## 📱 Platform-Specific Notes

### Android
- Minimum SDK 21 (Android 5.0)
- Requires `RECORD_AUDIO` permission
- Hardware-accelerated graphics recommended

### iOS
- Minimum iOS 12.0
- Requires microphone usage description in Info.plist
- Metal API used for optimal performance

### Web
- Requires modern browser with WebGL and Web Audio API
- Chrome/Edge recommended for best performance
- Safari has some WebGL limitations

### Desktop
- Native audio drivers provide lowest latency
- Full OpenGL support for advanced visualizations
- Multi-monitor support for extended visual displays

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Test on multiple platforms
4. Submit a pull request with detailed description

## 📄 License

MIT License - see LICENSE file for details

## 🆘 Troubleshooting

### Common Issues

1. **Audio Not Working**: Check permissions and restart app
2. **Build Failures**: Ensure all dependencies are installed
3. **Visual Glitches**: Update graphics drivers
4. **Performance Issues**: Try reducing visual quality settings

### Debug Mode

```bash
# Enable detailed logging
flutter run --debug --verbose

# Audio engine debugging
cmake .. -DCMAKE_BUILD_TYPE=Debug -DENABLE_AUDIO_DEBUG=ON
```

---

**Made with 💜 for the future of interactive audio**

*Combining the mathematical beauty of 4D geometry with the emotional power of music*