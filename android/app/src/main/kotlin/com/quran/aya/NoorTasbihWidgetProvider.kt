package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class NoorTasbihWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.noor_tasbih_widget)

            // Read from SharedPreferences saved by Flutter
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // Get Tasbih details
            val dhikrText = prefs.getString("flutter.widget_tasbih_dhikr", "سُبْحَانَ ٱللَّٰهِ") 
                ?: "سُبْحَانَ ٱللَّٰهِ"
            val count = prefs.getInt("flutter.widget_tasbih_count", 0)
            val target = prefs.getInt("flutter.widget_tasbih_target", 33)

            // Update text values
            views.setTextViewText(R.id.widget_tasbih_dhikr, dhikrText)
            views.setTextViewText(R.id.widget_tasbih_count, "$count / $target")

            // Update app widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
