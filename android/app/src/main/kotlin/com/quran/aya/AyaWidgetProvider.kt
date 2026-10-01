package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.util.Log

class AyaWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return
        if (action == WidgetUtils.ACTION_PRAYER_AUTO_ADVANCE ||
            action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_TIME_SET ||
            action == Intent.ACTION_TIMEZONE_CHANGED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, AyaWidgetProvider::class.java))
            if (ids != null && ids.isNotEmpty()) {
                for (id in ids) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            }
        }
    }

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

                val upcoming = WidgetUtils.getNextUpcomingPrayer(context, prefs)

                views.setInt(R.id.widget_root, "setBackgroundResource", m3Theme.bgDrawable)
                views.setTextViewText(R.id.widget_title, appName)
                views.setTextColor(R.id.widget_title, m3Theme.primaryColor)
                views.setInt(R.id.widget_divider, "setBackgroundColor", m3Theme.dividerColor)

                views.setTextViewText(R.id.widget_fajr_name, if (isArabic) "الفجر" else "Fajr")
                views.setTextViewText(R.id.widget_dhuhr_name, if (isArabic) "الظهر" else "Dhuhr")
                views.setTextViewText(R.id.widget_asr_name, if (isArabic) "العصر" else "Asr")
                views.setTextViewText(R.id.widget_maghrib_name, if (isArabic) "المغرب" else "Maghrib")
                views.setTextViewText(R.id.widget_isha_name, if (isArabic) "العشاء" else "Isha")

                // Extract prayer times (prioritize upcoming.allPrayersToday from multi-day schedule)
                val times = upcoming.allPrayersToday
                val fajr = times["fajr"] ?: WidgetUtils.getSafeString(prefs, "widget_prayer_fajr", "--:--")
                val dhuhr = times["dhuhr"] ?: WidgetUtils.getSafeString(prefs, "widget_prayer_dhuhr", "--:--")
                val asr = times["asr"] ?: WidgetUtils.getSafeString(prefs, "widget_prayer_asr", "--:--")
                val maghrib = times["maghrib"] ?: WidgetUtils.getSafeString(prefs, "widget_prayer_maghrib", "--:--")
                val isha = times["isha"] ?: WidgetUtils.getSafeString(prefs, "widget_prayer_isha", "--:--")

                views.setTextViewText(R.id.widget_fajr_time, fajr)
                views.setTextViewText(R.id.widget_dhuhr_time, dhuhr)
                views.setTextViewText(R.id.widget_asr_time, asr)
                views.setTextViewText(R.id.widget_maghrib_time, maghrib)
                views.setTextViewText(R.id.widget_isha_time, isha)

                if (upcoming.name.isNotEmpty() && upcoming.formattedTime.isNotEmpty()) {
                    views.setTextViewText(R.id.widget_next_prayer, "${upcoming.name}: ${upcoming.formattedTime}")
                } else {
                    views.setTextViewText(R.id.widget_next_prayer, appName)
                }
                views.setTextColor(R.id.widget_next_prayer, m3Theme.textColor)

                val activeTarget = upcoming.prayerKey.ifEmpty {
                    val fallback = WidgetUtils.getSafeString(prefs, "widget_active_prayer", "")
                    if (fallback.isNotEmpty()) fallback else upcoming.name
                }

                val transBg = R.drawable.widget_transparent_bg
                safeSetStyle(views, R.id.widget_fajr_container, R.id.widget_fajr_name, R.id.widget_fajr_time, activeTarget.equals("fajr", true) || activeTarget.contains("Fajr", true) || activeTarget.contains("الفجر"), m3Theme, transBg)
                safeSetStyle(views, R.id.widget_dhuhr_container, R.id.widget_dhuhr_name, R.id.widget_dhuhr_time, activeTarget.equals("dhuhr", true) || activeTarget.contains("Dhuhr", true) || activeTarget.contains("الظهر"), m3Theme, transBg)
                safeSetStyle(views, R.id.widget_asr_container, R.id.widget_asr_name, R.id.widget_asr_time, activeTarget.equals("asr", true) || activeTarget.contains("Asr", true) || activeTarget.contains("العصر"), m3Theme, transBg)
                safeSetStyle(views, R.id.widget_maghrib_container, R.id.widget_maghrib_name, R.id.widget_maghrib_time, activeTarget.equals("maghrib", true) || activeTarget.contains("Maghrib", true) || activeTarget.contains("المغرب"), m3Theme, transBg)
                safeSetStyle(views, R.id.widget_isha_container, R.id.widget_isha_name, R.id.widget_isha_time, activeTarget.equals("isha", true) || activeTarget.contains("Isha", true) || activeTarget.contains("العشاء"), m3Theme, transBg)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaWidgetProvider", "Error updating widget: ${e.message}", e)
            }
        }

        private fun safeSetStyle(views: RemoteViews, containerId: Int, nameId: Int, timeId: Int, isActive: Boolean, theme: WidgetM3Theme, transBg: Int) {
            try {
                if (isActive) {
                    views.setInt(containerId, "setBackgroundResource", theme.activePillDrawable)
                    views.setTextColor(nameId, theme.activePillTextColor)
                    views.setTextColor(timeId, theme.activePillTextColor)
                } else {
                    views.setInt(containerId, "setBackgroundResource", transBg)
                    views.setTextColor(nameId, theme.subtitleColor)
                    views.setTextColor(timeId, theme.textColor)
                }
            } catch (_: Throwable) {}
        }
    }
}
