cmake_minimum_required(VERSION 3.18)

# Set project name for iOS build
project(SynthEngineIOS LANGUAGES CXX OBJCXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# iOS-specific settings
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0")
set(CMAKE_XCODE_ATTRIBUTE_IPHONEOS_DEPLOYMENT_TARGET "12.0")

# Root path to native engine
set(NATIVE_ENGINE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../native")

# Define source files from the native engine
set(NATIVE_ENGINE_SOURCES
    ${NATIVE_ENGINE_ROOT}/src/ffi_bridge.cpp
    ${NATIVE_ENGINE_ROOT}/src/synth_engine.cpp
    ${NATIVE_ENGINE_ROOT}/src/audio_platform/audio_platform.cpp
    # Add iOS-specific audio platform implementation
    ${CMAKE_CURRENT_SOURCE_DIR}/audio_platform_coreaudio.mm
)

# Create the static library for iOS
add_library(synthengine STATIC ${NATIVE_ENGINE_SOURCES})

# Include directories
target_include_directories(synthengine PRIVATE
    ${NATIVE_ENGINE_ROOT}/src
    ${NATIVE_ENGINE_ROOT}/src/synthesis
    ${NATIVE_ENGINE_ROOT}/src/wavetable
    ${NATIVE_ENGINE_ROOT}/src/granular
    ${NATIVE_ENGINE_ROOT}/src/audio_platform
    ${NATIVE_ENGINE_ROOT}/include
    ${CMAKE_CURRENT_SOURCE_DIR}
)

# iOS-specific frameworks
find_library(CORE_AUDIO_FRAMEWORK CoreAudio)
find_library(AUDIO_UNIT_FRAMEWORK AudioUnit)
find_library(AUDIO_TOOLBOX_FRAMEWORK AudioToolbox)
find_library(AVFOUNDATION_FRAMEWORK AVFoundation)
find_library(FOUNDATION_FRAMEWORK Foundation)

# Link with iOS frameworks
target_link_libraries(synthengine
    ${CORE_AUDIO_FRAMEWORK}
    ${AUDIO_UNIT_FRAMEWORK}
    ${AUDIO_TOOLBOX_FRAMEWORK}
    ${AVFOUNDATION_FRAMEWORK}
    ${FOUNDATION_FRAMEWORK}
)

# Compiler flags for iOS
target_compile_options(synthengine PRIVATE
    -Wall
    -Wextra
    -Wno-unused-parameter
    -O3
    -ffast-math
    -funroll-loops
    $<$<COMPILE_LANGUAGE:OBJCXX>:-fobjc-arc>
)

# Compile definitions
target_compile_definitions(synthengine PRIVATE
    IOS_PLATFORM
    USE_CORE_AUDIO
    $<$<CONFIG:Debug>:DEBUG>
    $<$<CONFIG:Release>:NDEBUG>
)

# Set library properties
set_target_properties(synthengine PROPERTIES
    FRAMEWORK TRUE
    FRAMEWORK_VERSION A
    MACOSX_FRAMEWORK_IDENTIFIER com.domusgpt.synthengine
    MACOSX_FRAMEWORK_BUNDLE_VERSION 1.0.0
    MACOSX_FRAMEWORK_SHORT_VERSION_STRING 1.0
    XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY "iPhone Developer"
    XCODE_ATTRIBUTE_DEVELOPMENT_TEAM ""
    PUBLIC_HEADER "${NATIVE_ENGINE_ROOT}/include/synth_engine_api.h"
)

# Enable link-time optimization for release builds
if(CMAKE_BUILD_TYPE STREQUAL Release)
    set_property(TARGET synthengine PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()