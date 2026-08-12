package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
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
                val appName = if (isArabic) "آية" else "Aya"

                val text = WidgetUtils.getSafeString(prefs, "widget_verse_text", "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ")
                val ref = WidgetUtils.getSafeString(prefs, "widget_verse_ref", "سورة الرعد: ٢٨")

                views.setTextViewText(R.id.widget_title, if (isArabic) "آية اليوم" else "Verse of the Day")
                views.setTextViewText(R.id.widget_subtitle, appName)
                views.setTextViewText(R.id.widget_verse_text, text)
                views.setTextViewText(R.id.widget_verse_ref, ref)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaVerseWidgetProvider", "Error updating verse widget: ${e.message}", e)
            }
        }
    }
}
