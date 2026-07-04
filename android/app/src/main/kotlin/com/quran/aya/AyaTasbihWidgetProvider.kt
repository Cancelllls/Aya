package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class AyaTasbihWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action == "com.quran.aya.INCREMENT_TASBIH") {
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            var count = prefs.getInt("flutter.widget_tasbih_count", 0)
            val target = prefs.getInt("flutter.widget_tasbih_target", 33)
            
            count++
            if (count > target) count = 0 // Reset or loop? Let's just increment or reset. Wait, let's just increment.
            
            // Just increment for now, or reset if it hits target. Let's do reset if it exceeds target.
            if (count > target && target > 0) count = 1
            
            prefs.edit().putInt("flutter.widget_tasbih_count", count).apply()

            val appWidgetManager = AppWidgetManager.getInstance(context)
            val componentName = android.content.ComponentName(context, AyaTasbihWidgetProvider::class.java)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(componentName)
            for (id in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, id)
            }
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.aya_tasbih_widget)

            // Read from SharedPreferences saved by Flutter
            val prefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val isArabic = prefs.getBoolean("flutter.widget_is_arabic", true)
            val appName = if (isArabic) "آية" else "Aya"
            
            // Get Tasbih details
            val dhikrText = prefs.getString("flutter.widget_tasbih_dhikr", "سُبْحَانَ ٱللَّٰهِ") 
                ?: "سُبْحَانَ ٱللَّٰهِ"
            val count = prefs.getInt("flutter.widget_tasbih_count", 0)
            val target = prefs.getInt("flutter.widget_tasbih_target", 33)

            // Update text values
            views.setTextViewText(R.id.widget_tasbih_dhikr, dhikrText)
            views.setTextViewText(R.id.widget_tasbih_count, "$count / $target")

            // Add click listener to the entire widget to increment
            val intent = android.content.Intent(context, AyaTasbihWidgetProvider::class.java)
            intent.action = "com.quran.aya.INCREMENT_TASBIH"
            val pendingIntent = android.app.PendingIntent.getBroadcast(
                context, 0, intent,
                android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            // Update app widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
