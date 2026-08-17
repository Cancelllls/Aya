package com.quran.aya

import android.app.Activity
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.TextView

class AdhanLockscreenActivity : Activity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Ensure activity shows over lockscreen and turns screen on
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

        val prayerName = intent.getStringExtra("PRAYER_NAME") ?: "الصلاة"

        // Build layout programmatically
        val container = android.widget.LinearLayout(this).apply {
            orientation = android.widget.LinearLayout.VERTICAL
            gravity = android.view.Gravity.CENTER
            setBackgroundColor(0xFF0F172A.toInt()) // Sleek dark slate
            setPadding(48, 48, 48, 48)
        }

        val titleView = TextView(this).apply {
            text = "حين على الصلاة 🕌"
            textSize = 22f
            setTextColor(0xFFE5C158.toInt()) // Gold accent
            gravity = android.view.Gravity.CENTER
        }

        val prayerView = TextView(this).apply {
            text = "حان الآن موعد أذان $prayerName"
            textSize = 28f
            setTypeface(null, android.graphics.Typeface.BOLD)
            setTextColor(0xFFFFFFFF.toInt())
            gravity = android.view.Gravity.CENTER
            setPadding(0, 24, 0, 48)
        }

        val stopButton = Button(this).apply {
            text = "إيقاف الأذان (Stop Adhan)"
            textSize = 16f
            setTextColor(0xFFFFFFFF.toInt())
            setBackgroundColor(0xFFB91C1C.toInt()) // Red button
            setPadding(32, 16, 32, 16)
            setOnClickListener {
                AdhanBroadcastReceiver.stop(this@AdhanLockscreenActivity)
                finish()
            }
        }

        container.addView(titleView)
        container.addView(prayerView)
        container.addView(stopButton)

        setContentView(container)
    }
}
