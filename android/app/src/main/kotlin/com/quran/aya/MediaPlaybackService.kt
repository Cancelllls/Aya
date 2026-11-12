package com.quran.aya

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.net.wifi.WifiManager
import android.os.Build
import android.os.IBinder
import android.os.PowerManager
import android.support.v4.media.MediaMetadataCompat
import android.support.v4.media.session.MediaSessionCompat
import android.support.v4.media.session.PlaybackStateCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.core.content.res.ResourcesCompat

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
        const val EXTRA_ARTIST = "extra_artist"
        const val EXTRA_SUBTITLE = "extra_subtitle"
        const val EXTRA_IS_PLAYING = "extra_is_playing"

        @Volatile
        private var isRunning = false

        fun startService(
            context: Context,
            title: String,
            artist: String,
            subtitle: String,
            isPlaying: Boolean,
        ) {
            val intent = Intent(context, MediaPlaybackService::class.java).apply {
                action = ACTION_START
                putExtra(EXTRA_TITLE, title)
                putExtra(EXTRA_ARTIST, artist)
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
    private var ayaArtwork: Bitmap? = null

    private val mediaCallback = object : MediaSessionCompat.Callback() {
        override fun onPlay() {
            MainActivity.sendMediaAction("play")
        }

        override fun onPause() {
            MainActivity.sendMediaAction("pause")
        }

        override fun onSkipToNext() {
            MainActivity.sendMediaAction("next")
        }

        override fun onSkipToPrevious() {
            MainActivity.sendMediaAction("previous")
        }

        override fun onStop() {
            handleStopRequest()
        }
    }

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        createNotificationChannel()
        ayaArtwork = loadAyaArtworkBitmap()

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
                setCallback(mediaCallback)
                isActive = true
            }
        } catch (_: Exception) {}
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val action = intent?.action ?: return START_NOT_STICKY

        when (action) {
            ACTION_START -> {
                val title = intent.getStringExtra(EXTRA_TITLE) ?: "Aya Quran"
                val artist = intent.getStringExtra(EXTRA_ARTIST) ?: ""
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

                updateMediaSession(title, artist, isPlaying)
                val notification = buildNotification(title, artist, subtitle, isPlaying)
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
                handleStopRequest()
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

    private fun handleStopRequest() {
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
            mediaSession?.isActive = false
            mediaSession?.release()
        } catch (_: Exception) {}
        mediaSession = null
        ayaArtwork = null
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null

    /**
     * Render the official Aya crescent-and-star logo onto a full-bleed teal background
     * so Android MediaStyle / lockscreen cards display crisp background artwork (mipmap XML
     * adaptive icons cannot be decoded directly via BitmapFactory.decodeResource).
     */
    private fun loadAyaArtworkBitmap(): Bitmap? {
        val size = 512
        val bgColorRes = resources.getIdentifier("ic_launcher_background", "color", packageName)
        val fgDrawableRes = resources.getIdentifier("ic_launcher_foreground", "drawable", packageName)
        if (fgDrawableRes != 0) {
            try {
                val fgDrawable = ResourcesCompat.getDrawable(resources, fgDrawableRes, null)
                if (fgDrawable != null) {
                    val bitmap = Bitmap.createBitmap(size, size, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bitmap)
                    val bgColor = if (bgColorRes != 0) {
                        ContextCompat.getColor(this, bgColorRes)
                    } else {
                        0xFF0F766E.toInt()
                    }
                    canvas.drawColor(bgColor)
                    val pad = 32
                    fgDrawable.setBounds(pad, pad, size - pad, size - pad)
                    fgDrawable.draw(canvas)
                    return bitmap
                }
            } catch (_: Exception) {}
        }
        val launcherIconRes = resources.getIdentifier("ic_launcher", "mipmap", packageName)
        if (launcherIconRes != 0) {
            try {
                return BitmapFactory.decodeResource(resources, launcherIconRes)
            } catch (_: Exception) {}
        }
        return null
    }

    private fun updateMediaSession(title: String, artist: String, isPlaying: Boolean) {
        val session = mediaSession ?: return
        try {
            val metaBuilder = MediaMetadataCompat.Builder()
                .putString(MediaMetadataCompat.METADATA_KEY_TITLE, title)
                .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_TITLE, title)

            if (artist.isNotEmpty()) {
                metaBuilder
                    .putString(MediaMetadataCompat.METADATA_KEY_ARTIST, artist)
                    .putString(MediaMetadataCompat.METADATA_KEY_DISPLAY_SUBTITLE, artist)
            }

            ayaArtwork?.let { artwork ->
                metaBuilder
                    .putBitmap(MediaMetadataCompat.METADATA_KEY_ALBUM_ART, artwork)
                    .putBitmap(MediaMetadataCompat.METADATA_KEY_ART, artwork)
                    .putBitmap(MediaMetadataCompat.METADATA_KEY_DISPLAY_ICON, artwork)
            }
            session.setMetadata(metaBuilder.build())

            val state = if (isPlaying) {
                PlaybackStateCompat.STATE_PLAYING
            } else {
                PlaybackStateCompat.STATE_PAUSED
            }
            val actions =
                PlaybackStateCompat.ACTION_PLAY or
                    PlaybackStateCompat.ACTION_PAUSE or
                    PlaybackStateCompat.ACTION_PLAY_PAUSE or
                    PlaybackStateCompat.ACTION_SKIP_TO_NEXT or
                    PlaybackStateCompat.ACTION_SKIP_TO_PREVIOUS or
                    PlaybackStateCompat.ACTION_STOP

            session.setPlaybackState(
                PlaybackStateCompat.Builder()
                    .setActions(actions)
                    .setState(
                        state,
                        PlaybackStateCompat.PLAYBACK_POSITION_UNKNOWN,
                        if (isPlaying) 1.0f else 0.0f
                    )
                    .build()
            )
        } catch (_: Exception) {}
    }

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

    private fun buildNotification(
        title: String,
        artist: String,
        subtitle: String,
        isPlaying: Boolean,
    ): Notification {
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

        val toggleIcon = if (isPlaying) android.R.drawable.ic_media_pause else android.R.drawable.ic_media_play
        val toggleText = if (isPlaying) "Pause" else "Play"

        val builder = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(artist.ifEmpty { subtitle })
            .setSmallIcon(smallIcon)
            .setLargeIcon(ayaArtwork)
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

        if (artist.isNotEmpty() && subtitle.isNotEmpty()) {
            builder.setSubText(subtitle)
        }

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
