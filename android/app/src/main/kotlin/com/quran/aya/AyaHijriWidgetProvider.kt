package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.util.Log

class AyaHijriWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_hijri_widget)
                val prefs = WidgetUtils.getPrefs(context)

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val hijriDate = WidgetUtils.getSafeString(prefs, "widget_hijri_date", "15 Ramadan 1447")

                views.setTextViewText(R.id.hijri_date_title, if (isArabic) "التاريخ الهجري" else "Hijri Date")
                views.setTextViewText(R.id.hijri_date_text, hijriDate)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaHijriWidgetProvider", "Error updating hijri widget: ${e.message}", e)
            }
        }
    }
}
