# Synther - Quick Start Testing Guide 🎵

## Fastest Way to Test on Your Android Phone

### 1. Install Flutter (One-Time Setup)
```bash
# Windows: Download from https://flutter.dev/docs/get-started/install/windows
# Mac/Linux: Download from https://flutter.dev/docs/get-started/install

# Add to PATH and verify:
flutter doctor
```

### 2. Enable USB Debugging on Phone
1. Settings → About Phone → Tap "Build Number" 7 times
2. Settings → Developer Options → Enable "USB Debugging"
3. Connect phone via USB cable
4. Accept "Allow USB debugging" prompt

### 3. Run the App

#### Windows:
Double-click `test_android.bat` and choose option 1

#### Mac/Linux:
```bash
./test_android.sh
# Choose option 1
```

#### Or manually:
```bash
cd Synther
flutter run
```

## What You'll See

### Working Features ✅
- **XY Pad**: Touch to play notes with effects
- **Keyboard**: Piano keyboard with velocity
- **Controls**: All synthesis parameters
- **Visualizer**: 4D WebGL graphics (may work on some devices)
- **Presets**: Save/load sounds
- **LLM Presets**: AI-generated sounds (needs API key)

### Monetization (Test Mode) 💰
- **Test Banner Ad**: Bottom of screen
- **Upgrade Button**: Top right (yellow star)
- **Premium Tiers**: View subscription options
- **Test Purchases**: Won't charge real money

## Quick Commands

```bash
# Just run it
flutter run

# Build APK to share
flutter build apk
# APK at: build/app/outputs/flutter-apk/app-release.apk

# See device logs
flutter logs
```

## Troubleshooting

### "No devices found"
- Check USB cable connection
- Ensure USB debugging is enabled
- Try `adb devices` to verify

### "Build failed"
```bash
flutter clean
flutter pub get
flutter run
```

### No sound
- Check phone volume
- Grant microphone permission when prompted
- Restart the app

## Test Checklist

- [ ] App launches
- [ ] Can play notes on XY pad
- [ ] Keyboard produces sound
- [ ] Knobs change sound
- [ ] Test ad appears at bottom
- [ ] Upgrade button works
- [ ] No crashes

## What's Next?

1. **Note any issues** you find
2. **Try all features** - XY pad, keyboard, controls
3. **Test monetization** - ads and upgrade flow
4. **Share feedback** on performance and UI

## Ready to Rock! 🚀

The app is in test mode with:
- Test ads (won't earn revenue)
- Test purchases (won't charge you)
- Debug features enabled

Perfect for development testing!