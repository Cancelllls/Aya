package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.graphics.Color
import android.util.Log

class AyaVerseWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_verse_widget)
                val prefs = WidgetUtils.getPrefs(context)

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val isDark = WidgetUtils.getSafeBoolean(prefs, "widget_is_dark", true)
                val appName = if (isArabic) "آية" else "Aya"

                val text = WidgetUtils.getSafeString(prefs, "widget_verse_text", "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ")
                val ref = WidgetUtils.getSafeString(prefs, "widget_verse_ref", "سورة الرعد: ٢٨")

                val bgRes = if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light
                val titleColor = if (isDark) Color.parseColor("#E5C158") else Color.parseColor("#0D9488")
                val subtitleColor = if (isDark) Color.parseColor("#94A3B8") else Color.parseColor("#64748B")
                val textColor = if (isDark) Color.parseColor("#F8FAFC") else Color.parseColor("#0F172A")
                val refColor = if (isDark) Color.parseColor("#E5C158") else Color.parseColor("#0D9488")
                val dividerColor = if (isDark) Color.parseColor("#33E5C158") else Color.parseColor("#CBD5E1")

                views.setInt(R.id.widget_root, "setBackgroundResource", bgRes)
                views.setTextViewText(R.id.widget_title, if (isArabic) "آية اليوم" else "Verse of the Day")
                views.setTextColor(R.id.widget_title, titleColor)
                views.setTextViewText(R.id.widget_subtitle, appName)
                views.setTextColor(R.id.widget_subtitle, subtitleColor)
                views.setInt(R.id.widget_divider, "setBackgroundColor", dividerColor)

                views.setTextViewText(R.id.widget_verse_text, text)
                views.setTextColor(R.id.widget_verse_text, textColor)
                views.setTextViewText(R.id.widget_verse_ref, ref)
                views.setTextColor(R.id.widget_verse_ref, refColor)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaVerseWidgetProvider", "Error updating verse widget: ${e.message}", e)
            }
        }
    }
}
