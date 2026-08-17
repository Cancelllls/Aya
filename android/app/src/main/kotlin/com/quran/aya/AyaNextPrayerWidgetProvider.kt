package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Build
import android.widget.RemoteViews
import android.graphics.Color
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
                val m3Theme = WidgetUtils.getM3Theme(context, prefs)

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val nextPrayerName = WidgetUtils.getSafeString(prefs, "widget_next_prayer_name", "Asr")
                val nextPrayerTime = WidgetUtils.getSafeString(prefs, "widget_widget_next_display", "")
                val nextPrayerEpoch = WidgetUtils.getSafeLong(prefs, "widget_next_prayer_epoch", 0L)

                views.setInt(R.id.widget_root, "setBackgroundResource", m3Theme.bgDrawable)
                views.setTextViewText(R.id.next_prayer_title, if (isArabic) "الصلاة القادمة" else "Next Prayer")
                views.setTextColor(R.id.next_prayer_title, m3Theme.primaryColor)

                views.setTextViewText(R.id.next_prayer_name, nextPrayerName)
                views.setTextColor(R.id.next_prayer_name, m3Theme.textColor)

                if (nextPrayerEpoch > System.currentTimeMillis()) {
                    views.setChronometer(R.id.next_prayer_chronometer, nextPrayerEpoch, null, true)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.next_prayer_chronometer, true)
                    }
                    views.setTextColor(R.id.next_prayer_chronometer, m3Theme.primaryColor)
                } else {
                    views.setTextViewText(R.id.next_prayer_time, nextPrayerTime.ifEmpty { "--:--" })
                    views.setTextColor(R.id.next_prayer_time, m3Theme.primaryColor)
                }

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaNextPrayerWidgetProvider", "Error updating next prayer widget: ${e.message}", e)
            }
        }
    }
}
