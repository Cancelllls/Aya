package com.quran.aya

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.app.AlarmManager
import android.view.WindowManager
import android.provider.Settings
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.os.Vibrator
import android.os.VibrationEffect
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import android.app.PendingIntent

class MainActivity : FlutterActivity() {
    companion object {
        const val PICK_FILE_REQUEST = 9001
    }

    private val CHANNEL = "com.quran.aya/system"
    private var pendingFileResult: Result? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        // Natively support up to 144Hz screens
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.decorView.post {
                try {
                    val display = window.context.display
                    if (display != null) {
                        val modes = display.supportedModes
                        val highestMode = modes.maxByOrNull { it.refreshRate }
                        if (highestMode != null) {
                            val params = window.attributes
                            params.preferredDisplayModeId = highestMode.modeId
                            window.attributes = params
                        }
                    }
                } catch (_: Exception) {}
            }
        } else {
            try {
                val params = window.attributes
                params.preferredRefreshRate = 144f
                window.attributes = params
            } catch (_: Exception) {}
        }
    }

    @Suppress("DEPRECATION")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == PICK_FILE_REQUEST) {
            val uri = data?.data
            if (uri != null && resultCode == android.app.Activity.RESULT_OK) {
                try {
                    val input = contentResolver.openInputStream(uri)
                    val tmpFile = java.io.File(cacheDir, "import_backup.json")
                    input?.use { it.copyTo(tmpFile.outputStream()) }
                    pendingFileResult?.success(tmpFile.absolutePath)
                } catch (e: Exception) {
                    pendingFileResult?.success(null)
                }
            } else {
                pendingFileResult?.success(null)
            }
            pendingFileResult = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val mc = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        val adhanChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.adhan.app/alarm")

        adhanChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "scheduleExactAlarm" -> {
                    val timestamp = call.argument<Long>("timestamp")
                    val id = call.argument<Int>("id")
                    if (timestamp != null && id != null) {
                        scheduleExactAlarm(
                            timestamp = timestamp,
                            id = id,
                            mp3ResName = call.argument<String>("mp3ResName") ?: "",
                            prayerName = call.argument<String>("prayerName") ?: "Prayer",
                            enableVibration = call.argument<Boolean>("enableVibration") ?: true,
                        )
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing timestamp or id", null)
                    }
                }
                "schedulePreAdhanAlarm" -> {
                    val timestamp = call.argument<Long>("timestamp")
                    val id = call.argument<Int>("id")
                    val prayerName = call.argument<String>("prayerName") ?: "Prayer"
                    val minutesBefore = call.argument<Int>("minutesBefore") ?: 10
                    val alertMode = call.argument<String>("alertMode") ?: "vibrate"
                    if (timestamp != null && id != null) {
                        schedulePreAdhanAlarm(
                            timestamp = timestamp,
                            id = id,
                            prayerName = prayerName,
                            minutesBefore = minutesBefore,
                            alertMode = alertMode,
                        )
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing timestamp or id", null)
                    }
                }
                "cancelAlarm" -> {
                    val id = call.argument<Int>("id")
                    if (id != null) {
                        cancelAlarm(id)
                        result.success(true)
                    } else {
                        result.error("INVALID_ARGS", "Missing id", null)
                    }
                }
                "cancelAllAlarms" -> {
                    cancelAllAlarms()
                    result.success(true)
                }
                "getScheduledAlarms" -> {
                    result.success(getScheduledAlarms())
                }
                "openOemAutoStartSettings" -> {
                    openOemAutoStartSettings()
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        mc.setMethodCallHandler { call, result ->
            when (call.method) {
                "getAndroidSdkVersion" -> {
                    result.success(Build.VERSION.SDK_INT)
                }
                "checkExactAlarmPermission" -> {
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        alarmManager.canScheduleExactAlarms()
                    } else {
                        true
                    }
                    result.success(granted)
                }
                "requestExactAlarmPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        runOnUiThread {
                            var started = false
                            try {
                                val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                    data = Uri.fromParts("package", packageName, null)
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                started = true
                            } catch (e: Exception) {
                                try {
                                    val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(intent)
                                    started = true
                                } catch (_: Exception) {}
                            }
                            if (!started) {
                                try {
                                    val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                                        data = Uri.fromParts("package", packageName, null)
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(intent)
                                } catch (_: Exception) {}
                            }
                        }
                        result.success(true)
                    } else {
                        result.success(true)
                    }
                }
                "checkBatteryOptimization" -> {
                    val ignored = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val powerManager = getSystemService(Context.POWER_SERVICE) as PowerManager
                        powerManager.isIgnoringBatteryOptimizations(packageName)
                    } else {
                        true
                    }
                    result.success(ignored)
                }
                "requestDisableBatteryOptimization" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                data = Uri.parse("package:$packageName")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            try {
                                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                result.success(true)
                            } catch (ex: Exception) {
                                result.error("ERROR", ex.message, null)
                            }
                        }
                    } else {
                        result.success(true)
                    }
                }
                "setKeepScreenOn" -> {
                    val enabled = call.argument<Boolean>("enabled") ?: false
                    if (enabled) {
                        activity.window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    } else {
                        activity.window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
                    }
                    result.success(true)
                }
                "startLockTask" -> {
                    try {
                        startLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "stopLockTask" -> {
                    try {
                        stopLockTask()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "vibrate" -> {
                    val patternList = call.argument<List<Int>>("pattern")
                    val pattern = patternList?.map { it.toLong() }?.toLongArray() ?: longArrayOf(0, 500, 300, 500)
                    val amplitudesList = call.argument<List<Int>>("amplitudes")
                    val amplitudes = amplitudesList?.map { it }?.toIntArray()
                    val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    if (vibrator.hasVibrator()) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            if (amplitudes != null && amplitudes.size == pattern.size) {
                                vibrator.vibrate(VibrationEffect.createWaveform(pattern, amplitudes, -1))
                            } else {
                                vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
                            }
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(pattern, -1)
                        }
                    }
                    result.success(true)
                }
                "updateWidget" -> {
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
                            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
                            context.sendBroadcast(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "pickFile" -> {
                    pendingFileResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "application/json"
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("application/json", "*/*"))
                    }
                    startActivityForResult(intent, PICK_FILE_REQUEST)
                }
                "stopAdhan" -> {
                    AdhanBroadcastReceiver.activeStop?.invoke()
                    result.success(true)
                }
                "getTimeZoneName" -> {
                    result.success(java.util.TimeZone.getDefault().id)
                }
                "checkNotificationPolicyAccess" -> {
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                    val granted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        nm.isNotificationPolicyAccessGranted
                    } else {
                        true
                    }
                    result.success(granted)
                }
                "requestNotificationPolicyAccess" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        try {
                            val intent = Intent(Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                        } catch (_: Exception) {}
                    }
                    result.success(true)
                }
                "setDoNotDisturbMode" -> {
                    val enable = call.argument<Boolean>("enabled") ?: false
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                        val nm = getSystemService(Context.NOTIFICATION_SERVICE) as android.app.NotificationManager
                        if (nm.isNotificationPolicyAccessGranted) {
                            val filter = if (enable) android.app.NotificationManager.INTERRUPTION_FILTER_PRIORITY else android.app.NotificationManager.INTERRUPTION_FILTER_ALL
                            nm.setInterruptionFilter(filter)
                        }
                    }
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun scheduleExactAlarm(
        timestamp: Long,
        id: Int,
        mp3ResName: String,
        prayerName: String,
        enableVibration: Boolean,
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, AdhanBroadcastReceiver::class.java).apply {
            putExtra("ALARM_ID", id)
            putExtra("MP3_RES_NAME", mp3ResName)
            putExtra("PRAYER_NAME", prayerName)
            putExtra("ENABLE_VIBRATION", enableVibration)
            putExtra("SCHEDULED_TIMESTAMP", timestamp)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        saveAlarmInfo(id, timestamp, mp3ResName, prayerName, enableVibration, isPreAdhan = false)

        val showIntent = PendingIntent.getActivity(
            this,
            id + 50000,
            Intent(android.provider.AlarmClock.ACTION_SHOW_ALARMS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val clockInfo = AlarmManager.AlarmClockInfo(timestamp, showIntent)
                alarmManager.setAlarmClock(clockInfo, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, timestamp, pendingIntent)
            }
        } catch (e: SecurityException) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP, timestamp, pendingIntent
            )
        }
    }

    private fun schedulePreAdhanAlarm(
        timestamp: Long,
        id: Int,
        prayerName: String,
        minutesBefore: Int,
        alertMode: String,
    ) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = Intent(this, PreAdhanBroadcastReceiver::class.java).apply {
            putExtra("ALARM_ID", id)
            putExtra("PRAYER_NAME", prayerName)
            putExtra("MINUTES_BEFORE", minutesBefore)
            putExtra("ALERT_MODE", alertMode)
            putExtra("SCHEDULED_TIMESTAMP", timestamp)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            this, id, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        saveAlarmInfo(id, timestamp, "", prayerName, alertMode != "silent", isPreAdhan = true, minutesBefore = minutesBefore, alertMode = alertMode)

        val showIntent = PendingIntent.getActivity(
            this,
            id + 50000,
            Intent(android.provider.AlarmClock.ACTION_SHOW_ALARMS).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val clockInfo = AlarmManager.AlarmClockInfo(timestamp, showIntent)
                alarmManager.setAlarmClock(clockInfo, pendingIntent)
            } else {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, timestamp, pendingIntent)
            }
        } catch (e: SecurityException) {
            alarmManager.setExactAndAllowWhileIdle(
                AlarmManager.RTC_WAKEUP, timestamp, pendingIntent
            )
        }
    }

    private fun cancelAlarm(id: Int) {
        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent1 = Intent(this, AdhanBroadcastReceiver::class.java)
        val pendingIntent1 = PendingIntent.getBroadcast(
            this, id, intent1,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent1)

        val intent2 = Intent(this, PreAdhanBroadcastReceiver::class.java)
        val pendingIntent2 = PendingIntent.getBroadcast(
            this, id, intent2,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        alarmManager.cancel(pendingIntent2)

        removeAlarmInfo(id)
    }

    private fun cancelAllAlarms() {
        val prefs = getSharedPreferences("adhan_alarms_native", Context.MODE_PRIVATE)
        val allKeys = prefs.all.keys.filter { it.endsWith("_trigger") }
        val ids = allKeys.mapNotNull { it.removePrefix("alarm_").removeSuffix("_trigger").toIntOrNull() }.distinct()

        for (id in ids) {
            cancelAlarm(id)
        }
    }

    private fun saveAlarmInfo(
        id: Int,
        timestamp: Long,
        mp3ResName: String,
        prayerName: String,
        vibration: Boolean,
        isPreAdhan: Boolean,
        minutesBefore: Int = 0,
        alertMode: String = "vibrate"
    ) {
        val prefs = getSharedPreferences("adhan_alarms_native", Context.MODE_PRIVATE)
        prefs.edit().apply {
            putLong("alarm_${id}_trigger", timestamp)
            putString("alarm_${id}_mp3", mp3ResName)
            putString("alarm_${id}_prayer", prayerName)
            putBoolean("alarm_${id}_vibration", vibration)
            putBoolean("alarm_${id}_is_pre_adhan", isPreAdhan)
            putInt("alarm_${id}_minutes_before", minutesBefore)
            putString("alarm_${id}_alert_mode", alertMode)
            apply()
        }
    }

    private fun removeAlarmInfo(id: Int) {
        val prefs = getSharedPreferences("adhan_alarms_native", Context.MODE_PRIVATE)
        prefs.edit().apply {
            remove("alarm_${id}_trigger")
            remove("alarm_${id}_mp3")
            remove("alarm_${id}_prayer")
            remove("alarm_${id}_vibration")
            remove("alarm_${id}_is_pre_adhan")
            remove("alarm_${id}_minutes_before")
            remove("alarm_${id}_alert_mode")
            apply()
        }
    }

    private fun getScheduledAlarms(): List<Map<String, Any>> {
        val prefs = getSharedPreferences("adhan_alarms_native", Context.MODE_PRIVATE)
        val alarms = mutableListOf<Map<String, Any>>()
        val allKeys = prefs.all.keys.filter { it.endsWith("_trigger") }
        val now = System.currentTimeMillis()

        for (key in allKeys) {
            val id = key.removePrefix("alarm_").removeSuffix("_trigger").toIntOrNull() ?: continue
            val triggerAt = prefs.getLong(key, 0L)
            alarms.add(mapOf(
                "id" to id,
                "trigger" to triggerAt,
                "prayer" to (prefs.getString("alarm_${id}_prayer", "") ?: ""),
                "isPreAdhan" to prefs.getBoolean("alarm_${id}_is_pre_adhan", false),
                "isPast" to (triggerAt <= now)
            ))
        }
        return alarms
    }

    private fun openOemAutoStartSettings() {
        val intents = arrayOf(
            Intent().setComponent(ComponentName("com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity")),
            Intent().setComponent(ComponentName("com.letv.android.letvsafe", "com.letv.android.letvsafe.AutobootManageActivity")),
            Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity")),
            Intent().setComponent(ComponentName("com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity")),
            Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.AddWhiteListActivity")),
            Intent().setComponent(ComponentName("com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager")),
            Intent().setComponent(ComponentName("com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity")),
            Intent().setComponent(ComponentName("com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity")),
            Intent().setComponent(ComponentName("com.htc.pitroad", "com.htc.pitroad.landingpage.HTCLandingPageActivity")),
            Intent().setComponent(ComponentName("com.asus.mobilemanager", "com.asus.mobilemanager.MainActivity"))
        )
        for (intent in intents) {
            try {
                if (packageManager.resolveActivity(intent, 0) != null) {
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    return
                }
            } catch (_: Exception) {}
        }
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                data = Uri.fromParts("package", packageName, null)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            startActivity(intent)
        } catch (_: Exception) {}
    }
}
