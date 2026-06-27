package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class NoorVerseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.noor_verse_widget)

            // Read from SharedPreferences saved by Flutter
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            
            // Get verse details
            val text = prefs.getString("flutter.widget_verse_text", "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ") ?: "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ"
            val ref = prefs.getString("flutter.widget_verse_ref", "سورة الرعد: ٢٨") ?: "سورة الرعد: ٢٨"

            // Update text values
            views.setTextViewText(R.id.widget_verse_text, text)
            views.setTextViewText(R.id.widget_verse_ref, ref)

            // Update app widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
