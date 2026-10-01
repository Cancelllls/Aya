package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import android.util.Log

class AyaNextPrayerWidgetProvider : AppWidgetProvider() {

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        val action = intent.action ?: return
        if (action == WidgetUtils.ACTION_PRAYER_AUTO_ADVANCE ||
            action == AppWidgetManager.ACTION_APPWIDGET_UPDATE ||
            action == Intent.ACTION_BOOT_COMPLETED ||
            action == Intent.ACTION_TIME_SET ||
            action == Intent.ACTION_TIMEZONE_CHANGED) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, AyaNextPrayerWidgetProvider::class.java))
            if (ids != null && ids.isNotEmpty()) {
                for (id in ids) {
                    updateAppWidget(context, appWidgetManager, id)
                }
            }
        }
    }

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            try {
                val views = RemoteViews(context.packageName, R.layout.aya_next_prayer_widget)
                val prefs = WidgetUtils.getPrefs(context)
                val m3Theme = WidgetUtils.getM3Theme(context, prefs)

                val isArabic = WidgetUtils.getSafeBoolean(prefs, "widget_is_arabic", true)
                val upcoming = WidgetUtils.getNextUpcomingPrayer(context, prefs)
                val nowMs = System.currentTimeMillis()

                views.setInt(R.id.widget_root, "setBackgroundResource", m3Theme.bgDrawable)
                views.setInt(R.id.next_prayer_box, "setBackgroundResource", m3Theme.heroCardDrawable)

                views.setTextViewText(R.id.next_prayer_title, if (isArabic) "الصلاة القادمة" else "Next Prayer")
                views.setTextColor(R.id.next_prayer_title, m3Theme.primaryColor)

                val prayerDisplayName = if (upcoming.formattedTime.isNotEmpty() && upcoming.formattedTime != "--:--") {
                    "${upcoming.name} (${upcoming.formattedTime})"
                } else {
                    upcoming.name
                }
                views.setTextViewText(R.id.next_prayer_name, prayerDisplayName)
                views.setTextColor(R.id.next_prayer_name, m3Theme.textColor)

                views.setTextViewText(R.id.next_prayer_subtitle, if (isArabic) "الوقت المتبقي" else "Time Remaining")
                views.setTextColor(R.id.next_prayer_subtitle, m3Theme.subtitleColor)

                if (upcoming.epochMs > nowMs) {
                    val durationMs = upcoming.epochMs - nowMs
                    val targetElapsedRealtime = android.os.SystemClock.elapsedRealtime() + durationMs
                    views.setChronometer(R.id.next_prayer_chronometer, targetElapsedRealtime, null, true)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.next_prayer_chronometer, true)
                    }
                    views.setTextColor(R.id.next_prayer_chronometer, m3Theme.heroCardTextColor)
                    views.setViewVisibility(R.id.next_prayer_chronometer, View.VISIBLE)
                    views.setViewVisibility(R.id.next_prayer_time, View.GONE)
                } else {
                    // STOP chronometer cleanly so it NEVER displays negative numbers (-00:01)!
                    views.setChronometer(R.id.next_prayer_chronometer, android.os.SystemClock.elapsedRealtime(), null, false)
                    views.setViewVisibility(R.id.next_prayer_chronometer, View.GONE)
                    views.setViewVisibility(R.id.next_prayer_time, View.VISIBLE)
                    views.setTextViewText(R.id.next_prayer_time, upcoming.formattedTime.ifEmpty { "--:--" })
                    views.setTextColor(R.id.next_prayer_time, m3Theme.heroCardTextColor)
                }

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaNextPrayerWidgetProvider", "Error updating next prayer widget: ${e.message}", e)
            }
        }
    }
}
