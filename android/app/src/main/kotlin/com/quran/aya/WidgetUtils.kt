package com.quran.aya

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Color
import android.os.Build
import android.widget.RemoteViews
import org.json.JSONArray
import org.json.JSONObject
import java.util.Calendar
import java.util.TimeZone
import kotlin.math.*

data class WidgetM3Theme(
    val bgDrawable: Int,
    val primaryColor: Int,
    val textColor: Int,
    val subtitleColor: Int,
    val dividerColor: Int,
    val badgeBgDrawable: Int,
    val badgeTextColor: Int,
    val heroCardDrawable: Int,
    val heroCardTextColor: Int,
    val activePillDrawable: Int,
    val activePillTextColor: Int
)

data class UpcomingPrayerInfo(
    val name: String,
    val epochMs: Long,
    val formattedTime: String,
    val prayerKey: String = "",
    val allPrayersToday: Map<String, String> = emptyMap(),
    val isTomorrow: Boolean = false
)

object WidgetUtils {

    const val ACTION_PRAYER_AUTO_ADVANCE = "com.quran.aya.ACTION_PRAYER_AUTO_ADVANCE"

    fun updateAllWidgets(context: Context) {
        try {
            val widgetProviders = arrayOf(
                AyaWidgetProvider::class.java,
                AyaVerseWidgetProvider::class.java,
                AyaDhikrWidgetProvider::class.java,
                AyaHadithWidgetProvider::class.java,
                AyaTasbihWidgetProvider::class.java,
                AyaHijriWidgetProvider::class.java,
                AyaNextPrayerWidgetProvider::class.java,
                AyaAsmaulHusnaWidgetProvider::class.java,
                AyaCombinedWidgetProvider::class.java,
            )
            val appWidgetManager = AppWidgetManager.getInstance(context)
            for (provider in widgetProviders) {
                val intent = Intent(context, provider).apply {
                    action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                }
                val ids = appWidgetManager.getAppWidgetIds(
                    ComponentName(context, provider)
                )
                if (ids != null && ids.isNotEmpty()) {
                    intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                    context.sendBroadcast(intent)
                }
            }
        } catch (_: Throwable) {}
    }

    fun getPrefs(context: Context): SharedPreferences {
        return context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
    }

    fun getSafeString(prefs: SharedPreferences, key: String, defaultVal: String): String {
        return try {
            val keyWithPrefix = if (key.startsWith("flutter.")) key else "flutter.$key"
            prefs.getString(keyWithPrefix, defaultVal) ?: prefs.getString(key, defaultVal) ?: defaultVal
        } catch (_: Throwable) {
            defaultVal
        }
    }

    fun getSafeBoolean(prefs: SharedPreferences, key: String, defaultVal: Boolean): Boolean {
        return try {
            val keyWithPrefix = if (key.startsWith("flutter.")) key else "flutter.$key"
            if (prefs.contains(keyWithPrefix)) {
                prefs.getBoolean(keyWithPrefix, defaultVal)
            } else {
                prefs.getBoolean(key, defaultVal)
            }
        } catch (_: Throwable) {
            defaultVal
        }
    }

    fun getSafeInt(prefs: SharedPreferences, key: String, defaultVal: Int): Int {
        val keyWithPrefix = if (key.startsWith("flutter.")) key else "flutter.$key"
        val targetKey = if (prefs.contains(keyWithPrefix)) keyWithPrefix else key
        return try {
            prefs.getInt(targetKey, defaultVal)
        } catch (_: Throwable) {
            try {
                prefs.getLong(targetKey, defaultVal.toLong()).toInt()
            } catch (_: Throwable) {
                try {
                    prefs.getString(targetKey, null)?.toIntOrNull() ?: defaultVal
                } catch (_: Throwable) {
                    defaultVal
                }
            }
        }
    }

    fun getSafeLong(prefs: SharedPreferences, key: String, defaultVal: Long): Long {
        val keyWithPrefix = if (key.startsWith("flutter.")) key else "flutter.$key"
        val targetKey = if (prefs.contains(keyWithPrefix)) keyWithPrefix else key
        return try {
            prefs.getLong(targetKey, defaultVal)
        } catch (_: Throwable) {
            try {
                prefs.getInt(targetKey, defaultVal.toInt()).toLong()
            } catch (_: Throwable) {
                try {
                    prefs.getString(targetKey, null)?.toLongOrNull() ?: defaultVal
                } catch (_: Throwable) {
                    defaultVal
                }
            }
        }
    }

    fun getSafeDouble(prefs: SharedPreferences, key: String, defaultVal: Double): Double {
        val keyWithPrefix = if (key.startsWith("flutter.")) key else "flutter.$key"
        val targetKey = if (prefs.contains(keyWithPrefix)) keyWithPrefix else key
        return try {
            val rawLong = prefs.getLong(targetKey, -1L)
            if (rawLong != -1L) {
                java.lang.Double.longBitsToDouble(rawLong)
            } else {
                prefs.getFloat(targetKey, defaultVal.toFloat()).toDouble()
            }
        } catch (_: Throwable) {
            try {
                prefs.getString(targetKey, null)?.toDoubleOrNull() ?: defaultVal
            } catch (_: Throwable) {
                defaultVal
            }
        }
    }

    fun getNextUpcomingPrayer(context: Context, prefs: SharedPreferences): UpcomingPrayerInfo {
        val isArabic = getSafeBoolean(prefs, "widget_is_arabic", true)
        val nowMs = System.currentTimeMillis()

        // ── Tier 1: Multi-Day Precomputed 30-Day Schedule (Zero Drifting, Perfect Parity) ──
        val scheduleJson = getSafeString(prefs, "widget_prayer_schedule_30d", "")
        if (scheduleJson.isNotEmpty()) {
            try {
                val array = JSONArray(scheduleJson)
                for (i in 0 until array.length()) {
                    val dayObj = array.getJSONObject(i)
                    val f_ms = dayObj.optLong("f_ms", 0L)
                    val d_ms = dayObj.optLong("d_ms", 0L)
                    val a_ms = dayObj.optLong("a_ms", 0L)
                    val m_ms = dayObj.optLong("m_ms", 0L)
                    val i_ms = dayObj.optLong("i_ms", 0L)

                    val dayPrayers = listOf(
                        UpcomingPrayerInfo(if (isArabic) "الفجر" else "Fajr", f_ms, dayObj.optString("f_str", "--:--"), "fajr"),
                        UpcomingPrayerInfo(if (isArabic) "الظهر" else "Dhuhr", d_ms, dayObj.optString("d_str", "--:--"), "dhuhr"),
                        UpcomingPrayerInfo(if (isArabic) "العصر" else "Asr", a_ms, dayObj.optString("a_str", "--:--"), "asr"),
                        UpcomingPrayerInfo(if (isArabic) "المغرب" else "Maghrib", m_ms, dayObj.optString("m_str", "--:--"), "maghrib"),
                        UpcomingPrayerInfo(if (isArabic) "العشاء" else "Isha", i_ms, dayObj.optString("i_str", "--:--"), "isha")
                    )

                    // If any prayer today is in future:
                    for (item in dayPrayers) {
                        if (item.epochMs > nowMs) {
                            scheduleNextPrayerWidgetAlarm(context, item.epochMs)
                            val allTimes = mapOf(
                                "fajr" to dayObj.optString("f_str", "--:--"),
                                "dhuhr" to dayObj.optString("d_str", "--:--"),
                                "asr" to dayObj.optString("a_str", "--:--"),
                                "maghrib" to dayObj.optString("m_str", "--:--"),
                                "isha" to dayObj.optString("i_str", "--:--")
                            )
                            return item.copy(allPrayersToday = allTimes, isTomorrow = (i > 0))
                        }
                    }
                }
            } catch (_: Throwable) {}
        }

        // ── Tier 2: Stored Single-Day Epochs Fallback ──
        val fajrEpoch = getSafeLong(prefs, "widget_fajr_epoch", 0L)
        val dhuhrEpoch = getSafeLong(prefs, "widget_dhuhr_epoch", 0L)
        val asrEpoch = getSafeLong(prefs, "widget_asr_epoch", 0L)
        val maghribEpoch = getSafeLong(prefs, "widget_maghrib_epoch", 0L)
        val ishaEpoch = getSafeLong(prefs, "widget_isha_epoch", 0L)

        val fajrTime = getSafeString(prefs, "widget_prayer_fajr", "--:--")
        val dhuhrTime = getSafeString(prefs, "widget_prayer_dhuhr", "--:--")
        val asrTime = getSafeString(prefs, "widget_prayer_asr", "--:--")
        val maghribTime = getSafeString(prefs, "widget_prayer_maghrib", "--:--")
        val ishaTime = getSafeString(prefs, "widget_prayer_isha", "--:--")

        val list = listOf(
            UpcomingPrayerInfo(if (isArabic) "الفجر" else "Fajr", fajrEpoch, fajrTime, "fajr"),
            UpcomingPrayerInfo(if (isArabic) "الظهر" else "Dhuhr", dhuhrEpoch, dhuhrTime, "dhuhr"),
            UpcomingPrayerInfo(if (isArabic) "العصر" else "Asr", asrEpoch, asrTime, "asr"),
            UpcomingPrayerInfo(if (isArabic) "المغرب" else "Maghrib", maghribEpoch, maghribTime, "maghrib"),
            UpcomingPrayerInfo(if (isArabic) "العشاء" else "Isha", ishaEpoch, ishaTime, "isha")
        )

        for (item in list) {
            if (item.epochMs > nowMs) {
                scheduleNextPrayerWidgetAlarm(context, item.epochMs)
                return item.copy(allPrayersToday = mapOf(
                    "fajr" to fajrTime, "dhuhr" to dhuhrTime, "asr" to asrTime, "maghrib" to maghribTime, "isha" to ishaTime
                ))
            }
        }

        // ── Tier 3: Native Offline Solar Astronomical Engine (Runs Forever Without App Open) ──
        try {
            val astroResult = calculateAstronomicalUpcomingPrayer(context, prefs, isArabic, nowMs)
            if (astroResult != null && astroResult.epochMs > nowMs) {
                scheduleNextPrayerWidgetAlarm(context, astroResult.epochMs)
                return astroResult
            }
        } catch (_: Throwable) {}

        // ── Tier 4: Graceful Absolute Fallback ──
        val fallbackName = getSafeString(prefs, "widget_next_prayer_name", if (isArabic) "الفجر" else "Fajr")
        val fallbackEpoch = getSafeLong(prefs, "widget_next_prayer_epoch", 0L)
        val fallbackTime = getSafeString(prefs, "widget_widget_next_display", "--:--")
        val effectiveFallbackEpoch = if (fallbackEpoch > nowMs) fallbackEpoch else 0L

        if (effectiveFallbackEpoch > nowMs) {
            scheduleNextPrayerWidgetAlarm(context, effectiveFallbackEpoch)
        }

        return UpcomingPrayerInfo(fallbackName, effectiveFallbackEpoch, fallbackTime, "fajr")
    }

    fun scheduleNextPrayerWidgetAlarm(context: Context, nextEpochMs: Long) {
        if (nextEpochMs <= System.currentTimeMillis()) return
        try {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as? android.app.AlarmManager ?: return
            val appWidgetManager = AppWidgetManager.getInstance(context)

            val providers = arrayOf(
                AyaNextPrayerWidgetProvider::class.java,
                AyaCombinedWidgetProvider::class.java,
                AyaWidgetProvider::class.java
            )

            for (provider in providers) {
                val ids = appWidgetManager.getAppWidgetIds(ComponentName(context, provider))
                if (ids == null || ids.isEmpty()) continue

                val intent = Intent(context, provider).apply {
                    action = ACTION_PRAYER_AUTO_ADVANCE
                    putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                }
                val pendingIntent = PendingIntent.getBroadcast(
                    context,
                    provider.name.hashCode(),
                    intent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, nextEpochMs + 200L, pendingIntent)
                } else {
                    alarmManager.setExact(android.app.AlarmManager.RTC_WAKEUP, nextEpochMs + 200L, pendingIntent)
                }
            }
        } catch (_: Throwable) {}
    }

    fun getM3Theme(context: Context, prefs: SharedPreferences): WidgetM3Theme {
        val preset = getSafeString(prefs, "theme_preset", "adaptive")
        val isDark = getSafeBoolean(prefs, "widget_is_dark", true)

        // Android 12+ Dynamic System Material You Colors
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && (preset == "adaptive" || preset == "system" || preset == "monet" || preset.contains("monet"))) {
            try {
                val primary = context.getColor(android.R.color.system_accent1_500)
                val textColor = if (isDark) context.getColor(android.R.color.system_neutral1_100) else context.getColor(android.R.color.system_neutral1_900)
                val subtitleColor = if (isDark) context.getColor(android.R.color.system_neutral2_400) else context.getColor(android.R.color.system_neutral2_700)
                val dividerColor = if (isDark) Color.parseColor("#33FFFFFF") else Color.parseColor("#1F000000")

                return WidgetM3Theme(
                    bgDrawable = if (isDark) R.drawable.widget_background_dark else R.drawable.widget_background_light,
                    primaryColor = primary,
                    textColor = textColor,
                    subtitleColor = subtitleColor,
                    dividerColor = dividerColor,
                    badgeBgDrawable = if (isDark) R.drawable.active_prayer_background else R.drawable.active_prayer_background_light,
                    badgeTextColor = if (isDark) Color.BLACK else Color.WHITE,
                    heroCardDrawable = if (isDark) R.drawable.widget_hero_card_dark else R.drawable.widget_hero_card_light,
                    heroCardTextColor = primary,
                    activePillDrawable = if (isDark) R.drawable.widget_active_pill_dark else R.drawable.widget_active_pill_light,
                    activePillTextColor = primary
                )
            } catch (_: Throwable) {}
        }

        return when (preset) {
            "light", "white_monet" -> WidgetM3Theme(
                bgDrawable = R.drawable.widget_background_light,
                primaryColor = Color.parseColor("#0D9488"), // M3 Teal
                textColor = Color.parseColor("#0F172A"),
                subtitleColor = Color.parseColor("#64748B"),
                dividerColor = Color.parseColor("#E2E8F0"),
                badgeBgDrawable = R.drawable.active_prayer_background_light,
                badgeTextColor = Color.WHITE,
                heroCardDrawable = R.drawable.widget_hero_card_light,
                heroCardTextColor = Color.parseColor("#0D9488"),
                activePillDrawable = R.drawable.widget_active_pill_light,
                activePillTextColor = Color.parseColor("#0D9488")
            )
            "sepia" -> WidgetM3Theme(
                bgDrawable = R.drawable.widget_background_sepia,
                primaryColor = Color.parseColor("#8C5A2B"), // M3 Sepia Warm
                textColor = Color.parseColor("#4A3B2C"),
                subtitleColor = Color.parseColor("#7A6451"),
                dividerColor = Color.parseColor("#E5DABF"),
                badgeBgDrawable = R.drawable.active_prayer_background_sepia,
                badgeTextColor = Color.WHITE,
                heroCardDrawable = R.drawable.widget_hero_card_sepia,
                heroCardTextColor = Color.parseColor("#8C5A2B"),
                activePillDrawable = R.drawable.widget_active_pill_sepia,
                activePillTextColor = Color.parseColor("#8C5A2B")
            )
            "black" -> WidgetM3Theme(
                bgDrawable = R.drawable.widget_background_black,
                primaryColor = Color.parseColor("#E5C158"), // M3 Gold
                textColor = Color.parseColor("#E5E5E5"),
                subtitleColor = Color.parseColor("#A3A3A3"),
                dividerColor = Color.parseColor("#262626"),
                badgeBgDrawable = R.drawable.active_prayer_background,
                badgeTextColor = Color.BLACK,
                heroCardDrawable = R.drawable.widget_hero_card_dark,
                heroCardTextColor = Color.parseColor("#E5C158"),
                activePillDrawable = R.drawable.widget_active_pill_dark,
                activePillTextColor = Color.parseColor("#E5C158")
            )
            "dark", "dark_monet" -> WidgetM3Theme(
                bgDrawable = R.drawable.widget_background_dark,
                primaryColor = Color.parseColor("#E5C158"),
                textColor = Color.parseColor("#F8FAFC"),
                subtitleColor = Color.parseColor("#8E9E96"),
                dividerColor = Color.parseColor("#26E5C158"),
                badgeBgDrawable = R.drawable.active_prayer_background,
                badgeTextColor = Color.BLACK,
                heroCardDrawable = R.drawable.widget_hero_card_dark,
                heroCardTextColor = Color.parseColor("#E5C158"),
                activePillDrawable = R.drawable.widget_active_pill_dark,
                activePillTextColor = Color.parseColor("#E5C158")
            )
            else -> if (isDark) {
                WidgetM3Theme(
                    bgDrawable = R.drawable.widget_background_dark,
                    primaryColor = Color.parseColor("#E5C158"),
                    textColor = Color.parseColor("#F8FAFC"),
                    subtitleColor = Color.parseColor("#8E9E96"),
                    dividerColor = Color.parseColor("#26E5C158"),
                    badgeBgDrawable = R.drawable.active_prayer_background,
                    badgeTextColor = Color.BLACK,
                    heroCardDrawable = R.drawable.widget_hero_card_dark,
                    heroCardTextColor = Color.parseColor("#E5C158"),
                    activePillDrawable = R.drawable.widget_active_pill_dark,
                    activePillTextColor = Color.parseColor("#E5C158")
                )
            } else {
                WidgetM3Theme(
                    bgDrawable = R.drawable.widget_background_light,
                    primaryColor = Color.parseColor("#0D9488"),
                    textColor = Color.parseColor("#0F172A"),
                    subtitleColor = Color.parseColor("#64748B"),
                    dividerColor = Color.parseColor("#E2E8F0"),
                    badgeBgDrawable = R.drawable.active_prayer_background_light,
                    badgeTextColor = Color.WHITE,
                    heroCardDrawable = R.drawable.widget_hero_card_light,
                    heroCardTextColor = Color.parseColor("#0D9488"),
                    activePillDrawable = R.drawable.widget_active_pill_light,
                    activePillTextColor = Color.parseColor("#0D9488")
                )
            }
        }
    }

    fun attachLaunchAppPendingIntent(context: Context, views: RemoteViews, viewId: Int) {
        try {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(viewId, pendingIntent)
        } catch (_: Throwable) {}
    }

    // ── Native Astronomical Prayer Calculation Engine ───────────────────────

    private fun calculateAstronomicalUpcomingPrayer(
        context: Context,
        prefs: SharedPreferences,
        isArabic: Boolean,
        nowMs: Long
    ): UpcomingPrayerInfo? {
        var lat = getSafeDouble(prefs, "widget_user_latitude", 0.0)
        var lng = getSafeDouble(prefs, "widget_user_longitude", 0.0)
        if (lat == 0.0 && lng == 0.0) {
            val rawLoc = getSafeString(prefs, "user_location", "")
            if (rawLoc.isNotEmpty()) {
                try {
                    val obj = JSONObject(rawLoc)
                    lat = obj.optDouble("latitude", 30.0444)
                    lng = obj.optDouble("longitude", 31.2357)
                } catch (_: Throwable) {
                    lat = 30.0444
                    lng = 31.2357
                }
            } else {
                lat = 30.0444
                lng = 31.2357
            }
        }

        val method = getSafeInt(prefs, "widget_calc_method", 5)
        val madhab = getSafeInt(prefs, "widget_asr_method", 0)
        val use24h = getSafeBoolean(prefs, "widget_time_format_24h", false)

        val cal = Calendar.getInstance()
        val todayPrayers = computeSolarPrayersForDay(cal, lat, lng, method, madhab, use24h, isArabic)

        // Check if any prayer today is upcoming
        for (item in todayPrayers.values) {
            if (item.epochMs > nowMs) {
                val allTimes = todayPrayers.mapValues { it.value.formattedTime }
                return item.copy(allPrayersToday = allTimes, isTomorrow = false)
            }
        }

        // All today passed, compute tomorrow
        cal.add(Calendar.DAY_OF_YEAR, 1)
        val tomorrowPrayers = computeSolarPrayersForDay(cal, lat, lng, method, madhab, use24h, isArabic)
        val tomorrowFajr = tomorrowPrayers["fajr"]
        if (tomorrowFajr != null) {
            val allTimes = tomorrowPrayers.mapValues { it.value.formattedTime }
            return tomorrowFajr.copy(allPrayersToday = allTimes, isTomorrow = true)
        }

        return null
    }

    private fun computeSolarPrayersForDay(
        cal: Calendar,
        lat: Double,
        lng: Double,
        method: Int,
        madhab: Int,
        use24h: Boolean,
        isArabic: Boolean
    ): Map<String, UpcomingPrayerInfo> {
        val y = cal.get(Calendar.YEAR)
        val m = cal.get(Calendar.MONTH) + 1
        val d = cal.get(Calendar.DAY_OF_MONTH)

        val tzOffsetHours = cal.timeZone.getOffset(cal.timeInMillis) / 3600000.0

        // Julian Day
        var jy = y
        var jm = m
        if (jm <= 2) {
            jy -= 1
            jm += 12
        }
        val ja = floor(jy / 100.0)
        val jb = 2 - ja + floor(ja / 4.0)
        val jd = floor(365.25 * (jy + 4716)) + floor(30.6001 * (jm + 1)) + d + jb - 1524.5

        val dJ2000 = jd - 2451545.0
        val M = Math.toRadians((357.529 + 0.98560028 * dJ2000) % 360)
        val L0 = (280.459 + 0.98564736 * dJ2000) % 360
        val lambda = Math.toRadians((L0 + 1.915 * sin(M) + 0.020 * sin(2 * M)) % 360)
        val eps = Math.toRadians(23.439 - 0.00000036 * dJ2000)

        val alpha = Math.toDegrees(atan2(cos(eps) * sin(lambda), cos(lambda))) % 360
        val delta = asin(sin(eps) * sin(lambda))

        var eot = (L0 - alpha) / 15.0
        while (eot > 12) eot -= 24
        while (eot < -12) eot += 24

        val dhuhrHours = 12.0 + tzOffsetHours - (lng / 15.0) - eot

        val latRad = Math.toRadians(lat)

        fun hourAngle(angle: Double): Double {
            val cosH = (sin(Math.toRadians(-angle)) - sin(latRad) * sin(delta)) / (cos(latRad) * cos(delta))
            if (cosH > 1.0 || cosH < -1.0) return 0.0
            return Math.toDegrees(acos(cosH)) / 15.0
        }

        // Method angles
        val (fajrAngle, ishaAngle, ishaFixedMinutes) = when (method) {
            1 -> Triple(18.0, 18.0, 0) // Karachi
            2 -> Triple(15.0, 15.0, 0) // North America (ISNA)
            3 -> Triple(18.0, 17.0, 0) // MWL
            4 -> Triple(18.5, 0.0, 90) // Umm Al-Qura (90 min)
            5 -> Triple(19.5, 17.5, 0) // Egyptian
            7 -> Triple(17.7, 14.0, 0) // Tehran
            8 -> Triple(18.2, 18.2, 0) // Gulf / Dubai
            9 -> Triple(18.0, 17.5, 0) // Kuwait
            10 -> Triple(18.0, 0.0, 90) // Qatar
            else -> Triple(18.0, 17.0, 0)
        }

        val fajrHours = dhuhrHours - hourAngle(fajrAngle)
        val sunsetHours = dhuhrHours + hourAngle(0.833)
        val maghribHours = sunsetHours

        val ishaHours = if (ishaFixedMinutes > 0) {
            maghribHours + (ishaFixedMinutes / 60.0)
        } else {
            dhuhrHours + hourAngle(ishaAngle)
        }

        // Asr (Shafi n=1, Hanafi n=2)
        val n = if (madhab == 1) 2.0 else 1.0
        val asrAlt = atan(1.0 / (n + tan(abs(latRad - delta))))
        val cosAsr = (sin(asrAlt) - sin(latRad) * sin(delta)) / (cos(latRad) * cos(delta))
        val asrHA = if (cosAsr in -1.0..1.0) Math.toDegrees(acos(cosAsr)) / 15.0 else 0.0
        val asrHours = dhuhrHours + asrHA

        fun toEpoch(hoursFraction: Double): Long {
            var h = hoursFraction
            while (h < 0) h += 24
            while (h >= 24) h -= 24
            val ih = h.toInt()
            val remMin = (h - ih) * 60
            val im = round(remMin).toInt()
            val c = Calendar.getInstance(cal.timeZone).apply {
                timeInMillis = cal.timeInMillis
                set(Calendar.HOUR_OF_DAY, ih)
                set(Calendar.MINUTE, im)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            return c.timeInMillis
        }

        fun formatTime(epoch: Long): String {
            val c = Calendar.getInstance(cal.timeZone).apply { timeInMillis = epoch }
            val hour = c.get(Calendar.HOUR_OF_DAY)
            val minute = c.get(Calendar.MINUTE).toString().padStart(2, '0')
            if (use24h) {
                return "${hour.toString().padStart(2, '0')}:$minute"
            }
            val isPm = hour >= 12
            val displayHour = if (hour % 12 == 0) 12 else hour % 12
            val suffix = if (isPm) (if (isArabic) "م" else "PM") else (if (isArabic) "ص" else "AM")
            return "$displayHour:$minute $suffix"
        }

        val fEpoch = toEpoch(fajrHours)
        val dEpoch = toEpoch(dhuhrHours)
        val aEpoch = toEpoch(asrHours)
        val mEpoch = toEpoch(maghribHours)
        val iEpoch = toEpoch(ishaHours)

        return mapOf(
            "fajr" to UpcomingPrayerInfo(if (isArabic) "الفجر" else "Fajr", fEpoch, formatTime(fEpoch), "fajr"),
            "dhuhr" to UpcomingPrayerInfo(if (isArabic) "الظهر" else "Dhuhr", dEpoch, formatTime(dEpoch), "dhuhr"),
            "asr" to UpcomingPrayerInfo(if (isArabic) "العصر" else "Asr", aEpoch, formatTime(aEpoch), "asr"),
            "maghrib" to UpcomingPrayerInfo(if (isArabic) "المغرب" else "Maghrib", mEpoch, formatTime(mEpoch), "maghrib"),
            "isha" to UpcomingPrayerInfo(if (isArabic) "العشاء" else "Isha", iEpoch, formatTime(iEpoch), "isha")
        )
    }
}
