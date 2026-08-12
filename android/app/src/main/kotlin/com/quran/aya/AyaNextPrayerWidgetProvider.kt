package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.util.Log

class AyaNextPrayerWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_next_prayer_widget)
                val prefs = WidgetUtils.getPrefs(context)

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val nextPrayerName = WidgetUtils.getSafeString(prefs, "widget_next_prayer_name", "Asr")
                val nextPrayerTime = WidgetUtils.getSafeString(prefs, "widget_widget_next_display", "")

                views.setTextViewText(R.id.next_prayer_title, if (isArabic) "الصلاة القادمة" else "Next Prayer")
                views.setTextViewText(R.id.next_prayer_name, nextPrayerName)
                views.setTextViewText(R.id.next_prayer_time, nextPrayerTime.ifEmpty { "--:--" })

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaNextPrayerWidgetProvider", "Error updating next prayer widget: ${e.message}", e)
            }
        }
    }
}
