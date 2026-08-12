package com.quran.aya

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.util.Log

class AyaTasbihWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        try {
            if (intent.action == "com.quran.aya.INCREMENT_TASBIH") {
                val prefs = WidgetUtils.getPrefs(context)
                var count = WidgetUtils.getSafeInt(prefs, "widget_tasbih_count", 0)
                val target = WidgetUtils.getSafeInt(prefs, "widget_tasbih_target", 33)

                count++
                if (target > 0 && count > target) {
                    count = 1
                }

                prefs.edit().putInt("flutter.widget_tasbih_count", count).apply()

                val appWidgetManager = AppWidgetManager.getInstance(context)
                val componentName = ComponentName(context, AyaTasbihWidgetProvider::class.java)
                val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
                for (id in appWidgetIds) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            }
        } catch (e: Throwable) {
            Log.e("AyaTasbihWidgetProvider", "Error in onReceive: ${e.message}", e)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_tasbih_widget)
                val prefs = WidgetUtils.getPrefs(context)

                val dhikrText = WidgetUtils.getSafeString(prefs, "widget_tasbih_dhikr", "سُبْحَانَ ٱللَّٰهِ")
                val count = WidgetUtils.getSafeInt(prefs, "widget_tasbih_count", 0)
                val target = WidgetUtils.getSafeInt(prefs, "widget_tasbih_target", 33)

                views.setTextViewText(R.id.widget_tasbih_dhikr, dhikrText)
                views.setTextViewText(R.id.widget_tasbih_count, "$count / $target")

                val intent = Intent(context, AyaTasbihWidgetProvider::class.java).apply {
                    action = "com.quran.aya.INCREMENT_TASBIH"
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    0,
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaTasbihWidgetProvider", "Error updating tasbih widget: ${e.message}", e)
            }
        }
    }
}
