package com.quran.aya

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.view.Gravity
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class AdhanLockscreenActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Show over lockscreen and turn screen on for emergency Adhan alert
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD or
                WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON
            )
        }

        // Determine language from SharedPreferences / System Locale
        val prefs = getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
        val savedLang = prefs.getString("flutter.app_language", null)
            ?: prefs.getString("flutter.language", null)
            ?: Locale.getDefault().language

        val isAr = savedLang == "ar"

        // Receive raw prayer name
        val rawPrayerName = intent.getStringExtra("PRAYER_NAME") ?: "dhuhr"
        val lowerPrayer = rawPrayerName.lowercase()

        // Pure Arabic Prayer Names
        val prayerNameAr = when {
            lowerPrayer.contains("fajr") || lowerPrayer.contains("فجر") -> "الفجر"
            lowerPrayer.contains("dhuhr") || lowerPrayer.contains("ظهر") -> "الظهر"
            lowerPrayer.contains("asr") || lowerPrayer.contains("عصر") -> "العصر"
            lowerPrayer.contains("maghrib") || lowerPrayer.contains("مغرب") -> "المغرب"
            lowerPrayer.contains("isha") || lowerPrayer.contains("عشاء") -> "العشاء"
            else -> rawPrayerName
        }

        // Pure English Prayer Names
        val prayerNameEn = when {
            lowerPrayer.contains("fajr") || lowerPrayer.contains("فجر") -> "Fajr"
            lowerPrayer.contains("dhuhr") || lowerPrayer.contains("ظهر") -> "Dhuhr"
            lowerPrayer.contains("asr") || lowerPrayer.contains("عصر") -> "Asr"
            lowerPrayer.contains("maghrib") || lowerPrayer.contains("مغرب") -> "Maghrib"
            lowerPrayer.contains("isha") || lowerPrayer.contains("عشاء") -> "Isha"
            else -> rawPrayerName.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.ROOT) else it.toString() }
        }

        val titleText = if (isAr) "حيَّ على الصلاة 🕌" else "Come to Prayer 🕌"
        val bannerText = if (isAr) "حان الآن موعد أذان $prayerNameAr" else "It is now time for $prayerNameEn Prayer"
        val stopButtonText = if (isAr) "إيقاف الأذان" else "Stop Adhan"
        val openAppButtonText = if (isAr) "فتح التطبيق" else "Open Aya App"

        // Live formatted clock time
        val currentTimeStr = SimpleDateFormat("h:mm a", if (isAr) Locale("ar") else Locale.ENGLISH).format(Date())

        // Background Gradient (Obsidian Dark Blue Slate)
        val rootLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(64, 64, 64, 64)

            val backgroundGradient = GradientDrawable(
                GradientDrawable.Orientation.TOP_BOTTOM,
                intArrayOf(Color.parseColor("#0F172A"), Color.parseColor("#1E293B"), Color.parseColor("#0F172A"))
            )
            background = backgroundGradient
        }

        // Glassmorphic Card Container
        val cardContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(48, 48, 48, 48)

            val cardBackground = GradientDrawable().apply {
                setColor(Color.parseColor("#1A233A"))
                cornerRadius = 32f
                setStroke(2, Color.parseColor("#334155"))
            }
            background = cardBackground
        }

        // Top Gold Pill Badge
        val topBadge = TextView(this).apply {
            text = titleText
            textSize = 17f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.parseColor("#F59E0B")) // Warm Amber / Gold Accent
            gravity = Gravity.CENTER
            setPadding(32, 12, 32, 12)

            val badgeBg = GradientDrawable().apply {
                setColor(Color.parseColor("#26F59E0B"))
                cornerRadius = 24f
                setStroke(1, Color.parseColor("#4DF59E0B"))
            }
            background = badgeBg
        }

        // Icon Container Badge (Mosque / Notification Symbol)
        val iconBadge = TextView(this).apply {
            text = "🕌"
            textSize = 48f
            gravity = Gravity.CENTER
            setPadding(0, 32, 0, 16)
        }

        // Main Adhan Prayer Name Announcement Text
        val prayerAnnouncement = TextView(this).apply {
            text = bannerText
            textSize = 24f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            setPadding(0, 8, 0, 12)
        }

        // Current Clock Time Text
        val clockText = TextView(this).apply {
            text = currentTimeStr
            textSize = 16f
            setTextColor(Color.parseColor("#94A3B8")) // Muted Gray
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 48)
        }

        // Primary Stop Adhan Button (Red Pill Button)
        val stopButton = Button(this).apply {
            text = stopButtonText
            textSize = 17f
            typeface = Typeface.DEFAULT_BOLD
            setTextColor(Color.WHITE)
            setPadding(32, 20, 32, 20)

            val btnBg = GradientDrawable().apply {
                setColor(Color.parseColor("#DC2626")) // Vibrant Crimson Red
                cornerRadius = 24f
            }
            background = btnBg

            setOnClickListener {
                AdhanBroadcastReceiver.stop(this@AdhanLockscreenActivity)
                finish()
            }
        }

        // Secondary Open App Button (Outline Pill Button)
        val openAppButton = Button(this).apply {
            text = openAppButtonText
            textSize = 15f
            setTextColor(Color.parseColor("#CBD5E1"))
            setPadding(32, 16, 32, 16)

            val outlineBg = GradientDrawable().apply {
                setColor(Color.TRANSPARENT)
                cornerRadius = 24f
                setStroke(2, Color.parseColor("#334155"))
            }
            background = outlineBg

            setOnClickListener {
                AdhanBroadcastReceiver.stop(this@AdhanLockscreenActivity)
                val launchIntent = packageManager.getLaunchIntentForPackage(packageName)?.apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
                }
                if (launchIntent != null) {
                    startActivity(launchIntent)
                }
                finish()
            }
        }

        // Assemble Layout
        cardContainer.addView(topBadge)
        cardContainer.addView(iconBadge)
        cardContainer.addView(prayerAnnouncement)
        cardContainer.addView(clockText)
        cardContainer.addView(stopButton)

        // Spacing between buttons
        val spacer = LinearLayout(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                24
            )
        }
        cardContainer.addView(spacer)
        cardContainer.addView(openAppButton)

        rootLayout.addView(cardContainer)
        setContentView(rootLayout)
    }
}
