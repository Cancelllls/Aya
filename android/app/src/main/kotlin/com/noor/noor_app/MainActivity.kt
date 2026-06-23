package com.noor.noor_app

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
import android.speech.tts.TextToSpeech
import android.os.Vibrator
import android.os.VibrationEffect
import java.util.Locale
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity(), TextToSpeech.OnInitListener {
    private val CHANNEL = "com.noor.noor_app/system"
    private var tts: TextToSpeech? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Initialize Text-To-Speech
        tts = TextToSpeech(this, this)
        
        // Natively support up to 144Hz screens by requesting the highest refresh rate mode
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
                } catch (e: Exception) {
                    // Ignore if display mode selection is unsupported
                }
            }
        } else {
            try {
                val params = window.attributes
                params.preferredRefreshRate = 144f
                window.attributes = params
            } catch (e: Exception) {}
        }
    }

    override fun onInit(status: Int) {
        if (status == TextToSpeech.SUCCESS) {
            tts?.language = Locale("ar")
        }
    }

    private fun speak(text: String, lang: String) {
        try {
            tts?.language = Locale(lang)
            tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
        } catch (e: Exception) {}
    }

    override fun onDestroy() {
        try {
            tts?.stop()
            tts?.shutdown()
        } catch (e: Exception) {}
        super.onDestroy()
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkExactAlarmPermission" -> {
                    val permitted = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as AlarmManager
                        alarmManager.canScheduleExactAlarms()
                    } else {
                        true
                    }
                    result.success(permitted)
                }
                "requestExactAlarmPermission" -> {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        try {
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM).apply {
                                data = Uri.fromParts("package", packageName, null)
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // Fallback if package Uri is rejected by some devices
                            val intent = Intent(Settings.ACTION_REQUEST_SCHEDULE_EXACT_ALARM)
                            startActivity(intent)
                            result.success(true)
                        }
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
                            }
                            startActivity(intent)
                            result.success(true)
                        } catch (e: Exception) {
                            // Fallback to general settings screen
                            try {
                                val intent = Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS)
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
                    val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
                    if (vibrator.hasVibrator()) {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
                        } else {
                            @Suppress("DEPRECATION")
                            vibrator.vibrate(pattern, -1)
                        }
                    }
                    result.success(true)
                }
                "speak" -> {
                    val text = call.argument<String>("text") ?: ""
                    val lang = call.argument<String>("lang") ?: "ar"
                    speak(text, lang)
                    result.success(true)
                }
                "updateWidget" -> {
                    try {
                        // 1. Update Prayer Widget
                        val intent1 = Intent(context, NoorWidgetProvider::class.java).apply {
                            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        }
                        val ids1 = AppWidgetManager.getInstance(context).getAppWidgetIds(
                            ComponentName(context, NoorWidgetProvider::class.java)
                        )
                        intent1.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids1)
                        context.sendBroadcast(intent1)

                        // 2. Update Verse Widget
                        val intent2 = Intent(context, NoorVerseWidgetProvider::class.java).apply {
                            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        }
                        val ids2 = AppWidgetManager.getInstance(context).getAppWidgetIds(
                            ComponentName(context, NoorVerseWidgetProvider::class.java)
                        )
                        intent2.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids2)
                        context.sendBroadcast(intent2)

                        // 3. Update Dhikr Widget
                        val intent3 = Intent(context, NoorDhikrWidgetProvider::class.java).apply {
                            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        }
                        val ids3 = AppWidgetManager.getInstance(context).getAppWidgetIds(
                            ComponentName(context, NoorDhikrWidgetProvider::class.java)
                        )
                        intent3.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids3)
                        context.sendBroadcast(intent3)

                        // 4. Update Hadith Widget
                        val intent4 = Intent(context, NoorHadithWidgetProvider::class.java).apply {
                            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        }
                        val ids4 = AppWidgetManager.getInstance(context).getAppWidgetIds(
                            ComponentName(context, NoorHadithWidgetProvider::class.java)
                        )
                        intent4.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids4)
                        context.sendBroadcast(intent4)

                        // 5. Update Tasbih Widget
                        val intent5 = Intent(context, NoorTasbihWidgetProvider::class.java).apply {
                            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
                        }
                        val ids5 = AppWidgetManager.getInstance(context).getAppWidgetIds(
                            ComponentName(context, NoorTasbihWidgetProvider::class.java)
                        )
                        intent5.putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids5)
                        context.sendBroadcast(intent5)

                        result.success(true)
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
