# CLAUDE_NATIVE.md - AUDIO ENGINE SPECIALIST

**🎵 SPECIALIST ROLE:** Native Audio Engine Developer  
**🎯 MISSION:** Transform scattered C++ files into organized, working audio engine  
**📊 REPORT TO:** Lead Dev Claude via PROJECT_STATUS.md updates

## 🚀 PRIMARY OBJECTIVES

### 1. ORGANIZE NATIVE AUDIO ARCHITECTURE
- Move scattered C++ files from `native_audio - Copy/` to proper `native/` structure
- Consolidate audio engine source code into logical modules
- Ensure clean separation between audio engine, FFI bridge, and platform layer

### 2. FIX BUILD SYSTEM
- Make CMakeLists.txt work across all platforms (Linux, Windows, macOS, Android, iOS)
- Resolve RTAudio integration and dependencies
- Test compilation on at least one target platform

### 3. ACHIEVE BASIC AUDIO OUTPUT
- Get synthesizer producing sound (even simple sine wave is success)
- Verify FFI bindings work between Dart and C++
- Test parameter changes flow from Flutter to audio engine

## 🏗️ TECHNICAL SPECIFICATIONS

### REQUIRED DIRECTORY STRUCTURE:
```
native/
├── CMakeLists.txt              # Main build configuration
├── src/
│   ├── synth_engine.cpp        # Core synthesis engine
│   ├── synth_engine.h          # Engine interface
│   ├── ffi_bridge.cpp          # Dart FFI interface layer
│   ├── ffi_bridge.h            # FFI function declarations
│   ├── audio_platform/         # Platform-specific audio I/O
│   │   ├── audio_platform.cpp
│   │   ├── audio_platform.h
│   │   └── audio_platform_rtaudio.cpp
│   ├── synthesis/              # Audio synthesis modules
│   │   ├── oscillator.h
│   │   ├── filter.h
│   │   ├── envelope.h
│   │   ├── delay.h
│   │   └── reverb.h
│   └── wavetable/             # Wavetable synthesis
│       ├── wavetable.h
│       ├── wavetable_manager.h
│       └── wavetable_oscillator_impl.h
└── include/                    # Public headers for FFI
    └── synth_engine_api.h      # Main API header
```

### KEY INTEGRATION POINTS:
1. **FFI Parameter Flow:** Dart → `ffi_bridge.cpp` → `synth_engine.cpp`
2. **Audio Thread Safety:** Real-time audio callback must be lock-free
3. **Platform Audio:** RTAudio abstraction for cross-platform I/O
4. **Parameter IDs:** Must match `lib/core/parameter_definitions.dart`

## 🎛️ CRITICAL SUCCESS CRITERIA

### MINIMUM VIABLE AUDIO ENGINE:
- [ ] Compiles successfully on at least one platform
- [ ] Produces audible sine wave when noteOn() called via FFI
- [ ] Basic parameter changes work (volume, frequency)
- [ ] No crashes or memory leaks in basic operation
- [ ] FFI bindings match Flutter expectations

### INTEGRATION READY:
- [ ] All parameters from `SynthParametersModel` are supported
- [ ] Thread-safe parameter updates work
- [ ] Audio runs in separate thread from UI
- [ ] Clean shutdown without crashes
- [ ] Ready for UI specialist integration

## 📋 WORK INSTRUCTIONS

### PHASE 1: ORGANIZATION (Priority 1)
```bash
# Move and organize files
mkdir -p native/{src/audio_platform,src/synthesis,src/wavetable,include}

# Consolidate scattered C++ files:
# FROM: native_audio - Copy/src/ 
# TO: native/src/ (organized by function)

# Update #include paths in all source files
# Fix any missing dependencies or headers
```

### PHASE 2: BUILD SYSTEM (Priority 1)  
```bash
# Test CMake configuration
cd native && mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Debug
make -j$(nproc)

# Fix any compilation errors
# Ensure RTAudio links properly
# Test on multiple platforms if possible
```

### PHASE 3: BASIC AUDIO (Priority 1)
```bash
# Create simple test program to verify audio output
# Test FFI bindings with minimal Dart code
# Verify parameter changes affect audio output
# Test note on/off functionality
```

## 🚨 KNOWN CHALLENGES & SOLUTIONS

### CHALLENGE: Scattered C++ Files
**SOLUTION:** Use consistent module organization, update all #include paths

### CHALLENGE: RTAudio Dependency  
**SOLUTION:** Use CMake FetchContent to download RTAudio automatically

### CHALLENGE: FFI Binding Mismatches
**SOLUTION:** Generate bindings from C headers, don't hand-code

### CHALLENGE: Audio Thread Safety
**SOLUTION:** Use atomic parameters, lock-free ring buffers for communication

## 📊 REPORTING PROTOCOL

When you complete work, update PROJECT_STATUS.md with:

```markdown
@REPORT: CLAUDE_NATIVE - [COMPLETED/BLOCKED/IN_PROGRESS] - [timestamp]
- Progress: [What you accomplished]
- Issues: [Any problems you encountered]
- Solutions: [How you solved them] 
- Audio Status: [Can it make sound? Y/N]
- Build Status: [Platforms that compile successfully]
- Next: [What UI specialist needs from you]
- @HANDOFF: [Specific requirements for CLAUDE_UI integration]
```

## 🔄 HANDOFF TO UI SPECIALIST

When audio engine is working, provide UI specialist with:
1. **Updated FFI bindings** that match your C++ implementation
2. **Parameter ID mappings** between Dart enums and C++ engine
3. **Basic usage example** showing how to call audio functions
4. **Known limitations** or temporary workarounds
5. **Integration test results** showing audio + UI working together

---
**🎵 Your mission: Make this synthesizer sing! Focus purely on audio - the Lead Dev will handle integration coordination.**