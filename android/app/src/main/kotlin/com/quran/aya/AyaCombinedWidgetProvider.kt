package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.graphics.Color
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

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val appName = if (isArabic) "آية" else "Aya"

                val fajr = WidgetUtils.getSafeString(prefs, "widget_prayer_fajr", "--:--")
                val dhuhr = WidgetUtils.getSafeString(prefs, "widget_prayer_dhuhr", "--:--")
                val asr = WidgetUtils.getSafeString(prefs, "widget_prayer_asr", "--:--")
                val maghrib = WidgetUtils.getSafeString(prefs, "widget_prayer_maghrib", "--:--")
                val isha = WidgetUtils.getSafeString(prefs, "widget_prayer_isha", "--:--")

                val nextPrayerName = WidgetUtils.getSafeString(prefs, "widget_next_prayer_name", "")
                val nextPrayerEpoch = WidgetUtils.getSafeLong(prefs, "widget_next_prayer_epoch", 0L)
                val activePrayer = WidgetUtils.getSafeString(prefs, "widget_active_prayer", "")

                views.setTextViewText(R.id.widget_title, appName)

                val nowMs = System.currentTimeMillis()
                val remainingMs = nextPrayerEpoch - nowMs

                if (remainingMs > 0 && nextPrayerEpoch > 0L) {
                    val totalSeconds = (remainingMs / 1000).toInt()
                    val hours = totalSeconds / 3600
                    val minutes = (totalSeconds % 3600) / 60
                    val seconds = totalSeconds % 60
                    val countdown = String.format("%02d:%02d:%02d", hours, minutes, seconds)
                    views.setTextViewText(R.id.widget_countdown_timer, countdown)
                } else {
                    views.setTextViewText(R.id.widget_countdown_timer, "--:--:--")
                }

                val label = if (nextPrayerName.isNotEmpty()) {
                    if (isArabic) "حتى $nextPrayerName" else "Until $nextPrayerName"
                } else {
                    if (isArabic) "حتى الصلاة" else "Until Prayer"
                }
                views.setTextViewText(R.id.widget_countdown_label, label)
                views.setTextViewText(R.id.widget_next_label, if (isArabic) "التالي: " else "Next: ")
                views.setTextViewText(R.id.widget_next_prayer_name, nextPrayerName.ifEmpty {
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

                val activeBg = R.drawable.active_prayer_background
                val transBg = R.drawable.widget_transparent_bg

                setPrayerStyle(views, R.id.widget_fajr_container, R.id.widget_fajr_name, R.id.widget_fajr_time, activePrayer == "Fajr", activeBg, transBg)
                setPrayerStyle(views, R.id.widget_dhuhr_container, R.id.widget_dhuhr_name, R.id.widget_dhuhr_time, activePrayer == "Dhuhr", activeBg, transBg)
                setPrayerStyle(views, R.id.widget_asr_container, R.id.widget_asr_name, R.id.widget_asr_time, activePrayer == "Asr", activeBg, transBg)
                setPrayerStyle(views, R.id.widget_maghrib_container, R.id.widget_maghrib_name, R.id.widget_maghrib_time, activePrayer == "Maghrib", activeBg, transBg)
                setPrayerStyle(views, R.id.widget_isha_container, R.id.widget_isha_name, R.id.widget_isha_time, activePrayer == "Isha", activeBg, transBg)

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
            activeBg: Int,
            transBg: Int
        ) {
            try {
                if (isActive) {
                    views.setInt(containerId, "setBackgroundResource", activeBg)
                    views.setTextColor(nameId, Color.BLACK)
                    views.setTextColor(timeId, Color.BLACK)
                } else {
                    views.setInt(containerId, "setBackgroundResource", transBg)
                    views.setTextColor(nameId, Color.parseColor("#80FFFFFF"))
                    views.setTextColor(timeId, Color.WHITE)
                }
            } catch (_: Throwable) {}
        }
    }
}
