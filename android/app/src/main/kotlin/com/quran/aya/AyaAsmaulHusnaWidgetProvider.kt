package com.quran.aya

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class AyaAsmaulHusnaWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.aya_asma_widget)
            
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isArabic = prefs.getBoolean("flutter.widget_is_arabic", true)
            val appName = if (isArabic) "آية" else "Aya"
            val asmaArabic = prefs.getString("flutter.widget_asma_arabic", "الرَّحْمَنُ") ?: "الرَّحْمَنُ"
            val asmaEnglish = prefs.getString("flutter.widget_asma_english", "Ar-Rahman") ?: "Ar-Rahman"
            val asmaMeaning = prefs.getString("flutter.widget_asma_meaning", "The Beneficent") ?: "The Beneficent"
            
            views.setTextViewText(R.id.asma_arabic, asmaArabic)
            views.setTextViewText(R.id.asma_english, asmaEnglish)
            views.setTextViewText(R.id.asma_meaning, asmaMeaning)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            views.setOnClickPendingIntent(R.id.asma_arabic, pendingIntent)
            
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
