package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.graphics.Color
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

                val isDark = WidgetUtils.getSafeBoolean(prefs, "widget_is_dark", true)
                val asmaArabic = WidgetUtils.getSafeString(prefs, "widget_asma_arabic", "الرَّحْمَنُ")
                val asmaEnglish = WidgetUtils.getSafeString(prefs, "widget_asma_english", "Ar-Rahman")
                val asmaMeaning = WidgetUtils.getSafeString(prefs, "widget_asma_meaning", "The Beneficent")

                val bgRes = if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light
                val arabicColor = if (isDark) Color.parseColor("#E5C158") else Color.parseColor("#0D9488")
                val englishColor = if (isDark) Color.parseColor("#F8FAFC") else Color.parseColor("#0F172A")
                val meaningColor = if (isDark) Color.parseColor("#94A3B8") else Color.parseColor("#64748B")

                views.setInt(R.id.widget_root, "setBackgroundResource", bgRes)
                views.setTextViewText(R.id.asma_arabic, asmaArabic)
                views.setTextColor(R.id.asma_arabic, arabicColor)
                views.setTextViewText(R.id.asma_english, asmaEnglish)
                views.setTextColor(R.id.asma_english, englishColor)
                views.setTextViewText(R.id.asma_meaning, asmaMeaning)
                views.setTextColor(R.id.asma_meaning, meaningColor)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaAsmaulHusnaWidgetProvider", "Error updating asma widget: ${e.message}", e)
            }
        }
    }
}
