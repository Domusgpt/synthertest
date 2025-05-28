#!/bin/bash
# build_flutter.sh - Cross-platform Flutter build script

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "🚀 SYNTHER FLUTTER BUILD SCRIPT"
echo "Project root: $PROJECT_ROOT"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}📋 $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Change to project directory
cd "$PROJECT_ROOT"

# Check if Flutter is available
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter not found in PATH"
        print_warning "Please install Flutter SDK and add it to your PATH"
        print_warning "Visit: https://docs.flutter.dev/get-started/install"
        exit 1
    fi
    
    print_status "Flutter version:"
    flutter --version
}

# Clean previous builds
clean_builds() {
    print_status "Cleaning previous builds..."
    flutter clean
    flutter pub get
    print_success "Project cleaned and dependencies updated"
}

# Build for Android
build_android() {
    print_status "Building for Android..."
    
    # Check for Android SDK
    if [ -z "$ANDROID_HOME" ] && [ -z "$ANDROID_SDK_ROOT" ]; then
        print_warning "ANDROID_HOME or ANDROID_SDK_ROOT not set"
        print_warning "Attempting to build anyway..."
    fi
    
    # Build native engine first
    print_status "Building native engine for Android..."
    "$SCRIPT_DIR/build_native.sh" android
    
    # Build APK
    print_status "Building Android APK..."
    flutter build apk --release --target-platform android-arm64
    
    # Build App Bundle (for Play Store)
    print_status "Building Android App Bundle..."
    flutter build appbundle --release --target-platform android-arm64
    
    print_success "Android builds completed!"
    print_status "APK location: build/app/outputs/flutter-apk/app-release.apk"
    print_status "AAB location: build/app/outputs/bundle/release/app-release.aab"
}

# Build for iOS
build_ios() {
    print_status "Building for iOS..."
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "iOS builds require macOS"
        return 1
    fi
    
    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode not found. Please install Xcode."
        return 1
    fi
    
    # Build native engine first
    print_status "Building native engine for iOS..."
    "$SCRIPT_DIR/build_native.sh" ios
    
    # Build iOS app
    print_status "Building iOS app..."
    flutter build ios --release --no-codesign
    
    print_success "iOS build completed!"
    print_status "iOS app location: build/ios/iphoneos/Runner.app"
    print_warning "Note: Code signing required for device deployment"
}

# Build for Web
build_web() {
    print_status "Building for Web..."
    
    # Build web app
    print_status "Building web application..."
    flutter build web --release --web-renderer html
    
    print_success "Web build completed!"
    print_status "Web app location: build/web/"
    print_status "Serve with: python -m http.server 8000 (from build/web directory)"
}

# Build for Linux
build_linux() {
    print_status "Building for Linux..."
    
    # Check if Linux desktop is enabled
    if ! flutter config | grep -q "linux.*true"; then
        print_status "Enabling Linux desktop support..."
        flutter config --enable-linux-desktop
    fi
    
    # Build native engine first
    print_status "Building native engine for Linux..."
    "$SCRIPT_DIR/build_native.sh" linux
    
    # Build Linux app
    print_status "Building Linux application..."
    flutter build linux --release
    
    print_success "Linux build completed!"
    print_status "Linux app location: build/linux/x64/release/bundle/"
}

# Build for macOS
build_macos() {
    print_status "Building for macOS..."
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "macOS builds require macOS"
        return 1
    fi
    
    # Check if macOS desktop is enabled
    if ! flutter config | grep -q "macos.*true"; then
        print_status "Enabling macOS desktop support..."
        flutter config --enable-macos-desktop
    fi
    
    # Build native engine first
    print_status "Building native engine for macOS..."
    "$SCRIPT_DIR/build_native.sh" macos
    
    # Build macOS app
    print_status "Building macOS application..."
    flutter build macos --release
    
    print_success "macOS build completed!"
    print_status "macOS app location: build/macos/Build/Products/Release/synther.app"
}

# Build for Windows
build_windows() {
    print_status "Building for Windows..."
    
    # Check if Windows desktop is enabled
    if ! flutter config | grep -q "windows.*true"; then
        print_status "Enabling Windows desktop support..."
        flutter config --enable-windows-desktop
    fi
    
    # Build native engine first
    print_status "Building native engine for Windows..."
    "$SCRIPT_DIR/build_native.sh" windows
    
    # Build Windows app
    print_status "Building Windows application..."
    flutter build windows --release
    
    print_success "Windows build completed!"
    print_status "Windows app location: build/windows/runner/Release/"
}

# Build all platforms
build_all() {
    print_status "Building for all available platforms..."
    
    # Always available
    build_web
    
    # Platform-specific builds
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        build_linux
        # Try Android if SDK available
        if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
            build_android
        else
            print_warning "Skipping Android build (Android SDK not found)"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        build_macos
        build_ios
        # Try Android if SDK available
        if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
            build_android
        else
            print_warning "Skipping Android build (Android SDK not found)"
        fi
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        build_windows
        # Try Android if SDK available
        if [ -n "$ANDROID_HOME" ] || [ -n "$ANDROID_SDK_ROOT" ]; then
            build_android
        else
            print_warning "Skipping Android build (Android SDK not found)"
        fi
    fi
    
    print_success "All available platform builds completed!"
}

# Development build (debug)
build_debug() {
    print_status "Building debug version for testing..."
    
    # Build native engine in debug mode
    print_status "Building native engine in debug mode..."
    "$SCRIPT_DIR/build_native.sh" desktop
    
    # Run Flutter in debug mode
    print_status "Starting Flutter in debug mode..."
    flutter run --debug
}

# Main execution
check_flutter

case "$1" in
    clean)
        clean_builds
        ;;
    android)
        clean_builds
        build_android
        ;;
    ios)
        clean_builds
        build_ios
        ;;
    web)
        clean_builds
        build_web
        ;;
    linux)
        clean_builds
        build_linux
        ;;
    macos)
        clean_builds
        build_macos
        ;;
    windows)
        clean_builds
        build_windows
        ;;
    all)
        clean_builds
        build_all
        ;;
    debug)
        build_debug
        ;;
    "")
        print_error "No platform specified"
        echo "Usage: $0 {android|ios|web|linux|macos|windows|all|debug|clean}"
        echo ""
        echo "Platforms:"
        echo "  android  - Build for Android (requires Android SDK)"
        echo "  ios      - Build for iOS (requires macOS and Xcode)"
        echo "  web      - Build for Web browsers"
        echo "  linux    - Build for Linux desktop"
        echo "  macos    - Build for macOS desktop (requires macOS)"
        echo "  windows  - Build for Windows desktop"
        echo "  all      - Build for all available platforms"
        echo "  debug    - Build and run in debug mode"
        echo "  clean    - Clean previous builds and update dependencies"
        exit 1
        ;;
    *)
        print_error "Unknown platform: $1"
        echo "Usage: $0 {android|ios|web|linux|macos|windows|all|debug|clean}"
        exit 1
        ;;
esac

print_success "Flutter build script completed!"