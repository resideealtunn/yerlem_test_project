package com.example.yerlem_test_proje

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.IBinder
import android.app.Service
import android.content.ComponentName
import android.content.ServiceConnection

class MainActivity : FlutterActivity() {
    private val CHANNEL = "background_location_service"
    private var backgroundService: BackgroundLocationService? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startBackgroundLocation" -> {
                    startBackgroundLocation()
                    result.success(null)
                }
                "stopBackgroundLocation" -> {
                    stopBackgroundLocation()
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun startBackgroundLocation() {
        val intent = Intent(this, BackgroundLocationService::class.java)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    private fun stopBackgroundLocation() {
        val intent = Intent(this, BackgroundLocationService::class.java)
        stopService(intent)
    }

    override fun onDestroy() {
        super.onDestroy()
        // Uygulama kapatıldığında background service'i durdurma
        // stopBackgroundLocation()
    }
}
