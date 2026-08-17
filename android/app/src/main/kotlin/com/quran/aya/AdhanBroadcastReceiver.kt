package com.quran.aya

import android.annotation.SuppressLint
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.os.Build
import android.os.PowerManager
import android.os.VibrationEffect
import android.os.Vibrator
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.media.VolumeProviderCompat
import android.util.Log

/**
 * Five-Prayers-style adhan architecture:
 * AlarmManager → BroadcastReceiver → silent notification card +
 * native MediaPlayer + MediaSession (volume-key stop) +
 * accelerometer (flip-face-down stop).
 */
class AdhanBroadcastReceiver : BroadcastReceiver(), SensorEventListener {

    @SuppressLint("MissingPermission")
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("ALARM_ID", 0)
        val mp3ResName = intent.getStringExtra("MP3_RES_NAME") ?: ""
        val prayerName = intent.getStringExtra("PRAYER_NAME") ?: "Prayer"
        val enableVibration = intent.getBooleanExtra("ENABLE_VIBRATION", true)
        val scheduledTimestamp = intent.getLongExtra("SCHEDULED_TIMESTAMP", 0L)
        val maxDurationMs = intent.getIntExtra("MAX_DURATION_MS", 0)

        val channelId = "adhan_alert_v5"
        val notifManager = NotificationManagerCompat.from(context)

        // ── Missed Prayer Check (If delayed by >5 minutes in deep sleep) ─────
        val now = System.currentTimeMillis()
        if (scheduledTimestamp > 0 && now - scheduledTimestamp > 5 * 60 * 1000) {
            val iconRes = context.resources.getIdentifier("ic_notification", "drawable", context.packageName)
            val missedNotif = NotificationCompat.Builder(context, channelId)
                .setSmallIcon(if (iconRes != 0) iconRes else android.R.drawable.ic_popup_reminder)
                .setContentTitle("⚠️ فاتك وقت $prayerName")
                .setContentText("تأخر التنبيه بسبب وضع توفير الطاقة")
                .setPriority(NotificationCompat.PRIORITY_HIGH)
                .setAutoCancel(true)
                .build()
            notifManager.notify(alarmId + 8000, missedNotif)
            return
        }

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "Aya:AdhanWakeLock"
        )
        wakeLock.acquire(10 * 60 * 1000L)

        // ── Notification card (silent — no sound, no vibration, no stop button) ─
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId, "Adhan Alert",
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Adhan playback notification"
                setSound(null, null)
                enableVibration(false)
                setShowBadge(false)
            }
            notifManager.createNotificationChannel(channel)
        }

        val tapIntent = context.packageManager
            .getLaunchIntentForPackage(context.packageName)
            ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP) }
        val tapPending = if (tapIntent != null) PendingIntent.getActivity(
            context, alarmId + 10000, tapIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        ) else null

        val iconRes = context.resources.getIdentifier(
            "ic_notification", "drawable", context.packageName
        )

        val fullScreenIntent = Intent(context, AdhanLockscreenActivity::class.java).apply {
            putExtra("PRAYER_NAME", prayerName)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        }
        val fullScreenPending = PendingIntent.getActivity(
            context, alarmId + 30000, fullScreenIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notif = NotificationCompat.Builder(context, channelId)
            .setSmallIcon(if (iconRes != 0) iconRes else android.R.drawable.ic_popup_reminder)
            .setContentTitle(prayerName)
            .setContentText(
                context.getString(
                    context.resources.getIdentifier(
                        "adhan_playing", "string", context.packageName
                    )
                ).ifEmpty { "Adhan is playing — tap to open the app" }
            )
            .setPriority(NotificationCompat.PRIORITY_HIGH)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setFullScreenIntent(fullScreenPending, true)
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(tapPending)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .extend(NotificationCompat.WearableExtender())
            .build()

        notifManager.notify(alarmId, notif)

        try {
            context.startActivity(fullScreenIntent)
        } catch (_: Exception) {}

        // ── Vibration (Fajr-specific pattern vs standard) ─────────────────────
        if (enableVibration) {
            try {
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (vibrator.hasVibrator()) {
                    val isFajr = prayerName.contains("الفجر") || prayerName.lowercase().contains("fajr")
                    val pattern = if (isFajr)
                        longArrayOf(0, 1000, 300, 1000, 300, 1000, 300, 500, 200, 500)
                    else
                        longArrayOf(0, 1000, 500, 1000, 500, 500)

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

        // ── Accelerometer (flip-face-down stop) ──────────────────────
        var accelSensorManager: SensorManager? = null
        try {
            val sm = context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
            accelSensorManager = sm
            val accelerometer = sm.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
            sm.registerListener(this, accelerometer, SensorManager.SENSOR_DELAY_NORMAL)
        } catch (_: Exception) {}

        // ── MediaPlayer (fallback to default_adhan if invalid resName) ────────
        val mappedResName = when {
            mp3ResName.contains("meshary") || mp3ResName == "mishary" -> "adhan_meshary_al_fasy_kuwait"
            mp3ResName.contains("abdelbasset") || mp3ResName == "abdul_basit" -> "adhan_abdelbasset_abdessamad_egypte"
            mp3ResName.contains("zahrani") || mp3ResName == "manssour" -> "adhan_manssour_el_zahrani"
            mp3ResName.contains("quds") || mp3ResName == "maghriby" -> "adhan_nurdin_hamza_al_maghriby_quds"
            mp3ResName.contains("kazabri") -> "adhan_omar_al_kazabri_morocco"
            mp3ResName.contains("riad") -> "adhan_riad_al_djazairi_algeria"
            mp3ResName.contains("nakshabandi") -> "adhan_sayed_al_nakshabandi_egypte"
            mp3ResName.contains("fajr_meshary") -> "adhan_fajr_meshary_al_fasy_kuwait"
            mp3ResName.contains("fajr_abdelbasset") -> "adhan_fajr_abdelbasset_abdessamad_egypte"
            mp3ResName.contains("fajr_al_haram") || mp3ResName == "madinah" -> "adhan_fajr_al_haram_el_madani_saoudia"
            mp3ResName.contains("haddiwi") || mp3ResName == "nurdin" -> "adhan_fajr_nurdin_al_haddiwi_fajr_morocco"
            mp3ResName.isNotEmpty() -> mp3ResName.replace(".mp3", "")
            else -> "default_adhan"
        }

        var resId = context.resources.getIdentifier(mappedResName, "raw", context.packageName)
        if (resId == 0) {
            resId = context.resources.getIdentifier("default_adhan", "raw", context.packageName)
        }
        if (resId == 0) {
            resId = context.resources.getIdentifier("adhan_meshary_al_fasy_kuwait", "raw", context.packageName)
        }

        if (resId == 0) {
            if (wakeLock.isHeld) wakeLock.release()
            return
        }

        lateinit var player: MediaPlayer
        lateinit var mediaSession: MediaSessionCompat

        fun triggerPostAdhanActions() {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

            // 1. Post-Adhan Dua Notification
            val duaEnabled = prefs.getBoolean("flutter.post_adhan_dua", true)
            if (duaEnabled) {
                val duaNotif = NotificationCompat.Builder(context, channelId)
                    .setSmallIcon(if (iconRes != 0) iconRes else android.R.drawable.ic_popup_reminder)
                    .setContentTitle("دعاء بعد الأذان")
                    .setContentText("اللهم رب هذه الدعوة التامة والصلاة القائمة آت محمداً الوسيلة والفضيلة وابعثه مقاماً محموداً الذي وعدته")
                    .setStyle(NotificationCompat.BigTextStyle().bigText("اللهم رب هذه الدعوة التامة والصلاة القائمة آت محمداً الوسيلة والفضيلة وابعثه مقاماً محموداً الذي وعدته، رضيت بالله رباً وبالإسلام ديناً وبمحمد صلى الله عليه وسلم نبياً ورسولاً."))
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setAutoCancel(true)
                    .setTimeoutAfter(60_000)
                    .build()
                notifManager.notify(alarmId + 9000, duaNotif)
            }

            // 2. Auto-DND Trigger
            val dndEnabled = prefs.getBoolean("flutter.auto_dnd_enabled", false)
            val dndMinutes = if (prefs.contains("flutter.auto_dnd_duration")) {
                prefs.getInt("flutter.auto_dnd_duration", 20)
            } else {
                prefs.getInt("flutter.auto_dnd_minutes", 20)
            }
            if (dndEnabled && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                if (nm.isNotificationPolicyAccessGranted) {
                    prefs.edit().putInt("flutter.prev_interruption_filter", nm.currentInterruptionFilter).apply()
                    nm.setInterruptionFilter(NotificationManager.INTERRUPTION_FILTER_PRIORITY)

                    val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                    val restoreIntent = Intent(context, DndRestoreReceiver::class.java)
                    val restorePending = PendingIntent.getBroadcast(
                        context, 6000, restoreIntent,
                        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                    )
                    alarmManager.setExactAndAllowWhileIdle(
                        android.app.AlarmManager.RTC_WAKEUP,
                        System.currentTimeMillis() + dndMinutes * 60_000L,
                        restorePending
                    )
                }
            }
        }

        fun stop() {
            try { player.stop(); player.release() } catch (_: Exception) {}
            try { mediaSession.release() } catch (_: Exception) {}
            try { accelSensorManager?.unregisterListener(this@AdhanBroadcastReceiver) } catch (_: Exception) {}
            notifManager.cancel(alarmId)
            if (wakeLock.isHeld) wakeLock.release()
            triggerPostAdhanActions()
        }

        // ── MediaSessionCompat for volume-key stop ──────────────────
        mediaSession = MediaSessionCompat(context, "AyaAdhan")
        mediaSession.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(PlaybackStateCompat.STATE_PLAYING, 0, 0f)
                .build()
        )
        val volumeProvider = object : VolumeProviderCompat(
            VolumeProviderCompat.VOLUME_CONTROL_RELATIVE, 100, 50
        ) {
            override fun onAdjustVolume(direction: Int) {
                stop()
            }
        }
        mediaSession.setPlaybackToRemote(volumeProvider)
        mediaSession.setActive(true)

        // ── MediaPlayer ─────────────────────────────────────────────
        try {
            player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(AudioAttributes.USAGE_ALARM)
                        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .setLegacyStreamType(AudioManager.STREAM_ALARM)
                        .build()
                )
                val afd = context.resources.openRawResourceFd(resId)
                if (afd != null) {
                    setDataSource(afd.fileDescriptor, afd.startOffset, afd.length)
                    afd.close()
                    prepare()
                }
            }
        } catch (e: Exception) {
            Log.e("AdhanBroadcastReceiver", "Error creating MediaPlayer: ${e.message}", e)
            if (wakeLock.isHeld) wakeLock.release()
            return
        }

        Companion.activeStop = ::stop

        player.setOnCompletionListener {
            stop()
        }
        player.setOnErrorListener { mp, _, _ ->
            stop()
            true
        }

        // ── Volume Ramp-Up (20% -> 100% over 5 seconds) ───────────────
        val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val rampUpEnabled = prefs.getBoolean("flutter.volume_ramp_up", true)
        if (rampUpEnabled) {
            player.setVolume(0.2f, 0.2f)
            val handler = android.os.Handler(android.os.Looper.getMainLooper())
            val steps = 8
            val interval = 5000L / steps
            for (i in 1..steps) {
                handler.postDelayed({
                    try {
                        if (player.isPlaying) {
                            val vol = 0.2f + (0.8f * i / steps)
                            player.setVolume(vol, vol)
                        }
                    } catch (_: Exception) {}
                }, interval * i)
            }
        }

        // ── Takbeer-only max duration handling ────────────────────────
        if (maxDurationMs > 0) {
            android.os.Handler(android.os.Looper.getMainLooper()).postDelayed({
                stop()
            }, maxDurationMs.toLong())
        }

        player.start()
    }

    // ── SensorEventListener (flip-face-down) ────────────────────────

    override fun onSensorChanged(event: SensorEvent?) {
        if (event == null) return
        if (event.sensor.type == Sensor.TYPE_ACCELEROMETER) {
            val z = event.values[2]
            if (z < -8.5f && Companion.lastZ >= -8.5f) {
                Companion.activeStop?.invoke()
            }
            Companion.lastZ = z
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    companion object {
        var activeStop: (() -> Unit)? = null
        var lastZ: Float = 0f

        fun stop(context: Context? = null) {
            activeStop?.invoke()
            activeStop = null
            context?.let { ctx ->
                try {
                    val nm = ctx.getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                    nm.cancelAll()
                } catch (_: Exception) {}
            }
        }
    }
}
