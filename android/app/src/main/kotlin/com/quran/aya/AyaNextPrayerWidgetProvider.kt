package com.quran.aya

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class AyaNextPrayerWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.aya_next_prayer_widget)
            
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isArabic = prefs.getBoolean("flutter.widget_is_arabic", true)
            val appName = if (isArabic) "آية" else "Aya"
            val nextPrayerName = prefs.getString("flutter.widget_next_prayer_name", "Asr") ?: "Asr"
            val nextPrayerTime = prefs.getString("flutter.widget_widget_next_display", "Loading...") ?: "Loading..."
            
            views.setTextViewText(R.id.next_prayer_name, nextPrayerName)
            views.setTextViewText(R.id.next_prayer_time, nextPrayerTime)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.next_prayer_title, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
