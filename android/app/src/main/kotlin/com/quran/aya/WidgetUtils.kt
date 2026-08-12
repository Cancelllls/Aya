package com.quran.aya

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews

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
