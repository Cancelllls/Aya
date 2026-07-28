package com.quran.aya

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.PowerManager
import android.media.MediaPlayer
import android.media.AudioAttributes

class AdhanBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (false) {
            Log.d("AdhanReceiver", "Adhan Alarm Triggered!")
        }
        
        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "Aya:AdhanWakeLock"
        )
        // Acquire wake lock for 10 minutes max
        wakeLock.acquire(10 * 60 * 1000L)

        try {
            val resId = context.resources.getIdentifier("default_adhan", "raw", context.packageName)
            if (resId != 0) {
                val mediaPlayer = MediaPlayer.create(context, resId)
                mediaPlayer.setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build()
                )
                mediaPlayer.setOnCompletionListener { 
                    it.release() 
                    if (wakeLock.isHeld) {
                        wakeLock.release()
                    }
                }
                mediaPlayer.start()
            } else {
                if (wakeLock.isHeld) wakeLock.release()
            }
        } catch (e: Exception) {
            e.printStackTrace()
            if (wakeLock.isHeld) wakeLock.release()
        }
    }
}
