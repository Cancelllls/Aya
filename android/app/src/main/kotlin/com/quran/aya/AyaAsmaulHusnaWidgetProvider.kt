package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.util.Log

class AyaAsmaulHusnaWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_asma_widget)
                val prefs = WidgetUtils.getPrefs(context)

                val asmaArabic = WidgetUtils.getSafeString(prefs, "widget_asma_arabic", "الرَّحْمَنُ")
                val asmaEnglish = WidgetUtils.getSafeString(prefs, "widget_asma_english", "Ar-Rahman")
                val asmaMeaning = WidgetUtils.getSafeString(prefs, "widget_asma_meaning", "The Beneficent")

                views.setTextViewText(R.id.asma_arabic, asmaArabic)
                views.setTextViewText(R.id.asma_english, asmaEnglish)
                views.setTextViewText(R.id.asma_meaning, asmaMeaning)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaAsmaulHusnaWidgetProvider", "Error updating asma widget: ${e.message}", e)
            }
        }
    }
}
