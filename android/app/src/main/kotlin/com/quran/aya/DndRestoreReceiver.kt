package com.quran.aya

import android.app.NotificationManager
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class DndRestoreReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            try {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (nm.isNotificationPolicyAccessGranted) {
                    val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
                    val prevFilter = prefs.getInt("flutter.prev_interruption_filter", NotificationManager.INTERRUPTION_FILTER_ALL)
                    nm.setInterruptionFilter(prevFilter)
                }
            } catch (_: Exception) {}
        }
    }
}
