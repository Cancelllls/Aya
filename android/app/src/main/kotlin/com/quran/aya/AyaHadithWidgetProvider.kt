package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

class AyaHadithWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.aya_hadith_widget)

            // Read from SharedPreferences saved by Flutter
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isArabic = prefs.getBoolean("flutter.widget_is_arabic", true)
            val appName = if (isArabic) "آية" else "Aya"
            
            // Get Hadith details
            val text = prefs.getString("flutter.widget_hadith_text", "إنما الأعمال بالنيات وإنما لكل امرئ ما نوى") 
                ?: "إنما الأعمال بالنيات وإنما لكل امرئ ما نوى"
            val ref = prefs.getString("flutter.widget_hadith_ref", "رواه البخاري ومسلم") 
                ?: "رواه البخاري ومسلم"

            // Update text values
            views.setTextViewText(R.id.widget_hadith_text, text)
            views.setTextViewText(R.id.widget_hadith_ref, ref)

            // Update app widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
