#!/bin/bash
# build_native.sh - Cross-platform native engine build script

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
NATIVE_DIR="$PROJECT_ROOT/native"

echo "🏗️ SYNTHER NATIVE ENGINE BUILD SCRIPT"
echo "Project root: $PROJECT_ROOT"
echo "Native directory: $NATIVE_DIR"

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

# Check if native directory exists
if [ ! -d "$NATIVE_DIR" ]; then
    print_error "Native directory not found: $NATIVE_DIR"
    exit 1
fi

build_android() {
    print_status "Building native engine for Android..."
    
    # Check for Android NDK
    if [ -z "$ANDROID_NDK" ]; then
        print_error "ANDROID_NDK environment variable not set"
        print_warning "Please set ANDROID_NDK to your Android NDK installation path"
        return 1
    fi
    
    print_status "Using Android NDK: $ANDROID_NDK"
    
    cd "$NATIVE_DIR"
    mkdir -p build-android
    cd build-android
    
    # Build for ARM64 (primary architecture)
    print_status "Building for ARM64-v8a..."
    cmake .. \
        -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK/build/cmake/android.toolchain.cmake" \
        -DANDROID_ABI=arm64-v8a \
        -DANDROID_PLATFORM=android-21 \
        -DCMAKE_BUILD_TYPE=Release \
        -DFLUTTER_BUILD=ON
    
    make -j$(nproc)
    
    # Copy to Flutter Android directory
    FLUTTER_ANDROID_JNI="$PROJECT_ROOT/android/app/src/main/jniLibs/arm64-v8a"
    mkdir -p "$FLUTTER_ANDROID_JNI"
    cp libsynthengine.so "$FLUTTER_ANDROID_JNI/"
    
    print_success "Android native engine built successfully"
    print_status "Library copied to: $FLUTTER_ANDROID_JNI/libsynthengine.so"
}

build_ios() {
    print_status "Building native engine for iOS..."
    
    # Check for Xcode
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode not found. Please install Xcode and command line tools."
        return 1
    fi
    
    cd "$NATIVE_DIR"
    mkdir -p build-ios
    cd build-ios
    
    # Build iOS framework
    print_status "Configuring iOS build with CMake..."
    cmake .. \
        -G Xcode \
        -DCMAKE_SYSTEM_NAME=iOS \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=12.0 \
        -DCMAKE_BUILD_TYPE=Release \
        -DFLUTTER_BUILD=ON
    
    print_status "Building with Xcode..."
    xcodebuild -configuration Release -target synthengine
    
    # Copy framework to Flutter iOS directory
    FLUTTER_IOS_DIR="$PROJECT_ROOT/ios"
    if [ -d "Release-iphoneos/synthengine.framework" ]; then
        cp -R "Release-iphoneos/synthengine.framework" "$FLUTTER_IOS_DIR/"
        print_success "iOS framework built and copied successfully"
    else
        print_warning "iOS framework not found at expected location"
    fi
}

build_desktop() {
    print_status "Building native engine for desktop..."
    
    cd "$NATIVE_DIR"
    
    # Determine platform
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        PLATFORM="linux"
        BUILD_DIR="build-linux"
        LIBRARY_EXT="so"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        PLATFORM="macos"
        BUILD_DIR="build-macos"
        LIBRARY_EXT="dylib"
    elif [[ "$OSTYPE" == "msys" ]] || [[ "$OSTYPE" == "cygwin" ]]; then
        PLATFORM="windows"
        BUILD_DIR="build-windows"
        LIBRARY_EXT="dll"
    else
        print_error "Unsupported platform: $OSTYPE"
        return 1
    fi
    
    print_status "Building for platform: $PLATFORM"
    
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    cmake .. \
        -DCMAKE_BUILD_TYPE=Release \
        -DFLUTTER_BUILD=ON
    
    make -j$(nproc) 2>/dev/null || make -j4 2>/dev/null || make
    
    # Copy to Flutter desktop directory
    if [ -f "libsynthengine.$LIBRARY_EXT" ]; then
        FLUTTER_DESKTOP_DIR="$PROJECT_ROOT/$PLATFORM"
        if [ -d "$FLUTTER_DESKTOP_DIR" ]; then
            cp "libsynthengine.$LIBRARY_EXT" "$FLUTTER_DESKTOP_DIR/"
            print_success "Desktop library built and copied successfully"
        else
            print_warning "Flutter desktop directory not found: $FLUTTER_DESKTOP_DIR"
        fi
    else
        print_error "Library not found: libsynthengine.$LIBRARY_EXT"
        return 1
    fi
}

build_all() {
    print_status "Building native engine for all platforms..."
    
    # Try to build for all platforms
    build_desktop
    
    # Android (only if NDK is available)
    if [ -n "$ANDROID_NDK" ]; then
        build_android
    else
        print_warning "Skipping Android build (ANDROID_NDK not set)"
    fi
    
    # iOS (only on macOS with Xcode)
    if [[ "$OSTYPE" == "darwin"* ]] && command -v xcodebuild &> /dev/null; then
        build_ios
    else
        print_warning "Skipping iOS build (not on macOS or Xcode not found)"
    fi
    
    print_success "All available platform builds completed!"
}

# Main execution
case "$1" in
    android)
        build_android
        ;;
    ios)
        build_ios
        ;;
    desktop)
        build_desktop
        ;;
    linux)
        build_desktop
        ;;
    macos)
        build_desktop
        ;;
    windows)
        build_desktop
        ;;
    all)
        build_all
        ;;
    "")
        print_status "No platform specified, building for current desktop platform..."
        build_desktop
        ;;
    *)
        print_error "Unknown platform: $1"
        echo "Usage: $0 {android|ios|desktop|linux|macos|windows|all}"
        echo ""
        echo "Platforms:"
        echo "  android  - Build for Android (requires ANDROID_NDK)"
        echo "  ios      - Build for iOS (requires macOS and Xcode)"
        echo "  desktop  - Build for current desktop platform"
        echo "  linux    - Build for Linux"
        echo "  macos    - Build for macOS"
        echo "  windows  - Build for Windows"
        echo "  all      - Build for all available platforms"
        exit 1
        ;;
esac

print_success "Build script completed!"