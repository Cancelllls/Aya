package com.quran.aya

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.graphics.Color
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

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val isDark = WidgetUtils.getSafeBoolean(prefs, "widget_is_dark", true)
                val dhikrText = WidgetUtils.getSafeString(prefs, "widget_tasbih_dhikr", "سُبْحَانَ ٱللَّٰهِ")
                val count = WidgetUtils.getSafeInt(prefs, "widget_tasbih_count", 0)
                val target = WidgetUtils.getSafeInt(prefs, "widget_tasbih_target", 33)

                val bgRes = if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light
                val titleColor = if (isDark) Color.parseColor("#E5C158") else Color.parseColor("#0D9488")
                val subtitleColor = if (isDark) Color.parseColor("#94A3B8") else Color.parseColor("#64748B")
                val textColor = if (isDark) Color.parseColor("#F8FAFC") else Color.parseColor("#0F172A")
                val dividerColor = if (isDark) Color.parseColor("#33E5C158") else Color.parseColor("#CBD5E1")

                val badgeBg = if (isDark) R.drawable.active_prayer_background else R.drawable.active_prayer_background_light
                val badgeTextColor = if (isDark) Color.BLACK else Color.WHITE

                views.setInt(R.id.widget_root, "setBackgroundResource", bgRes)
                views.setTextViewText(R.id.widget_title, if (isArabic) "السبحة الإلكترونية" else "Tasbih Counter")
                views.setTextColor(R.id.widget_title, titleColor)
                views.setTextViewText(R.id.widget_subtitle, if (isArabic) "آية" else "Aya")
                views.setTextColor(R.id.widget_subtitle, subtitleColor)
                views.setInt(R.id.widget_divider, "setBackgroundColor", dividerColor)

                views.setTextViewText(R.id.widget_tasbih_dhikr, dhikrText)
                views.setTextColor(R.id.widget_tasbih_dhikr, textColor)

                views.setTextViewText(R.id.widget_tasbih_count, "$count / $target")
                views.setTextColor(R.id.widget_tasbih_count, badgeTextColor)
                views.setInt(R.id.widget_tasbih_count_container, "setBackgroundResource", badgeBg)

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
