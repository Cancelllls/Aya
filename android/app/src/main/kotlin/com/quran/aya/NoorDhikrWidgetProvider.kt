package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class NoorDhikrWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.noor_dhikr_widget)

            // Read from SharedPreferences saved by Flutter
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // Get dhikr details
            val text = prefs.getString("flutter.widget_dhikr_text", "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ") ?: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ"

            // Update text values
            views.setTextViewText(R.id.widget_dhikr_text, text)

            // Update app widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
