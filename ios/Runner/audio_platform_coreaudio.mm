#include "audio_platform.h"
#include "synth_engine.h"
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#include <memory>
#include <atomic>

namespace synth {

class CoreAudioPlatform : public AudioPlatform {
private:
    AudioUnit audioUnit_;
    SynthEngine* synth_engine_;
    std::atomic<bool> is_running_{false};
    
    // Audio configuration
    static constexpr Float64 SAMPLE_RATE = 48000.0;
    static constexpr UInt32 FRAMES_PER_BUFFER = 512; // Balanced latency/performance
    static constexpr UInt32 CHANNEL_COUNT = 2; // Stereo output
    
    // Audio session management
    AVAudioSession* audioSession_;
    
public:
    CoreAudioPlatform() : audioUnit_(nullptr), synth_engine_(nullptr), audioSession_(nullptr) {
        NSLog(@"CoreAudioPlatform constructor");
    }
    
    ~CoreAudioPlatform() {
        stop();
        cleanup();
        NSLog(@"CoreAudioPlatform destructor");
    }
    
    bool initialize(SynthEngine* engine) override {
        if (!engine) {
            NSLog(@"SynthEngine is null");
            return false;
        }
        
        synth_engine_ = engine;
        
        // Configure audio session
        if (!setupAudioSession()) {
            NSLog(@"Failed to setup audio session");
            return false;
        }
        
        // Create audio unit
        if (!createAudioUnit()) {
            NSLog(@"Failed to create audio unit");
            return false;
        }
        
        // Initialize synth engine with audio parameters
        synth_engine_->setSampleRate(SAMPLE_RATE);
        
        NSLog(@"Core Audio platform initialized successfully");
        NSLog(@"Sample rate: %f", SAMPLE_RATE);
        NSLog(@"Frames per buffer: %d", FRAMES_PER_BUFFER);
        NSLog(@"Channel count: %d", CHANNEL_COUNT);
        
        return true;
    }
    
    bool start() override {
        if (!audioUnit_) {
            NSLog(@"Audio unit not initialized");
            return false;
        }
        
        // Activate audio session
        NSError* error = nil;
        if (![[AVAudioSession sharedInstance] setActive:YES error:&error]) {
            NSLog(@"Failed to activate audio session: %@", error.localizedDescription);
            return false;
        }
        
        // Start audio unit
        OSStatus status = AudioUnitInitialize(audioUnit_);
        if (status != noErr) {
            NSLog(@"Failed to initialize audio unit: %d", (int)status);
            return false;
        }
        
        status = AudioOutputUnitStart(audioUnit_);
        if (status != noErr) {
            NSLog(@"Failed to start audio unit: %d", (int)status);
            return false;
        }
        
        is_running_ = true;
        NSLog(@"Audio unit started");
        return true;
    }
    
    bool stop() override {
        if (!audioUnit_) {
            return true;
        }
        
        is_running_ = false;
        
        // Stop audio unit
        OSStatus status = AudioOutputUnitStop(audioUnit_);
        if (status != noErr) {
            NSLog(@"Failed to stop audio unit: %d", (int)status);
        }
        
        // Uninitialize audio unit
        AudioUnitUninitialize(audioUnit_);
        
        // Deactivate audio session
        NSError* error = nil;
        [[AVAudioSession sharedInstance] setActive:NO error:&error];
        
        NSLog(@"Audio unit stopped");
        return status == noErr;
    }
    
    bool isRunning() const override {
        return is_running_.load();
    }
    
    double getSampleRate() const override {
        return SAMPLE_RATE;
    }
    
    int32_t getBufferSize() const override {
        return FRAMES_PER_BUFFER;
    }
    
private:
    bool setupAudioSession() {
        audioSession_ = [AVAudioSession sharedInstance];
        NSError* error = nil;
        
        // Set audio session category for playback with low latency
        if (![audioSession_ setCategory:AVAudioSessionCategoryPlayback 
                                   mode:AVAudioSessionModeDefault 
                                options:AVAudioSessionCategoryOptionLowLatency 
                                  error:&error]) {
            NSLog(@"Failed to set audio session category: %@", error.localizedDescription);
            return false;
        }
        
        // Set preferred buffer duration for low latency
        NSTimeInterval preferredIOBufferDuration = (double)FRAMES_PER_BUFFER / SAMPLE_RATE;
        if (![audioSession_ setPreferredIOBufferDuration:preferredIOBufferDuration error:&error]) {
            NSLog(@"Failed to set preferred buffer duration: %@", error.localizedDescription);
            // Non-critical, continue anyway
        }
        
        // Set preferred sample rate
        if (![audioSession_ setPreferredSampleRate:SAMPLE_RATE error:&error]) {
            NSLog(@"Failed to set preferred sample rate: %@", error.localizedDescription);
            // Non-critical, continue anyway
        }
        
        // Set up interruption handling
        [[NSNotificationCenter defaultCenter] 
            addObserver:[[InterruptionHandler alloc] initWithPlatform:this]
               selector:@selector(handleInterruption:)
                   name:AVAudioSessionInterruptionNotification
                 object:audioSession_];
        
        return true;
    }
    
    bool createAudioUnit() {
        OSStatus status;
        
        // Describe the audio unit
        AudioComponentDescription desc;
        desc.componentType = kAudioUnitType_Output;
        desc.componentSubType = kAudioUnitSubType_RemoteIO;
        desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        desc.componentFlags = 0;
        desc.componentFlagsMask = 0;
        
        // Find the audio unit
        AudioComponent component = AudioComponentFindNext(NULL, &desc);
        if (!component) {
            NSLog(@"Failed to find audio component");
            return false;
        }
        
        // Create audio unit instance
        status = AudioComponentInstanceNew(component, &audioUnit_);
        if (status != noErr) {
            NSLog(@"Failed to create audio unit instance: %d", (int)status);
            return false;
        }
        
        // Set up audio format
        AudioStreamBasicDescription format;
        format.mSampleRate = SAMPLE_RATE;
        format.mFormatID = kAudioFormatLinearPCM;
        format.mFormatFlags = kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked;
        format.mChannelsPerFrame = CHANNEL_COUNT;
        format.mBitsPerChannel = 32;
        format.mBytesPerFrame = sizeof(Float32) * CHANNEL_COUNT;
        format.mFramesPerPacket = 1;
        format.mBytesPerPacket = format.mBytesPerFrame;
        
        // Set the format on the audio unit
        status = AudioUnitSetProperty(audioUnit_,
                                     kAudioUnitProperty_StreamFormat,
                                     kAudioUnitScope_Input,
                                     0,
                                     &format,
                                     sizeof(format));
        if (status != noErr) {
            NSLog(@"Failed to set audio unit format: %d", (int)status);
            return false;
        }
        
        // Set up render callback
        AURenderCallbackStruct renderCallback;
        renderCallback.inputProc = audioRenderCallback;
        renderCallback.inputProcRefCon = this;
        
        status = AudioUnitSetProperty(audioUnit_,
                                     kAudioUnitProperty_SetRenderCallback,
                                     kAudioUnitScope_Input,
                                     0,
                                     &renderCallback,
                                     sizeof(renderCallback));
        if (status != noErr) {
            NSLog(@"Failed to set render callback: %d", (int)status);
            return false;
        }
        
        return true;
    }
    
    void cleanup() {
        // Remove notification observer
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        
        // Dispose of audio unit
        if (audioUnit_) {
            AudioComponentInstanceDispose(audioUnit_);
            audioUnit_ = nullptr;
        }
    }
    
    // Static render callback function
    static OSStatus audioRenderCallback(void* inRefCon,
                                       AudioUnitRenderActionFlags* ioActionFlags,
                                       const AudioTimeStamp* inTimeStamp,
                                       UInt32 inBusNumber,
                                       UInt32 inNumberFrames,
                                       AudioBufferList* ioData) {
        
        CoreAudioPlatform* platform = static_cast<CoreAudioPlatform*>(inRefCon);
        return platform->renderAudio(ioActionFlags, inTimeStamp, inBusNumber, inNumberFrames, ioData);
    }
    
    OSStatus renderAudio(AudioUnitRenderActionFlags* ioActionFlags,
                        const AudioTimeStamp* inTimeStamp,
                        UInt32 inBusNumber,
                        UInt32 inNumberFrames,
                        AudioBufferList* ioData) {
        
        if (!synth_engine_ || !is_running_.load()) {
            // Output silence
            for (UInt32 i = 0; i < ioData->mNumberBuffers; i++) {
                memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
            }
            return noErr;
        }
        
        try {
            // Generate audio samples
            Float32* output = static_cast<Float32*>(ioData->mBuffers[0].mData);
            
            // Process audio in the synth engine
            synth_engine_->processAudio(output, inNumberFrames, CHANNEL_COUNT);
            
        } catch (const std::exception& e) {
            NSLog(@"Exception in audio callback: %s", e.what());
            // Output silence on error
            for (UInt32 i = 0; i < ioData->mNumberBuffers; i++) {
                memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
            }
        } catch (...) {
            NSLog(@"Unknown exception in audio callback");
            // Output silence on error
            for (UInt32 i = 0; i < ioData->mNumberBuffers; i++) {
                memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
            }
        }
        
        return noErr;
    }
    
    void handleAudioInterruption(NSNotification* notification) {
        NSNumber* typeNumber = notification.userInfo[AVAudioSessionInterruptionTypeKey];
        AVAudioSessionInterruptionType type = (AVAudioSessionInterruptionType)typeNumber.unsignedIntegerValue;
        
        if (type == AVAudioSessionInterruptionTypeBegan) {
            NSLog(@"Audio interruption began");
            // Audio session was interrupted
            if (is_running_.load()) {
                stop();
            }
        } else if (type == AVAudioSessionInterruptionTypeEnded) {
            NSLog(@"Audio interruption ended");
            NSNumber* optionsNumber = notification.userInfo[AVAudioSessionInterruptionOptionKey];
            AVAudioSessionInterruptionOptions options = (AVAudioSessionInterruptionOptions)optionsNumber.unsignedIntegerValue;
            
            if (options & AVAudioSessionInterruptionOptionShouldResume) {
                // Resume audio if it was playing before interruption
                start();
            }
        }
    }
};

// Objective-C class for handling interruptions
@interface InterruptionHandler : NSObject
@property (nonatomic, assign) CoreAudioPlatform* platform;
@end

@implementation InterruptionHandler

- (instancetype)initWithPlatform:(CoreAudioPlatform*)platform {
    self = [super init];
    if (self) {
        _platform = platform;
    }
    return self;
}

- (void)handleInterruption:(NSNotification*)notification {
    if (_platform) {
        _platform->handleAudioInterruption(notification);
    }
}

@end

// Platform-specific factory function
std::unique_ptr<AudioPlatform> AudioPlatform::create() {
    NSLog(@"Creating Core Audio platform");
    return std::make_unique<CoreAudioPlatform>();
}

} // namespace synth