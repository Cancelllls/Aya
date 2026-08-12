package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews
import android.util.Log

class AyaHadithWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_hadith_widget)
                val prefs = WidgetUtils.getPrefs(context)

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val text = WidgetUtils.getSafeString(prefs, "widget_hadith_text", "إنما الأعمال بالنيات وإنما لكل امرئ ما نوى")
                val ref = WidgetUtils.getSafeString(prefs, "widget_hadith_ref", "رواه البخاري ومسلم")

                views.setTextViewText(R.id.widget_hadith_text, text)
                views.setTextViewText(R.id.widget_hadith_ref, ref)

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaHadithWidgetProvider", "Error updating hadith widget: ${e.message}", e)
            }
        }
    }
}
