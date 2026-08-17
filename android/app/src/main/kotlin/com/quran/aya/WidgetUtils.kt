package com.quran.aya

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
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

    fun getM3Theme(context: Context, prefs: SharedPreferences): WidgetM3Theme {
        val preset = getSafeString(prefs, "theme_preset", "dark")
        val isDark = getSafeBoolean(prefs, "widget_is_dark", true)

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
