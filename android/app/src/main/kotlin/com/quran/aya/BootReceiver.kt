package com.quran.aya

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == "android.intent.action.QUICKBOOT_POWERON") {
            Log.d("BootReceiver", "Device rebooted, need to reschedule prayers.")
            
            // To reschedule prayers on boot via Dart, one robust approach is to wake up 
            // the Flutter application. Another is to start a background service that spins up a FlutterEngine.
            // As requested, this BootReceiver acts as the trigger point for a MethodChannel call
            // or background service.
            
            // Attempt to launch the main app in background or notify the system
            try {
                val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
                launchIntent?.let {
                    // For modern Android, background activity launches are restricted.
                    // This is a simplified approach. Usually, flutter_local_notifications
                    // handles boot completion internally, or a foreground service is started.
                    it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    context.startActivity(it)
                }
            } catch (e: Exception) {
                Log.e("BootReceiver", "Failed to handle boot event: \${e.message}")
            }
        }
    }
}
