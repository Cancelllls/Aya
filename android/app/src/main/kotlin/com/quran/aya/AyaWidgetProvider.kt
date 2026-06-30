package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.graphics.Color

class AyaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.aya_widget)

            // Read from SharedPreferences saved by Flutter
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isArabic = prefs.getBoolean("flutter.widget_is_arabic", true)
            val appName = if (isArabic) "آية" else "Aya"
            
            // Get prayer times
            val fajr = prefs.getString("flutter.widget_prayer_fajr", "--:--") ?: "--:--"
            val dhuhr = prefs.getString("flutter.widget_prayer_dhuhr", "--:--") ?: "--:--"
            val asr = prefs.getString("flutter.widget_prayer_asr", "--:--") ?: "--:--"
            val maghrib = prefs.getString("flutter.widget_prayer_maghrib", "--:--") ?: "--:--"
            val isha = prefs.getString("flutter.widget_prayer_isha", "--:--") ?: "--:--"
            
            // Get status details
            val nextName = prefs.getString("flutter.widget_next_prayer_name", "") ?: ""
            val nextTime = prefs.getString("flutter.widget_widget_next_display", "") ?: "" // e.g. "Asr in 1h 10m" or "Maghrib 18:20"
            val activePrayer = prefs.getString("flutter.widget_active_prayer", "") ?: ""

            // Update labels in Arabic
            views.setTextViewText(R.id.widget_title, appName)
            views.setTextViewText(R.id.widget_fajr_name, "الفجر")
            views.setTextViewText(R.id.widget_dhuhr_name, "الظهر")
            views.setTextViewText(R.id.widget_asr_name, "العصر")
            views.setTextViewText(R.id.widget_maghrib_name, "المغرب")
            views.setTextViewText(R.id.widget_isha_name, "العشاء")

            // Update text values
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

            // Styling colors and backgrounds dynamically for active highlighting
            val activeBg = R.drawable.active_prayer_background
            val transBg = 0

            // Fajr container active style
            if (activePrayer == "Fajr") {
                views.setInt(R.id.widget_fajr_container, "setBackgroundResource", activeBg)
                views.setTextColor(R.id.widget_fajr_name, Color.BLACK)
                views.setTextColor(R.id.widget_fajr_time, Color.BLACK)
            } else {
                views.setInt(R.id.widget_fajr_container, "setBackgroundResource", transBg)
                views.setTextColor(R.id.widget_fajr_name, Color.parseColor("#80FFFFFF"))
                views.setTextColor(R.id.widget_fajr_time, Color.WHITE)
            }

            // Dhuhr container active style
            if (activePrayer == "Dhuhr") {
                views.setInt(R.id.widget_dhuhr_container, "setBackgroundResource", activeBg)
                views.setTextColor(R.id.widget_dhuhr_name, Color.BLACK)
                views.setTextColor(R.id.widget_dhuhr_time, Color.BLACK)
            } else {
                views.setInt(R.id.widget_dhuhr_container, "setBackgroundResource", transBg)
                views.setTextColor(R.id.widget_dhuhr_name, Color.parseColor("#80FFFFFF"))
                views.setTextColor(R.id.widget_dhuhr_time, Color.WHITE)
            }

            // Asr container active style
            if (activePrayer == "Asr") {
                views.setInt(R.id.widget_asr_container, "setBackgroundResource", activeBg)
                views.setTextColor(R.id.widget_asr_name, Color.BLACK)
                views.setTextColor(R.id.widget_asr_time, Color.BLACK)
            } else {
                views.setInt(R.id.widget_asr_container, "setBackgroundResource", transBg)
                views.setTextColor(R.id.widget_asr_name, Color.parseColor("#80FFFFFF"))
                views.setTextColor(R.id.widget_asr_time, Color.WHITE)
            }

            // Maghrib container active style
            if (activePrayer == "Maghrib") {
                views.setInt(R.id.widget_maghrib_container, "setBackgroundResource", activeBg)
                views.setTextColor(R.id.widget_maghrib_name, Color.BLACK)
                views.setTextColor(R.id.widget_maghrib_time, Color.BLACK)
            } else {
                views.setInt(R.id.widget_maghrib_container, "setBackgroundResource", transBg)
                views.setTextColor(R.id.widget_maghrib_name, Color.parseColor("#80FFFFFF"))
                views.setTextColor(R.id.widget_maghrib_time, Color.WHITE)
            }

            // Isha container active style
            if (activePrayer == "Isha") {
                views.setInt(R.id.widget_isha_container, "setBackgroundResource", activeBg)
                views.setTextColor(R.id.widget_isha_name, Color.BLACK)
                views.setTextColor(R.id.widget_isha_time, Color.BLACK)
            } else {
                views.setInt(R.id.widget_isha_container, "setBackgroundResource", transBg)
                views.setTextColor(R.id.widget_isha_name, Color.parseColor("#80FFFFFF"))
                views.setTextColor(R.id.widget_isha_time, Color.WHITE)
            }

            // Update app widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
