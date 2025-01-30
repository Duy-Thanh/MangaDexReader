package com.nekkochan.mangareader

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle
import android.os.Build
import android.view.View
import android.view.WindowManager
import android.graphics.PixelFormat
import android.view.WindowInsetsController

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Remove the Flutter splash screen
        intent.putExtra("background_mode", "transparent")
        intent.putExtra("enable_state_restoration", false)
        
        super.onCreate(savedInstanceState)

        // Enable hardware acceleration
        window.setFlags(
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED,
            WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
        )

        // Optimize window for performance
        window.apply {
            // Better color format for performance
            setFormat(PixelFormat.RGBA_8888)
            
            // Keep screen on while app is active
            addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
            
            // Enable hardware-accelerated rendering
            attributes.flags = attributes.flags or 
                WindowManager.LayoutParams.FLAG_HARDWARE_ACCELERATED
                
            // Optimize window drawing
            setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
        }

        // Modern system UI handling
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.apply {
                systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            )
        }
        
        // Make window background transparent
        window.setBackgroundDrawableResource(android.R.color.transparent)
        
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            // Optimize Android 12+ splash screen exit
            splashScreen.setOnExitAnimationListener { splashScreenView ->
                splashScreenView.remove()
            }
        }
    }
}
