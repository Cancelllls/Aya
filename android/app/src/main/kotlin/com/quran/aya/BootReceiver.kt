package com.quran.aya

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build

class BootReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val validActions = setOf(
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            "com.htc.intent.action.QUICKBOOT_POWERON",
            Intent.ACTION_TIME_CHANGED,
            Intent.ACTION_TIMEZONE_CHANGED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_LOCALE_CHANGED
        )

        if (intent.action !in validActions) return

        rescheduleAlarms(context)
    }

    private fun rescheduleAlarms(context: Context) {
        val prefs = context.getSharedPreferences("adhan_alarms_native", Context.MODE_PRIVATE)
        val allKeys = prefs.all.keys.filter { it.endsWith("_trigger") }
        val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager

        for (key in allKeys) {
            val idStr = key.removePrefix("alarm_").removeSuffix("_trigger")
            val id = idStr.toIntOrNull() ?: continue

            val triggerAt = prefs.getLong(key, 0L)
            if (triggerAt <= System.currentTimeMillis()) continue // Skip past alarms

            val mp3ResName = prefs.getString("alarm_${id}_mp3", "") ?: ""
            val prayerName = prefs.getString("alarm_${id}_prayer", "Prayer") ?: "Prayer"
            val vibration = prefs.getBoolean("alarm_${id}_vibration", true)
            val isPreAdhan = prefs.getBoolean("alarm_${id}_is_pre_adhan", false)
            val minutesBefore = prefs.getInt("alarm_${id}_minutes_before", 10)
            val alertMode = prefs.getString("alarm_${id}_alert_mode", "vibrate") ?: "vibrate"

            val targetClass = if (isPreAdhan) PreAdhanBroadcastReceiver::class.java else AdhanBroadcastReceiver::class.java
            val alarmIntent = Intent(context, targetClass).apply {
                if (isPreAdhan) {
                    putExtra("ALARM_ID", id)
                    putExtra("PRAYER_NAME", prayerName)
                    putExtra("MINUTES_BEFORE", minutesBefore)
                    putExtra("ALERT_MODE", alertMode)
                } else {
                    putExtra("ALARM_ID", id)
                    putExtra("MP3_RES_NAME", mp3ResName)
                    putExtra("PRAYER_NAME", prayerName)
                    putExtra("ENABLE_VIBRATION", vibration)
                    putExtra("SCHEDULED_TIMESTAMP", triggerAt)
                }
            }

            val pendingIntent = PendingIntent.getBroadcast(
                context, id, alarmIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            val showIntent = PendingIntent.getActivity(
                context,
                id + 50000,
                Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                },
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                    val clockInfo = AlarmManager.AlarmClockInfo(triggerAt, showIntent)
                    alarmManager.setAlarmClock(clockInfo, pendingIntent)
                } else {
                    alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                }
            } catch (e: Exception) {
                try {
                    alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
                } catch (_: Exception) {}
            }
        }
    }
}
