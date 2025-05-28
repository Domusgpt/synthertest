#!/bin/bash

echo "==================================="
echo "  SYNTHER ANDROID TEST BUILD"
echo "==================================="
echo ""

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo -e "${RED}ERROR: Flutter not found in PATH!${NC}"
    echo "Please install Flutter and add it to your PATH"
    echo "Visit: https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo -e "${GREEN}Flutter found. Running doctor...${NC}"
flutter doctor -v

echo ""
echo "==================================="
echo "  PREPARING BUILD"
echo "==================================="
echo ""

# Clean and get dependencies
echo "Cleaning previous builds..."
flutter clean

echo ""
echo "Getting dependencies..."
flutter pub get

echo ""
echo "==================================="
echo "  DEVICE CHECK"
echo "==================================="
echo ""
echo "Looking for connected devices..."
flutter devices

echo ""
echo "==================================="
echo "  BUILD OPTIONS"
echo "==================================="
echo ""
echo "1. Run on connected device (debug mode with hot reload)"
echo "2. Build APK only (for manual installation)"
echo "3. Build and install APK"
echo "4. Run on device with logs"
echo ""
read -p "Choose option (1-4): " choice

case $choice in
    1)
        echo ""
        echo -e "${BLUE}Running on device in debug mode...${NC}"
        flutter run
        ;;
    2)
        echo ""
        echo -e "${BLUE}Building release APK...${NC}"
        flutter build apk --release
        echo ""
        echo -e "${GREEN}APK built successfully!${NC}"
        echo "Location: build/app/outputs/flutter-apk/app-release.apk"
        echo ""
        echo "You can transfer this APK to your phone via:"
        echo "- USB cable"
        echo "- Google Drive"
        echo "- Email"
        echo ""
        ;;
    3)
        echo ""
        echo -e "${BLUE}Building and installing APK...${NC}"
        flutter build apk --release
        echo ""
        echo "Installing on device..."
        adb install build/app/outputs/flutter-apk/app-release.apk
        ;;
    4)
        echo ""
        echo -e "${BLUE}Running with logs...${NC}"
        flutter run --verbose
        ;;
    *)
        echo -e "${RED}Invalid choice!${NC}"
        ;;
esac

echo ""
echo "Done!"