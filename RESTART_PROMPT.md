# RESTART_PROMPT.md - Instructions for New Claude Instance

## 🎯 IMMEDIATE CONTEXT

You are continuing work on **Synther**, a cross-platform audio synthesizer app with ambitious monetization goals. The project is in active development with significant progress already made.

### First Steps:
1. **READ THESE FILES IN ORDER**:
   - `CLAUDE.md` - Contains complete project overview and current status
   - `PHASE_1_SUMMARY.md` - Original project context
   - `CLAUDE_BUILD.md` - Deployment and monetization strategy

2. **UNDERSTAND THE GOAL**:
   - Build a professional audio synthesizer app
   - Target: 100,000 monthly active users Year 1
   - Revenue goal: $100,000+ through ads and subscriptions
   - Platforms: iOS, Android, Web (Flutter framework)

3. **CURRENT STATE**:
   - ✅ Web audio synthesis is FIXED (was broken)
   - ✅ Visualizer integration is FIXED
   - ✅ Android native audio (Oboe) is IMPLEMENTED
   - ✅ iOS native audio (Core Audio) is IMPLEMENTED
   - ✅ Firebase backend is COMPLETE
   - 🚧 AdMob integration is NEXT
   - 🚧 In-App Purchases need implementation

## 💻 HOW TO WORK ON THIS PROJECT

### Development Approach:
1. **BE IMPLEMENTATION-FOCUSED** - The user wants working code, not discussions
2. **FOLLOW THE MONETIZATION STRATEGY** - Every feature should support the business model
3. **MAINTAIN CODE QUALITY** - This is a commercial product, not a prototype
4. **TEST EVERYTHING** - Use `flutter run` to verify changes work

### Key Technical Details:
- **Framework**: Flutter (Dart) for cross-platform UI
- **Audio Engine**: C++ with platform-specific implementations
- **Web Audio**: Complete Web Audio API implementation in Dart
- **Android Audio**: Oboe library for <10ms latency
- **iOS Audio**: Core Audio with AudioUnit
- **Backend**: Firebase (Auth, Firestore, Analytics, Storage)
- **Monetization**: AdMob ads + IAP subscriptions ($25/$99/$199 tiers)

### Code Organization:
```
lib/
├── core/               # Audio backends, Firebase, parameter management
├── features/           # UI components (xy_pad, keyboard, presets, etc.)
└── utils/             # Helper utilities

android/                # Android-specific code (Oboe integration)
ios/                   # iOS-specific code (Core Audio)
assets/visualizer/     # WebGL 4D visualizer files
```

## 🚀 WHAT TO DO NEXT

### PRIORITY 1: Complete AdMob Integration
Create `lib/features/ads/ad_manager.dart` with:
- Banner ads for free users
- Interstitial ads between sessions
- Rewarded ads for temporary premium features
- Frequency capping to prevent user annoyance
- Automatic hiding for premium users

### PRIORITY 2: Implement In-App Purchases
Create `lib/features/premium/premium_manager.dart` with:
- Three subscription tiers (Plus $25, Pro $99, Studio $199)
- Receipt validation
- Restore purchases functionality
- Integration with Firebase for premium status

### PRIORITY 3: Test & Deploy
1. Run `flutter build apk --release` for Android
2. Run `flutter build ios --release` for iOS
3. Test on physical devices
4. Set up Firebase project
5. Configure app store listings

## 🎨 PROJECT PHILOSOPHY

### User Experience Goals:
- **Professional Quality**: This competes with $100+ music apps
- **Low Latency**: <10ms audio latency on supported devices
- **Visual Feedback**: 4D visualizer responds to all parameters
- **Intuitive Controls**: XY pad and knobs feel responsive

### Monetization Philosophy:
- **Free Tier**: Fully functional with ads, limited presets
- **Plus Tier ($25/year)**: No ads, 50 presets, collaboration
- **Pro Tier ($99/year)**: Cloud sync, 200 presets, all features
- **Studio Tier ($199/year)**: Commercial use, priority support

### Technical Excellence:
- Platform-specific optimizations (not generic)
- Real-time audio processing without glitches
- 60fps visualizations with audio sync
- Scalable cloud backend

## ⚠️ CRITICAL WARNINGS

1. **DO NOT BREAK EXISTING FUNCTIONALITY**
   - Web audio synthesis is working - don't modify without testing
   - Visualizer bridge is working - maintain the iframe path structure
   - Native audio implementations are complete - test before changing

2. **MAINTAIN ARCHITECTURE PATTERNS**
   - Use Provider for state management
   - Follow the AudioBackend interface pattern
   - Keep platform-specific code isolated
   - Preserve the parameter synchronization flow

3. **RESPECT THE BUSINESS MODEL**
   - Every feature must support monetization goals
   - Premium features must provide clear value
   - Free tier must be good enough to attract users
   - But limited enough to encourage upgrades

## 📊 SUCCESS METRICS

You're building toward:
- 100,000 monthly active users
- 3-5% premium conversion rate
- $100,000+ annual revenue
- 4.5+ star app store rating
- <2% crash rate
- <10ms audio latency (native platforms)

## 🔧 COMMON COMMANDS

```bash
# Run the app
flutter run -d chrome        # Web browser
flutter run -d android       # Android device
flutter run -d ios          # iOS device

# Build for production
flutter build apk --release
flutter build ios --release
flutter build web --release

# Check for issues
flutter doctor
flutter analyze

# Update dependencies
flutter pub get
flutter pub upgrade
```

## 💡 FINAL NOTES

1. **The user expects rapid progress** - Implement features completely, don't just plan
2. **Code quality matters** - This is a commercial product, not a hackathon project
3. **Stay focused on monetization** - Every decision should support the business model
4. **Test on real devices** - Emulators don't show audio latency accurately
5. **Read CLAUDE.md first** - It has the complete current status

When you start, acknowledge that you've read this document and understand:
- The current project state
- The monetization goals
- What needs to be done next
- The technical architecture

Then proceed directly to implementation. The user values working code over lengthy explanations.

Good luck! This project has potential to be a significant commercial success. 🚀