cmake_minimum_required(VERSION 3.18.1)

# Set project name for Android build
project(SynthEngineAndroid LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Android-specific flags
set(CMAKE_ANDROID_STL_TYPE c++_shared)

# Root path to native engine
set(NATIVE_ENGINE_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/../../../../../native")

# Include FetchContent for Oboe
include(FetchContent)

# Fetch Oboe for low-latency audio on Android
FetchContent_Declare(
    oboe
    GIT_REPOSITORY https://github.com/google/oboe.git
    GIT_TAG main
)
FetchContent_MakeAvailable(oboe)

# Define source files from the native engine
set(NATIVE_ENGINE_SOURCES
    ${NATIVE_ENGINE_ROOT}/src/ffi_bridge.cpp
    ${NATIVE_ENGINE_ROOT}/src/synth_engine.cpp
    ${NATIVE_ENGINE_ROOT}/src/audio_platform/audio_platform.cpp
    # Add Android-specific audio platform implementation
    ${CMAKE_CURRENT_SOURCE_DIR}/audio_platform_oboe.cpp
)

# Create the shared library for Android
add_library(synthengine SHARED ${NATIVE_ENGINE_SOURCES})

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

# Link with Oboe
target_link_libraries(synthengine
    oboe::oboe
    android
    log
)

# Compiler flags for Android
target_compile_options(synthengine PRIVATE
    -Wall
    -Wextra
    -Wno-unused-parameter
    -O3
    -ffast-math
    -funroll-loops
)

# Compile definitions
target_compile_definitions(synthengine PRIVATE
    ANDROID_PLATFORM
    USE_OBOE_AUDIO
    $<$<CONFIG:Debug>:DEBUG>
    $<$<CONFIG:Release>:NDEBUG>
)

# Set library properties
set_target_properties(synthengine PROPERTIES
    ANDROID_ARM_MODE arm
)

# Enable link-time optimization for release builds
if(CMAKE_BUILD_TYPE STREQUAL Release)
    set_property(TARGET synthengine PROPERTY INTERPROCEDURAL_OPTIMIZATION TRUE)
endif()