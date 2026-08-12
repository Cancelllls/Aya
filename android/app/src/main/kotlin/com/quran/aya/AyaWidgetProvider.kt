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

                views.setTextViewText(R.id.widget_title, appName)
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

                val activeBg = R.drawable.active_prayer_background
                val transBg = R.drawable.widget_transparent_bg

                fun safeSetStyle(containerId: Int, nameId: Int, timeId: Int, isActive: Boolean) {
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

                safeSetStyle(R.id.widget_fajr_container, R.id.widget_fajr_name, R.id.widget_fajr_time, activePrayer == "Fajr")
                safeSetStyle(R.id.widget_dhuhr_container, R.id.widget_dhuhr_name, R.id.widget_dhuhr_time, activePrayer == "Dhuhr")
                safeSetStyle(R.id.widget_asr_container, R.id.widget_asr_name, R.id.widget_asr_time, activePrayer == "Asr")
                safeSetStyle(R.id.widget_maghrib_container, R.id.widget_maghrib_name, R.id.widget_maghrib_time, activePrayer == "Maghrib")
                safeSetStyle(R.id.widget_isha_container, R.id.widget_isha_name, R.id.widget_isha_time, activePrayer == "Isha")

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaWidgetProvider", "Error updating widget: ${e.message}", e)
            }
        }
    }
}
