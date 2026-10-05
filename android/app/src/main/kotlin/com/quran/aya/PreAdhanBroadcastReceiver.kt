package com.quran.aya

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.media.AudioAttributes
import android.net.Uri
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

class PreAdhanBroadcastReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("ALARM_ID", 0)
        val rawPrayerName = intent.getStringExtra("PRAYER_NAME") ?: "Prayer"
        val minutesBefore = intent.getIntExtra("MINUTES_BEFORE", 10)
        val alertMode = intent.getStringExtra("ALERT_MODE") ?: "vibrate"

        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val notifLang = prefs.getString("flutter.notification_lang", "follow_app") ?: "follow_app"
        val isAr = when (notifLang) {
            "ar" -> true
            "en" -> false
            else -> {
                val langCode = prefs.getString("flutter.lang_code", "ar") ?: "ar"
                langCode == "ar" || prefs.getBoolean("flutter.widget_is_arabic", true)
            }
        }

        val isJumuah = rawPrayerName.contains("الجمعة") || rawPrayerName.contains("jumu", ignoreCase = true)
        val isWarning = rawPrayerName.startsWith("⚠️")
        val isEarly = rawPrayerName.startsWith("⏰") || rawPrayerName.contains("مبكر", ignoreCase = true) || rawPrayerName.contains("early", ignoreCase = true)
        val isIqamah = (!isJumuah && !isWarning && !isEarly) && (rawPrayerName.startsWith("🕌") || minutesBefore < 0 || rawPrayerName.contains("إقامة") || rawPrayerName.contains("iqamah", ignoreCase = true))

        val pKey = when {
            rawPrayerName.contains("fajr", ignoreCase = true) || rawPrayerName.contains("فجر") -> "fajr"
            rawPrayerName.contains("dhuhr", ignoreCase = true) || rawPrayerName.contains("ظهر") -> "dhuhr"
            rawPrayerName.contains("asr", ignoreCase = true) || rawPrayerName.contains("عصر") -> "asr"
            rawPrayerName.contains("maghrib", ignoreCase = true) || rawPrayerName.contains("مغرب") -> "maghrib"
            rawPrayerName.contains("isha", ignoreCase = true) || rawPrayerName.contains("عشاء") -> "isha"
            else -> rawPrayerName.lowercase().trim()
        }

        val prayerName = when (pKey) {
            "fajr" -> if (isAr) "الفجر" else "Fajr"
            "dhuhr" -> if (isAr) "الظهر" else "Dhuhr"
            "asr" -> if (isAr) "العصر" else "Asr"
            "maghrib" -> if (isAr) "المغرب" else "Maghrib"
            "isha" -> if (isAr) "العشاء" else "Isha"
            else -> rawPrayerName
        }

        val storedPreMode = prefs.getString("flutter.pre_adhan_${pKey}_mode", null)
            ?: prefs.getString("flutter.pre_adhan_alert_mode", alertMode)
        val effectiveAlertMode = storedPreMode ?: alertMode

        if (effectiveAlertMode == "off") return

        val isSound = effectiveAlertMode == "sound" || effectiveAlertMode == "real_reciter"
        val soundTone = prefs.getString("flutter.notification_sound_tone", "chime") ?: "chime"
        val soundRawName = when (soundTone) {
            "call" -> "prayer_reminder_call"
            "takbeer" -> "adhan_meshary_al_fasy_kuwait"
            "system" -> null
            else -> "default_pre_adhan"
        }
        val channelId = if (!isSound) {
            "pre_adhan_silent_channel_v2"
        } else if (soundRawName != null) {
            "pre_adhan_tone_${soundTone}_v1"
        } else {
            "pre_adhan_system_channel_v1"
        }
        val notifManager = NotificationManagerCompat.from(context)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val soundUri = if (soundRawName != null) {
                Uri.parse("android.resource://${context.packageName}/raw/$soundRawName")
            } else {
                android.provider.Settings.System.DEFAULT_NOTIFICATION_URI
            }
            val channel = NotificationChannel(
                channelId,
                if (isSound) "Pre-Adhan Sound Alerts" else "Pre-Adhan Silent Alerts",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Reminders before prayer time"
                if (isSound) {
                    setSound(
                        soundUri,
                        AudioAttributes.Builder()
                            .setUsage(AudioAttributes.USAGE_ALARM)
                            .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                            .build()
                    )
                } else {
                    setSound(null, null)
                }
                enableVibration(alertMode != "silent")
            }
            notifManager.createNotificationChannel(channel)
        }

        val tapIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP) }
        val tapPending = if (tapIntent != null) PendingIntent.getActivity(
            context, alarmId + 20000, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        ) else null

        val iconRes = context.resources.getIdentifier(
            "ic_notification", "drawable", context.packageName
        )

        val absMinutes = kotlin.math.abs(minutesBefore)
        val minutesStr = if (!isAr) {
            "$absMinutes minute${if (absMinutes == 1) "" else "s"}"
        } else {
            when (absMinutes) {
                1 -> "دقيقة واحدة"
                2 -> "دقيقتين"
                in 3..10 -> "$absMinutes دقائق"
                else -> "$absMinutes دقيقة"
            }
        }

        val (title, body) = when {
            isWarning -> {
                val t = if (isAr) "⚠️ تنبيه قرب انتهاء الوقت" else "⚠️ Prayer Time Ending Soon"
                val cleanMsg = rawPrayerName.removePrefix("⚠️").trim()
                val b = if (cleanMsg.isNotEmpty() && cleanMsg != "Prayer") cleanMsg else {
                    if (isAr) "سارع بأداء صلاة $prayerName قبل خروج وقتها" else "Hurry to pray $prayerName before its time ends"
                }
                Pair(t, b)
            }
            isJumuah -> {
                val t = if (isAr) "🕌 صلاة الجمعة" else "🕌 Jumu'ah Prayer"
                val b = if (isAr) "بقي $minutesStr على صلاة الجمعة، تهيأ للذهاب إلى المسجد" else "$minutesStr remaining until Jumu'ah prayer"
                Pair(t, b)
            }
            isEarly -> {
                val t = if (isAr) "⏰ تنبيه مبكر للصلاة" else "⏰ Early Prayer Reminder"
                val b = if (isAr) "بقي $minutesStr على أذان صلاة $prayerName" else "$minutesStr remaining until $prayerName Adhan"
                Pair(t, b)
            }
            isIqamah -> {
                val t = if (isAr) "🕌 إقامة الصلاة" else "🕌 Iqamah Reminder"
                val b = if (isAr) "حان الآن موعد إقامة صلاة $prayerName" else "It is now time for $prayerName prayer Iqamah"
                Pair(t, b)
            }
            else -> {
                val t = if (isAr) "اقترب موعد الأذان" else "Adhan is approaching"
                val b = if (isAr) "بقي $minutesStr على أذان $prayerName" else "$minutesStr remaining until $prayerName Adhan"
                Pair(t, b)
            }
        }

        val notifBuilder = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(if (iconRes != 0) iconRes else android.R.drawable.ic_popup_reminder)
            .setContentTitle(title)
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_REMINDER)
            .setAutoCancel(true)
            .setContentIntent(tapPending)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .extend(NotificationCompat.WearableExtender())

        if (!isSound) {
            notifBuilder.setSound(null)
        }

        notifManager.notify(alarmId, notifBuilder.build())

        if (alertMode == "sound" || alertMode == "real_reciter") {
            try {
                if (soundRawName != null) {
                    val soundResId = context.resources.getIdentifier(soundRawName, "raw", context.packageName)
                    if (soundResId != 0) {
                        val player = android.media.MediaPlayer.create(context, soundResId)
                        player?.start()
                        player?.setOnCompletionListener { mp -> mp.release() }
                    }
                }
            } catch (_: Exception) {}
        }

        if (alertMode != "silent") {
            try {
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (vibrator.hasVibrator()) {
                    val pattern = longArrayOf(0, 500, 200, 500, 200, 200)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        vibrator.vibrate(
                            VibrationEffect.createWaveform(pattern, -1),
                            AudioAttributes.Builder()
                                .setUsage(AudioAttributes.USAGE_ALARM)
                                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                                .build()
                        )
                    } else {
                        @Suppress("DEPRECATION")
                        vibrator.vibrate(pattern, -1)
                    }
                }
            } catch (_: Exception) {}
        }
    }
}
