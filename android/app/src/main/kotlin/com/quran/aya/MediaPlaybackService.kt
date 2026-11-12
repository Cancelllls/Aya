package com.quran.aya

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.BitmapFactory
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.support.v4.media.session.MediaSessionCompat
import androidx.core.app.NotificationCompat

class MediaPlaybackService : Service() {

    companion object {
        const val CHANNEL_ID = "aya_media_playback"
        const val NOTIFICATION_ID = 8888

        const val ACTION_START = "com.quran.aya.action.START_MEDIA"
        const val ACTION_STOP = "com.quran.aya.action.STOP_MEDIA"
        const val ACTION_TOGGLE = "com.quran.aya.action.TOGGLE"
        const val ACTION_NEXT = "com.quran.aya.action.NEXT"
        const val ACTION_PREV = "com.quran.aya.action.PREV"

        const val EXTRA_TITLE = "extra_title"
        const val EXTRA_SUBTITLE = "extra_subtitle"
        const val EXTRA_IS_PLAYING = "extra_is_playing"

        @Volatile
        private var isRunning = false

        fun startService(context: Context, title: String, subtitle: String, isPlaying: Boolean) {
            val intent = Intent(context, MediaPlaybackService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_SUBTITLE, subtitle)
                putExtra(EXTRA_IS_PLAYING, isPlaying)
            }
            try {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context.startForegroundService(intent)
                } else {
                    context.startService(intent)
                }
            } catch (_: Exception) {}
        }

        fun stopService(context: Context) {
            if (!isRunning) return
            val intent = Intent(context, MediaPlaybackService::class.java).apply {
                action = ACTION_STOP
            }
            try {
                context.startService(intent)
            } catch (_: Exception) {}
        }
    }

    private var wakeLock: PowerManager.WakeLock? = null
    private var wifiLock: WifiManager.WifiLock? = null
    private var mediaSession: MediaSessionCompat? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()

        try {
            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
            wakeLock = pm.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Aya:MediaPlaybackWakeLock").apply {
                setReferenceCounted(false)
            }
        } catch (_: Exception) {}

        try {
            val wm = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
            wifiLock = wm.createWifiLock(WifiManager.WIFI_MODE_FULL_HIGH_PERF, "Aya:MediaWifiLock").apply {
                setReferenceCounted(false)
            }
        } catch (_: Exception) {}

        try {
            mediaSession = MediaSessionCompat(this, "AyaMediaSession").apply {
                isActive = true
            }
        } catch (_: Exception) {}
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: return START_NOT_STICKY

        when (action) {
            ACTION_START -> {
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "Aya Quran"
                val subtitle = intent.getStringExtra(EXTRA_SUBTITLE) ?: ""
                val isPlaying = intent.getBooleanExtra(EXTRA_IS_PLAYING, false)

                if (isPlaying) {
                    try {
                        if (wakeLock?.isHeld != true) {
                            wakeLock?.acquire(4 * 60 * 60 * 1000L) // 4 hours safety timeout
                        }
                    } catch (_: Exception) {}
                    try {
                        if (wifiLock?.isHeld != true) {
                            wifiLock?.acquire()
                        }
                    } catch (_: Exception) {}
                } else {
                    releaseLocks()
                }

                val notification = buildNotification(title, subtitle, isPlaying)
                try {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        startForeground(
                            NOTIFICATION_ID,
                            notification,
                            ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK
                        )
                    } else {
                        startForeground(NOTIFICATION_ID, notification)
                    }
                } catch (_: Exception) {
                    try {
                        startForeground(NOTIFICATION_ID, notification)
                    } catch (_: Exception) {}
                }
            }
            ACTION_STOP -> {
                releaseLocks()
                try {
                    stopForeground(STOP_FOREGROUND_REMOVE)
                } catch (_: Exception) {
                    try {
                        @Suppress("DEPRECATION")
                        stopForeground(true)
                    } catch (_: Exception) {}
                }
                stopSelf()
                MainActivity.sendMediaAction("stop")
            }
            ACTION_TOGGLE -> {
                MainActivity.sendMediaAction("toggle")
            }
            ACTION_NEXT -> {
                MainActivity.sendMediaAction("next")
            }
            ACTION_PREV -> {
                MainActivity.sendMediaAction("previous")
            }
        }

        return START_NOT_STICKY
    }

    private fun releaseLocks() {
        try {
            if (wakeLock?.isHeld == true) {
                wakeLock?.release()
            }
        } catch (_: Exception) {}
        try {
            if (wifiLock?.isHeld == true) {
                wifiLock?.release()
            }
        } catch (_: Exception) {}
    }

    override fun onDestroy() {
        isRunning = false
        releaseLocks()
        try {
            mediaSession?.release()
        } catch (_: Exception) {}
        mediaSession = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Media Playback / مشغل الصوت",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Lock screen and notification controls for Quran audio playback"
                setShowBadge(false)
                setSound(null, null)
                enableVibration(false)
            }
            val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    private fun buildNotification(title: String, subtitle: String, isPlaying: Boolean): Notification {
        val tapIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        }
        val tapPending = if (tapIntent != null) {
            PendingIntent.getActivity(
                this, 0, tapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
        } else null

        val prevIntent = Intent(this, MediaPlaybackService::class.java).apply { action = ACTION_PREV }
        val prevPending = PendingIntent.getService(
            this, 1, prevIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val toggleIntent = Intent(this, MediaPlaybackService::class.java).apply { action = ACTION_TOGGLE }
        val togglePending = PendingIntent.getService(
            this, 2, toggleIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val nextIntent = Intent(this, MediaPlaybackService::class.java).apply { action = ACTION_NEXT }
        val nextPending = PendingIntent.getService(
            this, 3, nextIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val stopIntent = Intent(this, MediaPlaybackService::class.java).apply { action = ACTION_STOP }
        val stopPending = PendingIntent.getService(
            this, 4, stopIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val iconRes = resources.getIdentifier("ic_notification", "drawable", packageName)
        val smallIcon = if (iconRes != 0) iconRes else android.R.drawable.ic_media_play

        val launcherIconRes = resources.getIdentifier("ic_launcher", "mipmap", packageName)
        val largeIcon = if (launcherIconRes != 0) {
            try { BitmapFactory.decodeResource(resources, launcherIconRes) } catch (_: Exception) { null }
        } else null

        val toggleIcon = if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
        val toggleText = if (isPlaying) "Pause" else "Play"

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(subtitle)
            .setSmallIcon(smallIcon)
            .setLargeIcon(largeIcon)
            .setContentIntent(tapPending)
            .setOngoing(isPlaying)
            .setOnlyAlertOnce(true)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setCategory(NotificationCompat.CATEGORY_TRANSPORT)
            .setColor(0xFFE5C158.toInt())
            .addAction(android.R.drawable.ic_media_previous, "Previous", prevPending)
            .addAction(toggleIcon, toggleText, togglePending)
            .addAction(android.R.drawable.ic_media_next, "Next", nextPending)
            .addAction(android.R.drawable.ic_menu_close_clear_cancel, "Stop", stopPending)

        mediaSession?.let { session ->
            builder.setStyle(
                androidx.media.app.NotificationCompat.MediaStyle()
                    .setMediaSession(session.sessionToken)
                    .setShowActionsInCompactView(0, 1, 2)
            )
        }

        return builder.build()
    }
}
