package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.graphics.Color
import android.util.Log

class AyaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_widget)
                val prefs = WidgetUtils.getPrefs(context)
                val m3Theme = WidgetUtils.getM3Theme(context, prefs)

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val appName = if (isArabic) "آية" else "Aya"

                val fajr = WidgetUtils.getSafeString(prefs, "widget_prayer_fajr", "--:--")
                val dhuhr = WidgetUtils.getSafeString(prefs, "widget_prayer_dhuhr", "--:--")
                val asr = WidgetUtils.getSafeString(prefs, "widget_prayer_asr", "--:--")
                val maghrib = WidgetUtils.getSafeString(prefs, "widget_prayer_maghrib", "--:--")
                val isha = WidgetUtils.getSafeString(prefs, "widget_prayer_isha", "--:--")

                val nextName = WidgetUtils.getSafeString(prefs, "widget_next_prayer_name", "")
                val nextTime = WidgetUtils.getSafeString(prefs, "widget_widget_next_display", "")
                val activePrayer = WidgetUtils.getSafeString(prefs, "widget_active_prayer", "")

                views.setInt(R.id.widget_root, "setBackgroundResource", m3Theme.bgDrawable)
                views.setTextViewText(R.id.widget_title, appName)
                views.setTextColor(R.id.widget_title, m3Theme.primaryColor)
                views.setTextColor(R.id.widget_next_prayer, m3Theme.textColor)
                views.setInt(R.id.widget_divider, "setBackgroundColor", m3Theme.dividerColor)

                views.setTextViewText(R.id.widget_fajr_name, if (isArabic) "الفجر" else "Fajr")
                views.setTextViewText(R.id.widget_dhuhr_name, if (isArabic) "الظهر" else "Dhuhr")
                views.setTextViewText(R.id.widget_asr_name, if (isArabic) "العصر" else "Asr")
                views.setTextViewText(R.id.widget_maghrib_name, if (isArabic) "المغرب" else "Maghrib")
                views.setTextViewText(R.id.widget_isha_name, if (isArabic) "العشاء" else "Isha")

                views.setTextViewText(R.id.widget_fajr_time, fajr)
                views.setTextViewText(R.id.widget_dhuhr_time, dhuhr)
                views.setTextViewText(R.id.widget_asr_time, asr)
                views.setTextViewText(R.id.widget_maghrib_time, maghrib)
                views.setTextViewText(R.id.widget_isha_time, isha)

                if (nextName.isNotEmpty() && nextTime.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_next_prayer, "$nextName: $nextTime")
                } else {
                    views.setTextViewText(R.id.widget_next_prayer, appName)
                }

                val transBg = R.drawable.widget_transparent_bg
                val targetHighlight = if (activePrayer.isNotEmpty()) activePrayer else nextName

                safeSetStyle(views, R.id.widget_fajr_container, R.id.widget_fajr_name, R.id.widget_fajr_time, targetHighlight.contains("Fajr", ignoreCase = true) || targetHighlight.contains("الفجر"), m3Theme, transBg)
                safeSetStyle(views, R.id.widget_dhuhr_container, R.id.widget_dhuhr_name, R.id.widget_dhuhr_time, targetHighlight.contains("Dhuhr", ignoreCase = true) || targetHighlight.contains("الظهر"), m3Theme, transBg)
                safeSetStyle(views, R.id.widget_asr_container, R.id.widget_asr_name, R.id.widget_asr_time, targetHighlight.contains("Asr", ignoreCase = true) || targetHighlight.contains("العصر"), m3Theme, transBg)
                safeSetStyle(views, R.id.widget_maghrib_container, R.id.widget_maghrib_name, R.id.widget_maghrib_time, targetHighlight.contains("Maghrib", ignoreCase = true) || targetHighlight.contains("المغرب"), m3Theme, transBg)
                safeSetStyle(views, R.id.widget_isha_container, R.id.widget_isha_name, R.id.widget_isha_time, targetHighlight.contains("Isha", ignoreCase = true) || targetHighlight.contains("العشاء"), m3Theme, transBg)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaWidgetProvider", "Error updating widget: ${e.message}", e)
            }
        }

        private fun safeSetStyle(views: RemoteViews, containerId: Int, nameId: Int, timeId: Int, isActive: Boolean, theme: WidgetM3Theme, transBg: Int) {
            try {
                if (isActive) {
                    views.setInt(containerId, "setBackgroundResource", theme.badgeBgDrawable)
                    views.setTextColor(nameId, theme.badgeTextColor)
                    views.setTextColor(timeId, theme.badgeTextColor)
                } else {
                    views.setInt(containerId, "setBackgroundResource", transBg)
                    views.setTextColor(nameId, theme.subtitleColor)
                    views.setTextColor(timeId, theme.textColor)
                }
            } catch (_: Throwable) {}
        }
    }
}
