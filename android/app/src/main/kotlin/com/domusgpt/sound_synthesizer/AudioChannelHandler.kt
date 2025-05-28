package com.domusgpt.sound_synthesizer

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.media.AudioManager
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class AudioChannelHandler(private val context: Context, private val flutterEngine: FlutterEngine) {
    
    companion object {
        private const val CHANNEL = "synther/audio"
        private const val REQUEST_AUDIO_PERMISSION = 1001
    }
    
    private var methodChannel: MethodChannel? = null
    private var audioManager: AudioManager? = null
    private var audioFocusRequest: AudioFocusRequest? = null
    
    init {
        audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
        setupMethodChannel()
    }
    
    private fun setupMethodChannel() {
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        methodChannel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "requestAudioPermissions" -> requestAudioPermissions(result)
                "initializeAudio" -> initializeAudio(result)
                "getAudioLatency" -> getAudioLatency(result)
                "getBufferUnderrunCount" -> getBufferUnderrunCount(result)
                "requestLowLatencyMode" -> requestLowLatencyMode(result)
                "setAudioAttributes" -> setAudioAttributes(result)
                else -> result.notImplemented()
            }
        }
    }
    
    private fun requestAudioPermissions(result: Result) {
        val permissions = arrayOf(
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.MODIFY_AUDIO_SETTINGS
        )
        
        val missingPermissions = permissions.filter { permission ->
            ContextCompat.checkSelfPermission(context, permission) != PackageManager.PERMISSION_GRANTED
        }
        
        if (missingPermissions.isEmpty()) {
            result.success(true)
        } else {
            // Note: This would typically require activity context for requesting permissions
            // In a real implementation, you'd need to handle this through the main activity
            result.success(false)
        }
    }
    
    private fun initializeAudio(result: Result) {
        try {
            // Request audio focus
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                val audioAttributes = AudioAttributes.Builder()
                    .setUsage(AudioAttributes.USAGE_MEDIA)
                    .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                    .build()
                
                audioFocusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN)
                    .setAudioAttributes(audioAttributes)
                    .setAcceptsDelayedFocusGain(true)
                    .setOnAudioFocusChangeListener { focusChange ->
                        handleAudioFocusChange(focusChange)
                    }
                    .build()
                
                val focusResult = audioManager?.requestAudioFocus(audioFocusRequest!!)
                if (focusResult == AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                    result.success(true)
                } else {
                    result.success(false)
                }
            } else {
                @Suppress("DEPRECATION")
                val focusResult = audioManager?.requestAudioFocus(
                    { focusChange -> handleAudioFocusChange(focusChange) },
                    AudioManager.STREAM_MUSIC,
                    AudioManager.AUDIOFOCUS_GAIN
                )
                result.success(focusResult == AudioManager.AUDIOFOCUS_REQUEST_GRANTED)
            }
            
            // Set additional audio manager properties
            audioManager?.mode = AudioManager.MODE_NORMAL
            
        } catch (e: Exception) {
            result.error("AUDIO_INIT_ERROR", "Failed to initialize audio: ${e.message}", null)
        }
    }
    
    private fun getAudioLatency(result: Result) {
        try {
            // Get output latency if available (API 29+)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                val latency = audioManager?.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER)?.toDoubleOrNull() ?: 0.0
                val sampleRate = audioManager?.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE)?.toDoubleOrNull() ?: 48000.0
                val latencyMs = if (sampleRate > 0) (latency / sampleRate) * 1000.0 else 0.0
                result.success(latencyMs)
            } else {
                // Estimate latency for older devices
                result.success(20.0) // Conservative estimate
            }
        } catch (e: Exception) {
            result.error("LATENCY_ERROR", "Failed to get audio latency: ${e.message}", null)
        }
    }
    
    private fun getBufferUnderrunCount(result: Result) {
        try {
            // This would typically be implemented in the native audio layer
            // For now, return 0 as a placeholder
            result.success(0)
        } catch (e: Exception) {
            result.error("UNDERRUN_ERROR", "Failed to get buffer underrun count: ${e.message}", null)
        }
    }
    
    private fun requestLowLatencyMode(result: Result) {
        try {
            // Check if device supports low-latency audio
            val hasLowLatencyFeature = context.packageManager.hasSystemFeature(
                PackageManager.FEATURE_AUDIO_LOW_LATENCY
            )
            
            val hasProAudioFeature = context.packageManager.hasSystemFeature(
                PackageManager.FEATURE_AUDIO_PRO
            )
            
            if (hasLowLatencyFeature || hasProAudioFeature) {
                // Set audio manager to performance mode
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    try {
                        // This is typically done in the native layer with Oboe
                        result.success(true)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                } else {
                    result.success(false)
                }
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("LOW_LATENCY_ERROR", "Failed to request low latency mode: ${e.message}", null)
        }
    }
    
    private fun setAudioAttributes(result: Result) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                // This is typically handled during stream creation in Oboe
                // Call native function to set audio attributes
                initializeAudio()
                result.success(true)
            } else {
                result.success(false)
            }
        } catch (e: Exception) {
            result.error("AUDIO_ATTRIBUTES_ERROR", "Failed to set audio attributes: ${e.message}", null)
        }
    }
    
    private fun handleAudioFocusChange(focusChange: Int) {
        when (focusChange) {
            AudioManager.AUDIOFOCUS_GAIN -> {
                // Resume playback
                methodChannel?.invokeMethod("onAudioFocusGained", null)
            }
            AudioManager.AUDIOFOCUS_LOSS -> {
                // Stop playback
                methodChannel?.invokeMethod("onAudioFocusLost", null)
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT -> {
                // Pause playback
                methodChannel?.invokeMethod("onAudioFocusLostTransient", null)
            }
            AudioManager.AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK -> {
                // Lower volume
                methodChannel?.invokeMethod("onAudioFocusLostTransientCanDuck", null)
            }
        }
    }
    
    // Native function declarations
    private external fun initializeAudio()
    private external fun setAudioAttributes()
    
    fun cleanup() {
        // Release audio focus
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            audioFocusRequest?.let { request ->
                audioManager?.abandonAudioFocusRequest(request)
            }
        } else {
            @Suppress("DEPRECATION")
            audioManager?.abandonAudioFocus { }
        }
        
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
    }
    
    companion object {
        // Load native library
        init {
            System.loadLibrary("synthengine")
        }
    }
}