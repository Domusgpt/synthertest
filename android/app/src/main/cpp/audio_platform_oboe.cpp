#include "audio_platform.h"
#include "synth_engine.h"
#include <oboe/Oboe.h>
#include <android/log.h>
#include <memory>
#include <atomic>

#define LOG_TAG "SynthEngineOboe"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

namespace synth {

class OboeAudioPlatform : public AudioPlatform, public oboe::AudioStreamCallback {
private:
    std::shared_ptr<oboe::AudioStream> stream_;
    SynthEngine* synth_engine_;
    std::atomic<bool> is_running_{false};
    
    // Audio configuration
    static constexpr int32_t SAMPLE_RATE = 48000;
    static constexpr int32_t FRAMES_PER_BUFFER = 192; // Low latency buffer
    static constexpr int32_t CHANNEL_COUNT = 2; // Stereo output
    
public:
    OboeAudioPlatform() : synth_engine_(nullptr) {
        LOGI("OboeAudioPlatform constructor");
    }
    
    ~OboeAudioPlatform() {
        stop();
        LOGI("OboeAudioPlatform destructor");
    }
    
    bool initialize(SynthEngine* engine) override {
        if (!engine) {
            LOGE("SynthEngine is null");
            return false;
        }
        
        synth_engine_ = engine;
        
        // Create audio stream
        oboe::AudioStreamBuilder builder;
        
        oboe::Result result = builder.setSharingMode(oboe::SharingMode::Exclusive)
            ->setPerformanceMode(oboe::PerformanceMode::LowLatency)
            ->setChannelCount(CHANNEL_COUNT)
            ->setSampleRate(SAMPLE_RATE)
            ->setFormat(oboe::AudioFormat::Float)
            ->setBufferCapacityInFrames(FRAMES_PER_BUFFER * 2)
            ->setFramesPerCallback(FRAMES_PER_BUFFER)
            ->setCallback(this)
            ->setDirection(oboe::Direction::Output)
            ->openStream(stream_);
        
        if (result != oboe::Result::OK) {
            LOGE("Failed to create audio stream: %s", oboe::convertToText(result));
            
            // Fallback to less aggressive settings
            result = builder.setSharingMode(oboe::SharingMode::Shared)
                ->setPerformanceMode(oboe::PerformanceMode::None)
                ->setFramesPerCallback(oboe::kUnspecified)
                ->openStream(stream_);
                
            if (result != oboe::Result::OK) {
                LOGE("Failed to create fallback audio stream: %s", oboe::convertToText(result));
                return false;
            }
        }
        
        // Log stream configuration
        LOGI("Audio stream created:");
        LOGI("  Sample rate: %d", stream_->getSampleRate());
        LOGI("  Channel count: %d", stream_->getChannelCount());
        LOGI("  Frames per buffer: %d", stream_->getFramesPerBurst());
        LOGI("  Performance mode: %s", 
             oboe::convertToText(stream_->getPerformanceMode()));
        LOGI("  Sharing mode: %s", 
             oboe::convertToText(stream_->getSharingMode()));
        
        // Initialize synth engine with audio parameters
        synth_engine_->setSampleRate(stream_->getSampleRate());
        
        return true;
    }
    
    bool start() override {
        if (!stream_) {
            LOGE("Audio stream not initialized");
            return false;
        }
        
        oboe::Result result = stream_->requestStart();
        if (result != oboe::Result::OK) {
            LOGE("Failed to start audio stream: %s", oboe::convertToText(result));
            return false;
        }
        
        is_running_ = true;
        LOGI("Audio stream started");
        return true;
    }
    
    bool stop() override {
        if (!stream_) {
            return true;
        }
        
        is_running_ = false;
        
        oboe::Result result = stream_->requestStop();
        if (result != oboe::Result::OK) {
            LOGE("Failed to stop audio stream: %s", oboe::convertToText(result));
            return false;
        }
        
        LOGI("Audio stream stopped");
        return true;
    }
    
    bool isRunning() const override {
        return is_running_.load();
    }
    
    double getSampleRate() const override {
        return stream_ ? stream_->getSampleRate() : SAMPLE_RATE;
    }
    
    int32_t getBufferSize() const override {
        return stream_ ? stream_->getBufferSizeInFrames() : FRAMES_PER_BUFFER;
    }
    
    // Oboe callback - called from audio thread
    oboe::DataCallbackResult onAudioReady(
        oboe::AudioStream* audioStream,
        void* audioData,
        int32_t numFrames) override {
        
        if (!synth_engine_ || !is_running_.load()) {
            // Output silence
            std::memset(audioData, 0, numFrames * CHANNEL_COUNT * sizeof(float));
            return oboe::DataCallbackResult::Continue;
        }
        
        // Generate audio samples
        float* output = static_cast<float*>(audioData);
        
        try {
            // Process audio in the synth engine
            synth_engine_->processAudio(output, numFrames, CHANNEL_COUNT);
        } catch (const std::exception& e) {
            LOGE("Exception in audio callback: %s", e.what());
            std::memset(audioData, 0, numFrames * CHANNEL_COUNT * sizeof(float));
        } catch (...) {
            LOGE("Unknown exception in audio callback");
            std::memset(audioData, 0, numFrames * CHANNEL_COUNT * sizeof(float));
        }
        
        return oboe::DataCallbackResult::Continue;
    }
    
    void onErrorBeforeClose(oboe::AudioStream* oboeStream, oboe::Result error) override {
        LOGE("Audio stream error before close: %s", oboe::convertToText(error));
    }
    
    void onErrorAfterClose(oboe::AudioStream* oboeStream, oboe::Result error) override {
        LOGE("Audio stream error after close: %s", oboe::convertToText(error));
        
        // Try to restart the stream
        if (is_running_.load()) {
            LOGI("Attempting to restart audio stream");
            
            // Reset the stream
            stream_.reset();
            
            // Try to recreate and restart
            if (initialize(synth_engine_)) {
                start();
            } else {
                LOGE("Failed to restart audio stream");
                is_running_ = false;
            }
        }
    }
};

// Platform-specific factory function
std::unique_ptr<AudioPlatform> AudioPlatform::create() {
    LOGI("Creating Oboe audio platform");
    return std::make_unique<OboeAudioPlatform>();
}

// Android-specific initialization
extern "C" {
    
// JNI function to be called from Java/Kotlin
JNIEXPORT void JNICALL
Java_com_domusgpt_sound_1synthesizer_MainActivity_initializeAudio(JNIEnv *env, jobject thiz) {
    LOGI("Initializing audio from JNI");
    
    // This could be used for additional Android-specific audio setup
    // such as requesting audio focus, setting audio attributes, etc.
}

JNIEXPORT void JNICALL
Java_com_domusgpt_sound_1synthesizer_MainActivity_setAudioAttributes(JNIEnv *env, jobject thiz) {
    LOGI("Setting audio attributes from JNI");
    
    // Configure Android audio attributes for low-latency performance
    // This would typically be done from the Java/Kotlin side using AudioManager
}

} // extern "C"

} // namespace synth