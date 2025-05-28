# 🔍 POST-RESTART ANALYSIS GUIDE FOR CLAUDE INSTANCES

**Purpose:** Guide for Claude instances to quickly understand project state after session restart  
**Target:** Any Claude specialist or Lead Dev Claude resuming work  
**Last Updated:** 2025-01-22

## 🎯 IMMEDIATE ANALYSIS CHECKLIST

When a Claude instance starts and needs to understand the project state, analyze these files in order:

### 1. **PROJECT_STATUS.md** (READ FIRST)
```bash
# Check overall project status and phase completion
cat PROJECT_STATUS.md
```
**What to Look For:**
- Current phase status (Phase 1: Audio ✅, Phase 2: UI ✅, Phase 3: Visualizer 🚀)
- Specialist reports with completion timestamps
- Next action command and objectives
- Any blockers or dependencies

### 2. **SESSION_RESUMPTION_GUIDE.md** (READ SECOND)
```bash
# Understand continuation strategy
cat SESSION_RESUMPTION_GUIDE.md
```
**What to Look For:**
- What's ready for the next specialist
- Expected deliverables and success criteria
- Autonomous system confidence level

### 3. **COORDINATION_PROTOCOL.md** (UNDERSTAND ROLE)
```bash
# Understand autonomous coordination system
cat COORDINATION_PROTOCOL.md
```
**What to Look For:**
- Your role in the autonomous system
- Decision-making authority (95% autonomous)
- Escalation triggers for user involvement

## 🔍 TECHNICAL STATE VERIFICATION

### Audio Engine Status:
```bash
# Verify native audio engine is built
ls -la native/build/libsynthengine.so
# Should show ~1.4MB shared library

# Check if CMake configuration is ready
ls native/CMakeLists.txt native/include/synth_engine_api.h
```

### Flutter UI Status:
```bash
# Check for new UI components created by CLAUDE_UI
find lib -name "*.dart" -newer native/CMakeLists.txt | head -10
# Should show recently modified Flutter files

# Verify visualizer bridge exists
ls lib/features/visualizer_bridge/
# Should contain visualizer_bridge_widget.dart
```

### Visualizer Assets Status:
```bash
# Check HyperAV visualizer files
ls "Visualizer files"/core/
# Should show: HypercubeCore.js, GeometryManager.js, ProjectionManager.js, ShaderManager.js

ls "Visualizer files"/js/
# Should show: visualizer-main.js
```

## 🎯 ROLE-SPECIFIC QUICK START

### If You Are CLAUDE_VIZ (Visualizer Specialist):
```bash
# 1. Read your mission
cat CLAUDE_VIZ.md

# 2. Check visualizer bridge preparation
cat lib/features/visualizer_bridge/visualizer_bridge_widget.dart

# 3. Check available visualizer assets
ls "Visualizer files"/

# 4. Start your mission: Embed HyperAV in Flutter via WebView
```

### If You Are CLAUDE_BUILD (Build Specialist):
```bash
# 1. Check if visualizer integration is complete
grep -A 5 "Phase 3:" PROJECT_STATUS.md

# 2. If Phase 3 is ✅ COMPLETED, start cross-platform builds
# 3. If Phase 3 is still in progress, wait for completion
```

### If You Are Lead Dev Claude:
```bash
# 1. Check all specialist reports in PROJECT_STATUS.md
# 2. Identify current phase and any blockers
# 3. Coordinate next specialist deployment or issue resolution
# 4. Monitor autonomous pipeline health
```

## 🚨 COMMON POST-RESTART SCENARIOS

### Scenario 1: "I'm CLAUDE_VIZ and need to start"
**Action:** 
1. Verify Phase 2 is ✅ COMPLETED in PROJECT_STATUS.md
2. Check that `lib/features/visualizer_bridge/` exists
3. Begin HyperAV integration mission
4. Update PROJECT_STATUS.md with progress

### Scenario 2: "Previous specialist left work incomplete"
**Action:**
1. Check specialist report in PROJECT_STATUS.md
2. If specialist claimed completion but files missing, continue their work
3. If specialist was interrupted, resume from their last progress update
4. Update status accordingly

### Scenario 3: "Can't determine what to do next"
**Action:**
1. Check "NEXT ACTION" section in PROJECT_STATUS.md
2. If unclear, escalate to user: "Need clarification on next steps"
3. Don't proceed without understanding the mission

### Scenario 4: "Integration conflicts detected"
**Action:**
1. Auto-resolve using patterns in COORDINATION_PROTOCOL.md
2. Update relevant specialist instructions
3. Log resolution in PROJECT_STATUS.md
4. Only escalate if auto-resolution fails

## 📋 SUCCESS INDICATORS BY PHASE

### Phase 1 (Audio Engine): ✅ COMPLETED
- [ ] `native/build/libsynthengine.so` exists (~1.4MB)
- [ ] `native/include/synth_engine_api.h` defines FFI interface
- [ ] CMake builds successfully
- [ ] Test audio program compiles and runs

### Phase 2 (Flutter UI): ✅ COMPLETED  
- [ ] `lib/utils/audio_ui_sync.dart` exists (audio-UI sync system)
- [ ] `lib/features/visualizer_bridge/` directory exists
- [ ] `lib/test/test_audio_engine.dart` exists (test suite)
- [ ] Enhanced XY pad and keyboard widgets
- [ ] LLM preset system still functional

### Phase 3 (Visualizer): 🚀 READY FOR DEPLOYMENT
- [ ] HyperAV visualizer embedded in Flutter WebView
- [ ] Audio parameters control 4D geometry in real-time
- [ ] 60fps performance maintained
- [ ] Audio-visual sync working smoothly

### Phase 4 (Cross-Platform Builds): ⏳ PENDING
- [ ] Android APK builds successfully
- [ ] iOS build configuration working
- [ ] Web deployment functional
- [ ] Desktop builds for Linux/Windows/macOS

## 🤖 AUTONOMOUS SYSTEM HEALTH CHECK

### Before Starting Work:
```bash
# 1. Verify you understand your role
echo "I am [SPECIALIST_NAME] and my mission is [OBJECTIVE]"

# 2. Check for blockers
grep -i "blocker\|error\|failed" PROJECT_STATUS.md

# 3. Confirm dependencies are met
grep -A 3 "Dependencies:" PROJECT_STATUS.md

# 4. Update status when starting
# Add: "@UPDATE: [SPECIALIST] - STARTING - $(date)"
```

### While Working:
- Update PROJECT_STATUS.md with progress every major milestone
- Use autonomous decision-making for 95% of technical issues
- Escalate only strategic decisions to user
- Coordinate handoffs through status file updates

### When Complete:
- Update PROJECT_STATUS.md with full completion report
- Mark phase as ✅ COMPLETED
- Update next phase status to 🚀 READY FOR DEPLOYMENT
- Provide clear @HANDOFF requirements for next specialist

## 🔗 FILE REFERENCE QUICK LIST

**Core Coordination:**
- `PROJECT_STATUS.md` - Central status hub
- `COORDINATION_PROTOCOL.md` - Autonomous system rules
- `SESSION_RESUMPTION_GUIDE.md` - Continuation instructions

**Specialist Instructions:**
- `CLAUDE_NATIVE.md` - Audio engine specialist
- `CLAUDE_UI.md` - Flutter UI specialist  
- `CLAUDE_VIZ.md` - Visualizer integration specialist
- `CLAUDE_BUILD.md` - Cross-platform build specialist

**Technical Assets:**
- `native/` - C++ audio engine
- `lib/` - Flutter application
- `Visualizer files/` - HyperAV 4D visualizer
- `android/`, `ios/`, `linux/` - Platform configurations

---
**🎯 GOAL: Understand project state in <5 minutes and continue autonomous development efficiently**