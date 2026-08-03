package com.quran.aya

import android.annotation.SuppressLint
import android.app.Notification
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

        val powerManager = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val wakeLock = powerManager.newWakeLock(
            PowerManager.PARTIAL_WAKE_LOCK or PowerManager.ACQUIRE_CAUSES_WAKEUP,
            "Aya:AdhanWakeLock"
        )
        wakeLock.acquire(10 * 60 * 1000L)

        // ── Notification card (silent — no sound, no vibration, no stop button) ─
        val channelId = "adhan_alert_v4"
        val notifManager = NotificationManagerCompat.from(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId, "Athan Alert",
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
            .setOngoing(true)
            .setAutoCancel(false)
            .setContentIntent(tapPending)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .build()

        notifManager.notify(alarmId, notif)

        // ── Vibration ───────────────────────────────────────────────────
        if (enableVibration) {
            try {
                val vibrator = context.getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                if (vibrator.hasVibrator()) {
                    val pattern = longArrayOf(0, 1000, 500, 1000, 500, 500)
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

        // ── MediaPlayer (skip if silent mode requested) ────────────────
        val resId = if (mp3ResName.isNotEmpty())
            context.resources.getIdentifier(mp3ResName, "raw", context.packageName)
        else 0

        if (resId == 0) {
            if (wakeLock.isHeld) wakeLock.release()
            return
        }

        // ── MediaSessionCompat for volume-key stop ──────────────────
        val mediaSession = MediaSessionCompat(context, "AyaAdhan")
        mediaSession.setPlaybackState(
            PlaybackStateCompat.Builder()
                .setState(PlaybackStateCompat.STATE_PLAYING, 0, 0f)
                .build()
        )
        val volumeProvider = object : VolumeProviderCompat(
            VolumeProviderCompat.VOLUME_CONTROL_RELATIVE, 100, 50
        ) {
            override fun onAdjustVolume(direction: Int) {
                // direction -1 = volume down, 1 = volume up — stop on either
                stop()
            }
        }
        mediaSession.setPlaybackToRemote(volumeProvider)
        mediaSession.setActive(true)

        // ── MediaPlayer ─────────────────────────────────────────────
        val player = MediaPlayer.create(context, resId)
        player.setAudioAttributes(
            AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .setLegacyStreamType(AudioManager.STREAM_ALARM)
                .build()
        )

        fun stop() {
            try { player.stop(); player.release() } catch (_: Exception) {}
            mediaSession.release()
            try { accelSensorManager?.unregisterListener(this@AdhanBroadcastReceiver) } catch (_: Exception) {}
            notifManager.cancel(alarmId)
            if (wakeLock.isHeld) wakeLock.release()
        }

        Companion.activeStop = ::stop

        player.setOnCompletionListener {
            it.release()
            mediaSession.release()
            try { accelSensorManager?.unregisterListener(this@AdhanBroadcastReceiver) } catch (_: Exception) {}
            notifManager.cancel(alarmId)
            if (wakeLock.isHeld) wakeLock.release()
        }
        player.setOnErrorListener { mp, _, _ ->
            mp.release()
            mediaSession.release()
            try { accelSensorManager?.unregisterListener(this@AdhanBroadcastReceiver) } catch (_: Exception) {}
            notifManager.cancel(alarmId)
            if (wakeLock.isHeld) wakeLock.release()
            true
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
    }
}
