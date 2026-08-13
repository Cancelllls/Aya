package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.util.Log

class AyaDhikrWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_dhikr_widget)
                val prefs = WidgetUtils.getPrefs(context)

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val text = WidgetUtils.getSafeString(prefs, "widget_dhikr_text", "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ")

                views.setTextViewText(R.id.widget_title, if (isArabic) "ذكر اليوم" else "Dhikr of the Day")
                views.setTextViewText(R.id.widget_subtitle, if (isArabic) "آية" else "Aya")
                views.setTextViewText(R.id.widget_dhikr_text, text)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaDhikrWidgetProvider", "Error updating dhikr widget: ${e.message}", e)
            }
        }
    }
}
