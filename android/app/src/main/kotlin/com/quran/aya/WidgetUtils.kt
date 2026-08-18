package com.quran.aya

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.widget.RemoteViews

data class WidgetM3Theme(
    val bgDrawable: Int,
    val primaryColor: Int,
    val textColor: Int,
    val subtitleColor: Int,
    val dividerColor: Int,
    val badgeBgDrawable: Int,
    val badgeTextColor: Int
)

data class UpcomingPrayerInfo(
    val name: String,
    val epochMs: Long,
    val formattedTime: String
)

object WidgetUtils {

    fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    fun getSafeString(prefs: SharedPreferences, key: String, defaultVal: String): String {
        return try {
            val keyWithPrefix = if (key.startsWith("flutter.")) key else "flutter.$key"
            prefs.getString(keyWithPrefix, defaultVal) ?: prefs.getString(key, defaultVal) ?: defaultVal
        } catch (_: Throwable) {
            defaultVal
        }
    }

    fun getSafeBoolean(prefs: SharedPreferences, key: String, defaultVal: Boolean): Boolean {
        return try {
            val keyWithPrefix = if (key.startsWith("flutter.")) key else "flutter.$key"
            if (prefs.contains(keyWithPrefix)) {
                prefs.getBoolean(keyWithPrefix, defaultVal)
            } else {
                prefs.getBoolean(key, defaultVal)
            }
        } catch (_: Throwable) {
            defaultVal
        }
    }

    fun getSafeInt(prefs: SharedPreferences, key: String, defaultVal: Int): Int {
        val keyWithPrefix = if (key.startsWith("flutter.")) key else "flutter.$key"
        val targetKey = if (prefs.contains(keyWithPrefix)) keyWithPrefix else key
        return try {
            prefs.getInt(targetKey, defaultVal)
        } catch (_: Throwable) {
            try {
                prefs.getLong(targetKey, defaultVal.toLong()).toInt()
            } catch (_: Throwable) {
                try {
                    prefs.getString(targetKey, null)?.toIntOrNull() ?: defaultVal
                } catch (_: Throwable) {
                    defaultVal
                }
            }
        }
    }

    fun getSafeLong(prefs: SharedPreferences, key: String, defaultVal: Long): Long {
        val keyWithPrefix = if (key.startsWith("flutter.")) key else "flutter.$key"
        val targetKey = if (prefs.contains(keyWithPrefix)) keyWithPrefix else key
        return try {
            prefs.getLong(targetKey, defaultVal)
        } catch (_: Throwable) {
            try {
                prefs.getInt(targetKey, defaultVal.toInt()).toLong()
            } catch (_: Throwable) {
                try {
                    prefs.getString(targetKey, null)?.toLongOrNull() ?: defaultVal
                } catch (_: Throwable) {
                    defaultVal
                }
            }
        }
    }

    fun getNextUpcomingPrayer(context: Context, prefs: SharedPreferences): UpcomingPrayerInfo {
        val isArabic = getSafeBoolean(prefs, "widget_is_arabic", true)
        val nowMs = System.currentTimeMillis()

        val fajrEpoch = getSafeLong(prefs, "widget_fajr_epoch", 0L)
        val dhuhrEpoch = getSafeLong(prefs, "widget_dhuhr_epoch", 0L)
        val asrEpoch = getSafeLong(prefs, "widget_asr_epoch", 0L)
        val maghribEpoch = getSafeLong(prefs, "widget_maghrib_epoch", 0L)
        val ishaEpoch = getSafeLong(prefs, "widget_isha_epoch", 0L)

        val fajrTime = getSafeString(prefs, "widget_prayer_fajr", "--:--")
        val dhuhrTime = getSafeString(prefs, "widget_prayer_dhuhr", "--:--")
        val asrTime = getSafeString(prefs, "widget_prayer_asr", "--:--")
        val maghribTime = getSafeString(prefs, "widget_prayer_maghrib", "--:--")
        val ishaTime = getSafeString(prefs, "widget_prayer_isha", "--:--")

        val list = listOf(
            UpcomingPrayerInfo(if (isArabic) "الفجر" else "Fajr", fajrEpoch, fajrTime),
            UpcomingPrayerInfo(if (isArabic) "الظهر" else "Dhuhr", dhuhrEpoch, dhuhrTime),
            UpcomingPrayerInfo(if (isArabic) "العصر" else "Asr", asrEpoch, asrTime),
            UpcomingPrayerInfo(if (isArabic) "المغرب" else "Maghrib", maghribEpoch, maghribTime),
            UpcomingPrayerInfo(if (isArabic) "العشاء" else "Isha", ishaEpoch, ishaTime)
        )

        // Find first prayer whose epoch is strictly in the future (> nowMs)
        for (item in list) {
            if (item.epochMs > nowMs) {
                return item
            }
        }

        // Fallback: stored next prayer or default
        val fallbackName = getSafeString(prefs, "widget_next_prayer_name", if (isArabic) "الفجر" else "Fajr")
        val fallbackEpoch = getSafeLong(prefs, "widget_next_prayer_epoch", 0L)
        val fallbackTime = getSafeString(prefs, "widget_widget_next_display", "--:--")

        return UpcomingPrayerInfo(fallbackName, fallbackEpoch, fallbackTime)
    }

    fun getM3Theme(context: Context, prefs: SharedPreferences): WidgetM3Theme {
        val preset = getSafeString(prefs, "theme_preset", "adaptive")
        val isDark = getSafeBoolean(prefs, "widget_is_dark", true)

        // Android 12+ (API 31+) Dynamic System Material You Colors
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && (preset == "adaptive" || preset == "system" || preset == "monet")) {
            try {
                val primary = context.getColor(android.R.color.system_accent1_500)
                val textColor = if (isDark) context.getColor(android.R.color.system_neutral1_100) else context.getColor(android.R.color.system_neutral1_900)
                val subtitleColor = if (isDark) context.getColor(android.R.color.system_neutral2_400) else context.getColor(android.R.color.system_neutral2_700)
                val dividerColor = if (isDark) Color.parseColor("#33FFFFFF") else Color.parseColor("#1F000000")

                return WidgetM3Theme(
                    bgDrawable = if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light,
                    primaryColor = primary,
                    textColor = textColor,
                    subtitleColor = subtitleColor,
                    dividerColor = dividerColor,
                    badgeBgDrawable = if (isDark) R.drawable.active_prayer_background else R.drawable.active_prayer_background_light,
                    badgeTextColor = if (isDark) Color.BLACK else Color.WHITE
                )
            } catch (_: Throwable) {}
        }

        return when (preset) {
            "light", "white_monet" -> WidgetM3Theme(
                bgDrawable = R.drawable.widget_background_light,
                primaryColor = Color.parseColor("#0D9488"), // M3 Teal
                textColor = Color.parseColor("#0F172A"),
                subtitleColor = Color.parseColor("#64748B"),
                dividerColor = Color.parseColor("#E2E8F0"),
                badgeBgDrawable = R.drawable.active_prayer_background_light,
                badgeTextColor = Color.WHITE
            )
            "sepia" -> WidgetM3Theme(
                bgDrawable = R.drawable.widget_background_sepia,
                primaryColor = Color.parseColor("#8C5A2B"), // M3 Sepia Warm
                textColor = Color.parseColor("#4A3B2C"),
                subtitleColor = Color.parseColor("#7A6451"),
                dividerColor = Color.parseColor("#E5DABF"),
                badgeBgDrawable = R.drawable.active_prayer_background_sepia,
                badgeTextColor = Color.WHITE
            )
            "black" -> WidgetM3Theme(
                bgDrawable = R.drawable.widget_background_black,
                primaryColor = Color.parseColor("#E5C158"), // M3 Gold
                textColor = Color.parseColor("#E5E5E5"),
                subtitleColor = Color.parseColor("#A3A3A3"),
                dividerColor = Color.parseColor("#262626"),
                badgeBgDrawable = R.drawable.active_prayer_background,
                badgeTextColor = Color.BLACK
            )
            "dark", "dark_monet" -> WidgetM3Theme(
                bgDrawable = R.drawable.widget_background_dark,
                primaryColor = Color.parseColor("#E5C158"),
                textColor = Color.parseColor("#F8FAFC"),
                subtitleColor = Color.parseColor("#94A3B8"),
                dividerColor = Color.parseColor("#33E5C158"),
                badgeBgDrawable = R.drawable.active_prayer_background,
                badgeTextColor = Color.BLACK
            )
            else -> if (isDark) {
                WidgetM3Theme(
                    bgDrawable = R.drawable.widget_background_dark,
                    primaryColor = Color.parseColor("#E5C158"),
                    textColor = Color.parseColor("#F8FAFC"),
                    subtitleColor = Color.parseColor("#94A3B8"),
                    dividerColor = Color.parseColor("#33E5C158"),
                    badgeBgDrawable = R.drawable.active_prayer_background,
                    badgeTextColor = Color.BLACK
                )
            } else {
                WidgetM3Theme(
                    bgDrawable = R.drawable.widget_background_light,
                    primaryColor = Color.parseColor("#0D9488"),
                    textColor = Color.parseColor("#0F172A"),
                    subtitleColor = Color.parseColor("#64748B"),
                    dividerColor = Color.parseColor("#E2E8F0"),
                    badgeBgDrawable = R.drawable.active_prayer_background_light,
                    badgeTextColor = Color.WHITE
                )
            }
        }
    }

    fun attachLaunchAppPendingIntent(context: Context, views: RemoteViews, viewId: Int) {
        try {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(viewId, pendingIntent)
        } catch (_: Throwable) {}
    }
}
