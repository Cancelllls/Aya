package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Build
import android.widget.RemoteViews
import android.util.Log

class AyaCombinedWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_combined_widget)
                val prefs = WidgetUtils.getPrefs(context)
                val m3Theme = WidgetUtils.getM3Theme(context, prefs)

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val appName = if (isArabic) "آية" else "Aya"

                val fajr = WidgetUtils.getSafeString(prefs, "widget_prayer_fajr", "--:--")
                val dhuhr = WidgetUtils.getSafeString(prefs, "widget_prayer_dhuhr", "--:--")
                val asr = WidgetUtils.getSafeString(prefs, "widget_prayer_asr", "--:--")
                val maghrib = WidgetUtils.getSafeString(prefs, "widget_prayer_maghrib", "--:--")
                val isha = WidgetUtils.getSafeString(prefs, "widget_prayer_isha", "--:--")

                val upcoming = WidgetUtils.getNextUpcomingPrayer(context, prefs)
                val activePrayer = WidgetUtils.getSafeString(prefs, "widget_active_prayer", "")
                val nowMs = System.currentTimeMillis()

                // Root Theme Background
                views.setInt(R.id.widget_root, "setBackgroundResource", m3Theme.bgDrawable)

                // Header styling
                views.setTextViewText(R.id.widget_title, appName)
                views.setTextColor(R.id.widget_title, m3Theme.primaryColor)
                views.setTextColor(R.id.widget_next_label, m3Theme.subtitleColor)
                views.setTextColor(R.id.widget_next_prayer_name, m3Theme.textColor)

                // Native Standalone Chronometer Setup with Negative Count Prevention
                if (upcoming.epochMs > nowMs) {
                    val durationMs = upcoming.epochMs - nowMs
                    val targetElapsedRealtime = android.os.SystemClock.elapsedRealtime() + durationMs
                    views.setChronometer(R.id.widget_countdown_timer, targetElapsedRealtime, null, true)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.widget_countdown_timer, true)
                    }
                } else {
                    // STOP chronometer cleanly so it NEVER displays negative numbers (-00:01)!
                    views.setChronometer(R.id.widget_countdown_timer, android.os.SystemClock.elapsedRealtime(), null, false)
                }

                // Countdown box background and text
                views.setInt(R.id.widget_countdown_box, "setBackgroundResource", m3Theme.badgeBgDrawable)
                views.setTextColor(R.id.widget_countdown_timer, m3Theme.badgeTextColor)
                views.setTextColor(R.id.widget_countdown_label, m3Theme.badgeTextColor)

                val label = if (upcoming.name.isNotEmpty()) {
                    if (isArabic) "حتى ${upcoming.name}" else "Until ${upcoming.name}"
                } else {
                    if (isArabic) "حتى الصلاة" else "Until Prayer"
                }
                views.setTextViewText(R.id.widget_countdown_label, label)
                views.setTextViewText(R.id.widget_next_label, if (isArabic) "التالي: " else "Next: ")
                views.setTextViewText(R.id.widget_next_prayer_name, upcoming.name.ifEmpty {
                    if (isArabic) "الصلاة" else "Prayer"
                })

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

                val transBg = R.drawable.widget_transparent_bg
                val targetHighlight = if (activePrayer.isNotEmpty()) activePrayer else upcoming.name

                setPrayerStyle(views, R.id.widget_fajr_container, R.id.widget_fajr_name, R.id.widget_fajr_time, targetHighlight.contains("Fajr", ignoreCase = true) || targetHighlight.contains("الفجر"), m3Theme, transBg)
                setPrayerStyle(views, R.id.widget_dhuhr_container, R.id.widget_dhuhr_name, R.id.widget_dhuhr_time, targetHighlight.contains("Dhuhr", ignoreCase = true) || targetHighlight.contains("الظهر"), m3Theme, transBg)
                setPrayerStyle(views, R.id.widget_asr_container, R.id.widget_asr_name, R.id.widget_asr_time, targetHighlight.contains("Asr", ignoreCase = true) || targetHighlight.contains("العصر"), m3Theme, transBg)
                setPrayerStyle(views, R.id.widget_maghrib_container, R.id.widget_maghrib_name, R.id.widget_maghrib_time, targetHighlight.contains("Maghrib", ignoreCase = true) || targetHighlight.contains("المغرب"), m3Theme, transBg)
                setPrayerStyle(views, R.id.widget_isha_container, R.id.widget_isha_name, R.id.widget_isha_time, targetHighlight.contains("Isha", ignoreCase = true) || targetHighlight.contains("العشاء"), m3Theme, transBg)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaCombinedWidgetProvider", "Error updating combined widget: ${e.message}", e)
            }
        }

        private fun setPrayerStyle(
            views: RemoteViews,
            containerId: Int,
            nameId: Int,
            timeId: Int,
            isActive: Boolean,
            theme: WidgetM3Theme,
            transBg: Int
        ) {
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
