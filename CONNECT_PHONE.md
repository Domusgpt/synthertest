# How to Connect Your Android Phone

## 1. Enable Developer Mode on Phone
- Settings → About Phone
- Tap "Build Number" 7 times
- You'll see "You are now a developer!"

## 2. Enable USB Debugging
- Settings → System → Developer Options
- Turn ON "Developer options" toggle
- Turn ON "USB debugging"
- Turn ON "Install via USB" (if available)

## 3. Connect Phone to Computer
- Use a USB cable (data cable, not charging-only)
- When prompted on phone: "Allow USB debugging?"
- Check "Always allow from this computer"
- Tap "OK"

## 4. Verify Connection
```bash
# Check if phone is detected
adb devices

# Should show something like:
# List of devices attached
# ABC123DEF456    device
```

## 5. Run Flutter Again
```bash
cd /mnt/c/Users/millz/Desktop/Synther
flutter run
```

## Troubleshooting

### Phone not showing up?

1. **Try different USB cable** - Some cables are charge-only
2. **Try different USB port** - Use USB 2.0 if available
3. **Check notification panel** - Select "File Transfer" or "MTP"
4. **Restart ADB**:
   ```bash
   adb kill-server
   adb start-server
   adb devices
   ```

### Still not working?

5. **Install Google USB Driver** (Windows):
   - Android Studio → SDK Manager → SDK Tools
   - Check "Google USB Driver"
   - Apply

6. **Check Device Manager** (Windows):
   - Should see your phone under "Portable Devices"
   - Or under "Android Device"

## Alternative: Build APK and Transfer

If USB connection is problematic:

```bash
# Build APK
flutter build apk --release

# Find APK at:
# build/app/outputs/flutter-apk/app-release.apk

# Transfer via:
# - Google Drive
# - Email
# - WhatsApp
# - USB file transfer
```

## Quick Test Without Phone

Want to test in Chrome browser instead?
```bash
flutter run -d chrome
```

This will run the web version with:
- Web Audio API synthesis
- Test ads (won't show in web)
- All UI features
- Limited audio performance