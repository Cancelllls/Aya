package com.quran.aya

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Build
import android.view.View
import android.widget.RemoteViews
import android.util.Log

class AyaNextPrayerWidgetProvider : AppWidgetProvider() {

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
                views.setInt(R.id.next_prayer_box, "setBackgroundResource", m3Theme.badgeBgDrawable)

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
                views.setTextColor(R.id.next_prayer_subtitle, m3Theme.badgeTextColor)

                if (upcoming.epochMs > nowMs) {
                    val durationMs = upcoming.epochMs - nowMs
                    val targetElapsedRealtime = android.os.SystemClock.elapsedRealtime() + durationMs
                    views.setChronometer(R.id.next_prayer_chronometer, targetElapsedRealtime, null, true)
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                        views.setChronometerCountDown(R.id.next_prayer_chronometer, true)
                    }
                    views.setTextColor(R.id.next_prayer_chronometer, m3Theme.badgeTextColor)
                    views.setViewVisibility(R.id.next_prayer_chronometer, View.VISIBLE)
                    views.setViewVisibility(R.id.next_prayer_time, View.GONE)
                } else {
                    // STOP chronometer cleanly so it NEVER displays negative numbers (-00:01)!
                    views.setChronometer(R.id.next_prayer_chronometer, android.os.SystemClock.elapsedRealtime(), null, false)
                    views.setViewVisibility(R.id.next_prayer_chronometer, View.GONE)
                    views.setViewVisibility(R.id.next_prayer_time, View.VISIBLE)
                    views.setTextViewText(R.id.next_prayer_time, upcoming.formattedTime.ifEmpty { "--:--" })
                    views.setTextColor(R.id.next_prayer_time, m3Theme.badgeTextColor)
                }

                WidgetUtils.attachLaunchAppPendingIntent(context, views, R.id.widget_root)

                appWidgetManager.updateAppWidget(appWidgetId, views)
            } catch (e: Throwable) {
                Log.e("AyaNextPrayerWidgetProvider", "Error updating next prayer widget: ${e.message}", e)
            }
        }
    }
}
