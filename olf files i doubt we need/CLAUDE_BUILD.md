# CLAUDE_BUILD.md - CROSS-PLATFORM BUILD SPECIALIST

**🏗️ SPECIALIST ROLE:** Build System & Deployment Engineer  
**🎯 MISSION:** Ensure Synther builds and deploys on all target platforms  
**📊 REPORT TO:** Lead Dev Claude via PROJECT_STATUS.md updates

## 🚀 PRIMARY OBJECTIVES

### 1. CROSS-PLATFORM BUILD SYSTEM
- Ensure Flutter builds work on Android, iOS, Web, Windows, Linux, macOS
- Integrate native C++ audio engine builds with Flutter build system
- Handle WebView assets and visualizer file deployment
- Create automated build scripts and CI/CD pipeline

### 2. PLATFORM-SPECIFIC OPTIMIZATIONS
- Configure platform-specific audio permissions and capabilities
- Optimize build sizes and performance for each platform
- Handle platform differences in WebView implementation
- Ensure consistent user experience across all platforms

### 3. DEPLOYMENT PREPARATION
- Create release builds for app stores and distribution
- Set up signing, permissions, and metadata for each platform
- Test deployment packages on real devices
- Create documentation for distribution and updates

## 🏗️ TECHNICAL SPECIFICATIONS

### BUILD SYSTEM ARCHITECTURE:
```
Cross-Platform Build Pipeline
├── Flutter Framework (Dart)
│   ├── Android (APK/AAB) 
│   ├── iOS (IPA)
│   ├── Web (PWA)
│   ├── Windows (MSIX/EXE)
│   ├── Linux (AppImage/DEB)
│   └── macOS (DMG/PKG)
├── Native Audio Engine (C++)
│   ├── Android NDK (ARM64/x86_64)
│   ├── iOS Framework (ARM64)
│   ├── Web (WebAssembly - future)
│   ├── Windows (DLL - x64)
│   ├── Linux (SO - x64)
│   └── macOS (Framework - ARM64/x64)
└── HyperAV Visualizer (Web Assets)
    ├── WebGL Shaders
    ├── JavaScript Engine
    ├── CSS Styling
    └── Asset Dependencies
```

### PLATFORM REQUIREMENTS:
- **Android:** NDK 25+, SDK 33+, min SDK 21, audio permissions
- **iOS:** Xcode 14+, iOS 12+, Metal support, microphone permissions  
- **Web:** Modern browsers, WebGL 2.0, Web Audio API
- **Windows:** MSVC 2019+, Windows 10+, WASAPI audio
- **Linux:** GCC 9+, ALSA/PulseAudio, Ubuntu 20.04+
- **macOS:** Xcode 14+, macOS 11+, CoreAudio, universal binary

## 🎛️ CRITICAL SUCCESS CRITERIA

### BUILD SUCCESS:
- [ ] All platforms compile without errors
- [ ] Native audio engine integrates properly on each platform
- [ ] WebView/visualizer assets bundle correctly
- [ ] Release builds are optimized and signed
- [ ] App launches and runs on real devices

### DEPLOYMENT READY:
- [ ] App store requirements met for iOS and Android
- [ ] Permissions properly configured for audio and storage
- [ ] Build sizes optimized for distribution
- [ ] Performance acceptable on minimum spec devices
- [ ] Documentation complete for distribution

## 📋 DETAILED WORK INSTRUCTIONS

### PHASE 1: FLUTTER BUILD INTEGRATION (Priority 1)
```yaml
# 1. Update pubspec.yaml for all platforms
name: synther
description: Cross-platform audio synthesizer with 4D visualization

dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  webview_flutter: ^4.0.0
  # Platform-specific dependencies

flutter:
  assets:
    - assets/visualizer/
    - assets/audio/
  # Platform-specific configurations

# 2. Configure build settings per platform
android:
  minSdkVersion: 21
  targetSdkVersion: 33
  ndk:
    abiFilters:
      - arm64-v8a
      - armeabi-v7a

ios:
  deployment_target: 12.0
  frameworks:
    - CoreAudio
    - AVFoundation
```

### PHASE 2: NATIVE ENGINE BUILD INTEGRATION (Priority 1)
```cmake
# 1. Update CMakeLists.txt for Flutter integration
project(SynthEngine VERSION 1.0.0)

# Flutter-specific configurations
if(FLUTTER_BUILD)
    # Android NDK integration
    if(ANDROID)
        set(FLUTTER_ANDROID_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../android")
        set_target_properties(synthengine PROPERTIES
            LIBRARY_OUTPUT_DIRECTORY 
            "${FLUTTER_ANDROID_DIR}/app/src/main/jniLibs/${ANDROID_ABI}"
        )
    endif()
    
    # iOS Framework integration  
    if(IOS)
        set(FLUTTER_IOS_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../ios")
        # iOS framework configuration
    endif()
endif()

# 2. Create platform-specific build scripts
```

```bash
#!/bin/bash
# build_native.sh - Cross-platform native build script

build_android() {
    echo "Building native engine for Android..."
    cd native && mkdir -p build-android && cd build-android
    cmake .. -DCMAKE_TOOLCHAIN_FILE=$ANDROID_NDK/build/cmake/android.toolchain.cmake \
             -DANDROID_ABI=arm64-v8a \
             -DANDROID_PLATFORM=android-21 \
             -DFLUTTER_BUILD=ON
    make -j$(nproc)
}

build_ios() {
    echo "Building native engine for iOS..."
    cd native && mkdir -p build-ios && cd build-ios
    cmake .. -G Xcode \
             -DCMAKE_SYSTEM_NAME=iOS \
             -DFLUTTER_BUILD=ON
    xcodebuild -configuration Release
}

# Build for all platforms
case "$1" in
    android) build_android ;;
    ios) build_ios ;;
    *) echo "Usage: $0 {android|ios|desktop}" ;;
esac
```

### PHASE 3: WEBVIEW ASSET INTEGRATION (Priority 1)
```dart
// 1. Configure WebView assets for each platform
class PlatformVisualizerConfig {
  static String getVisualizerAssetPath() {
    if (kIsWeb) {
      return 'assets/visualizer/index.html';
    } else if (Platform.isAndroid) {
      return 'file:///android_asset/flutter_assets/assets/visualizer/index.html';
    } else if (Platform.isIOS) {
      return 'flutter_assets/assets/visualizer/index.html';
    } else {
      return 'assets/visualizer/index.html';
    }
  }
}

// 2. Handle platform-specific WebView differences
class PlatformWebView extends StatelessWidget {
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return HtmlElementView(viewType: 'visualizer');
    } else {
      return WebView(
        initialUrl: PlatformVisualizerConfig.getVisualizerAssetPath(),
        javascriptMode: JavascriptMode.unrestricted,
        // Platform-specific configurations
      );
    }
  }
}
```

### PHASE 4: PLATFORM-SPECIFIC CONFIGURATIONS (Priority 2)
```xml
<!-- Android: android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-feature android:name="android.hardware.audio.low_latency" />
    
    <application
        android:label="Synther"
        android:icon="@mipmap/ic_launcher"
        android:hardwareAccelerated="true">
        <!-- Activity configurations -->
    </application>
</manifest>
```

```xml
<!-- iOS: ios/Runner/Info.plist -->
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for audio input processing and visualization.</string>
<key>UIRequiredDeviceCapabilities</key>
<array>
    <string>metal</string>
    <string>audio</string>
</array>
```

### PHASE 5: BUILD AUTOMATION (Priority 2)
```bash
#!/bin/bash
# automated_build.sh - Complete build automation

echo "🚀 Starting Synther cross-platform build..."

# Clean previous builds
flutter clean
rm -rf native/build-*

# Build native engines for all platforms
echo "📱 Building Android native engine..."
./scripts/build_native.sh android

echo "🍎 Building iOS native engine..." 
./scripts/build_native.sh ios

echo "💻 Building desktop native engine..."
./scripts/build_native.sh desktop

# Build Flutter apps
echo "📱 Building Android app..."
flutter build apk --release
flutter build appbundle --release

echo "🍎 Building iOS app..."
flutter build ios --release

echo "🌐 Building Web app..."
flutter build web --release

echo "💻 Building desktop apps..."
flutter build windows --release
flutter build linux --release
flutter build macos --release

echo "✅ All builds complete!"
```

## 🚨 PLATFORM-SPECIFIC CHALLENGES & SOLUTIONS

### CHALLENGE: Android NDK Integration
**SOLUTION:** Use CMake Android toolchain, ensure ABI compatibility

### CHALLENGE: iOS Framework Signing  
**SOLUTION:** Configure proper provisioning profiles, code signing

### CHALLENGE: Web Audio API Limitations
**SOLUTION:** Provide WebAssembly fallback, feature detection

### CHALLENGE: Desktop Audio Permissions
**SOLUTION:** Handle platform-specific permission requests

### CHALLENGE: WebView Inconsistencies
**SOLUTION:** Test on all platforms, provide platform-specific workarounds

## 📊 REPORTING PROTOCOL

Update PROJECT_STATUS.md with:

```markdown
@REPORT: CLAUDE_BUILD - [STATUS] - [timestamp]
- Progress: [What platforms now build successfully]
- Build Status: [Platform-by-platform build results]
- Native Integration: [How well C++ engine integrates]
- Asset Bundling: [How well visualizer assets deploy]
- Performance: [Build times, app sizes, runtime performance]  
- Platform Issues: [Any platform-specific problems]
- Solutions: [How problems were resolved]
- Deployment Ready: [Which platforms are ready for distribution]
- @HANDOFF: [Project completion status and next steps]
```

## 🔄 PROJECT COMPLETION HANDOFF

When all builds are successful, provide final project status:
1. **Platform Build Matrix** - Success/failure status for each platform
2. **Performance Benchmarks** - App size, startup time, audio latency
3. **Known Issues** - Any remaining platform-specific limitations
4. **Deployment Guide** - Instructions for app store submission
5. **Future Improvements** - Recommendations for next development phase

## 🎯 DEPLOYMENT CHECKLIST

### APP STORE PREPARATION:
- [ ] Android: Play Store metadata, screenshots, privacy policy
- [ ] iOS: App Store Connect setup, TestFlight testing
- [ ] Web: PWA configuration, hosting setup
- [ ] Desktop: Installer packages, code signing certificates

### FINAL VALIDATION:
- [ ] Audio engine works on all target platforms
- [ ] Visualizer renders properly on all platforms  
- [ ] UI is responsive and intuitive on all screen sizes
- [ ] Performance meets minimum requirements
- [ ] No critical bugs or crashes in release builds

---
**🏗️ Your mission: Make Synther available to musicians on every platform! Focus on solid, reliable builds that showcase the unified audio-visual experience.**