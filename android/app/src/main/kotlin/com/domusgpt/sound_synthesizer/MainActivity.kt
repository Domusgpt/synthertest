package com.domusgpt.sound_synthesizer

import android.Manifest
import android.content.pm.PackageManager
import android.os.Bundle
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity: FlutterActivity() {
    
    companion object {
        private const val REQUEST_AUDIO_PERMISSION = 1001
    }
    
    private var audioChannelHandler: AudioChannelHandler? = null
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        // Initialize audio channel handler
        audioChannelHandler = AudioChannelHandler(this, flutterEngine)
        
        // Request audio permissions on startup
        requestAudioPermissions()
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Set the app to handle audio properly
        volumeControlStream = android.media.AudioManager.STREAM_MUSIC
    }
    
    override fun onDestroy() {
        super.onDestroy()
        audioChannelHandler?.cleanup()
    }
    
    private fun requestAudioPermissions() {
        val permissions = arrayOf(
            Manifest.permission.RECORD_AUDIO,
            Manifest.permission.MODIFY_AUDIO_SETTINGS
        )
        
        val missingPermissions = permissions.filter { permission ->
            ContextCompat.checkSelfPermission(this, permission) != PackageManager.PERMISSION_GRANTED
        }
        
        if (missingPermissions.isNotEmpty()) {
            ActivityCompat.requestPermissions(
                this,
                missingPermissions.toTypedArray(),
                REQUEST_AUDIO_PERMISSION
            )
        }
    }
    
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        
        when (requestCode) {
            REQUEST_AUDIO_PERMISSION -> {
                val allGranted = grantResults.all { it == PackageManager.PERMISSION_GRANTED }
                if (allGranted) {
                    // Permissions granted, audio functionality available
                    println("Audio permissions granted")
                } else {
                    // Some permissions denied, limited functionality
                    println("Audio permissions denied")
                }
            }
        }
    }
    
    override fun onResume() {
        super.onResume()
        // Resume audio if needed
    }
    
    override fun onPause() {
        super.onPause()
        // Pause audio to be respectful of other apps
    }
    
    // Native function declarations (called from C++ layer)
    external fun initializeAudio()
    external fun setAudioAttributes()
    
    companion object {
        // Load native library
        init {
            try {
                System.loadLibrary("synthengine")
                println("Native library loaded successfully")
            } catch (e: UnsatisfiedLinkError) {
                println("Failed to load native library: ${e.message}")
            }
        }
    }
}