# Android Testing Guide for Synther

## Prerequisites

### 1. Install Flutter on Your Development Machine
```bash
# Download Flutter SDK from https://flutter.dev/docs/get-started/install
# Extract and add to PATH

# Verify installation
flutter doctor
```

### 2. Enable Developer Mode on Your Android Phone
1. Go to Settings → About Phone
2. Tap "Build Number" 7 times
3. Go back to Settings → Developer Options
4. Enable:
   - Developer options
   - USB debugging
   - Install via USB (if present)

### 3. Connect Your Phone
1. Connect phone via USB cable
2. Accept "Allow USB debugging" prompt on phone
3. Verify connection:
```bash
flutter devices
# Should show your device
```

## Quick Test Build

### Option 1: Debug Build (Fastest)
```bash
cd /path/to/Synther

# Get dependencies
flutter pub get

# Run on connected device
flutter run

# This will:
# - Build debug APK
# - Install on your phone
# - Launch with hot reload enabled
# - Show console logs
```

### Option 2: Release APK Build
```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Build release APK
flutter build apk --release

# The APK will be at:
# build/app/outputs/flutter-apk/app-release.apk

# Install manually:
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Option 3: Split APKs (Smaller Size)
```bash
# Build split APKs by architecture
flutter build apk --split-per-abi

# This creates smaller APKs:
# - app-armeabi-v7a-release.apk (32-bit)
# - app-arm64-v8a-release.apk (64-bit)
# - app-x86_64-release.apk (Intel)
```

## Testing Checklist

### Core Features
- [ ] App launches without crashing
- [ ] Audio engine initializes (check status in app bar)
- [ ] XY Pad responds to touch
- [ ] Keyboard plays notes
- [ ] Parameter knobs adjust values
- [ ] Visualizer displays (if working)

### Monetization (Test Mode)
- [ ] Banner ad appears at bottom (test ad)
- [ ] "Upgrade" button visible in app bar
- [ ] Premium upgrade screen opens
- [ ] Can select different tiers
- [ ] Test purchases work (won't charge you)

### Performance
- [ ] Audio latency is acceptable
- [ ] No crackling or glitches
- [ ] UI remains responsive
- [ ] Visualizer runs smoothly

## Common Issues & Solutions

### Build Errors

1. **"SDK not found"**
```bash
# Set up Android SDK
flutter doctor --android-licenses
```

2. **"Gradle build failed"**
```bash
# Update Gradle
cd android
./gradlew clean
./gradlew build
```

3. **"Package name conflict"**
```bash
# Uninstall existing app first
adb uninstall com.domusgpt.sound_synthesizer
```

### Runtime Issues

1. **No sound**
- Check phone volume
- Grant microphone permission
- Restart the app

2. **Ads not showing**
- Normal in debug mode
- Test ads should appear
- Check internet connection

3. **Crashes on launch**
```bash
# View crash logs
adb logcat | grep -E "flutter|synther"
```

## Quick Development Setup

### 1. Create Test Script
Create `test_on_phone.sh`:
```bash
#!/bin/bash
echo "🚀 Building Synther for Android..."

# Clean and get dependencies
flutter clean
flutter pub get

# Build and run
flutter run --release

echo "✅ App should be running on your phone!"
```

### 2. Make it executable
```bash
chmod +x test_on_phone.sh
```

### 3. Run anytime
```bash
./test_on_phone.sh
```

## Firebase Test Setup (Optional)

### Quick Firebase Setup for Testing
1. Create a test Firebase project
2. Download `google-services.json`
3. Place in `android/app/`
4. The app will work without this, but with limited features

### Test User Flow
1. Launch app → Works without login
2. Try saving preset → Prompts for account
3. Create test account → Free tier active
4. Test upgrade flow → Shows subscriptions

## Wireless Debugging (Advanced)

### Setup Wireless ADB
```bash
# Connect phone via USB first
adb tcpip 5555

# Find phone's IP (Settings → About → IP address)
adb connect 192.168.1.XXX:5555

# Disconnect USB cable
# Now you can run Flutter wirelessly!
flutter run
```

## Performance Profiling

### Check Performance
```bash
# Run in profile mode
flutter run --profile

# Opens DevTools for:
# - CPU profiling
# - Memory usage
# - Network requests
# - Widget inspector
```

## Sharing APK with Others

### Create Shareable APK
```bash
# Build universal APK
flutter build apk --release

# Upload to Google Drive or send via:
# - Email (if <25MB)
# - Google Drive
# - WeTransfer
# - USB transfer
```

### Installation Instructions for Testers
1. Enable "Unknown sources" in Settings
2. Download APK
3. Tap to install
4. Grant requested permissions

## Next Steps After Testing

1. **Note any issues** - Keep a list of bugs/improvements
2. **Check performance** - Note FPS, audio latency
3. **Test monetization** - Ensure ads and IAP work
4. **Get feedback** - Share with friends/musicians
5. **Iterate** - Fix issues before store release

## Quick Commands Reference
```bash
# Most common commands you'll use:
flutter run                      # Run debug build
flutter run --release           # Run release build
flutter build apk               # Build APK
flutter logs                    # View device logs
flutter clean                   # Clean build files
adb install app.apk            # Install APK
adb uninstall com.domusgpt.sound_synthesizer  # Uninstall
```

## Ready to Test! 🎵
Your Synther app is ready for Android testing. The monetization system will show test ads and allow test purchases. Perfect for development!