package com.austennkuna.intention

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import android.app.ActivityManager

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.austennkuna.intention/accessibility"
    private val EVENT_CHANNEL = "com.austennkuna.intention/app_events"

    private var eventSink: EventChannel.EventSink? = null
    private var appOpenedReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Method channel — check/open accessibility settings
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "isAccessibilityEnabled" -> {
                    result.success(isAccessibilityEnabled())
                }
                "openAccessibilitySettings" -> {
                    val intent = Intent(Settings.ACTION_ACCESSIBILITY_SETTINGS)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Event channel — stream app open events to Flutter
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                eventSink = sink
                registerReceiver()
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                unregisterAppReceiver()
            }
        })
    }

    private fun isAccessibilityEnabled(): Boolean {
        val expectedServiceName =
            "${packageName}/${IntentionAccessibilityService::class.java.canonicalName}"
        val enabledServices = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.ENABLED_ACCESSIBILITY_SERVICES
        ) ?: return false
        val colonSplitter = TextUtils.SimpleStringSplitter(':')
        colonSplitter.setString(enabledServices)
        while (colonSplitter.hasNext()) {
            if (colonSplitter.next().equals(expectedServiceName, ignoreCase = true)) {
                return true
            }
        }
        return false
    }

    private fun registerReceiver() {
        appOpenedReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            val packageName = intent?.getStringExtra(
                IntentionAccessibilityService.EXTRA_PACKAGE_NAME
            ) ?: return
            eventSink?.success(packageName)
        }
    }
        val filter = IntentFilter(IntentionAccessibilityService.ACTION_APP_OPENED)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(appOpenedReceiver, filter, RECEIVER_EXPORTED)
            } else {
            registerReceiver(appOpenedReceiver, filter)
       }
    }
    private fun launchCoolingLadder(packageName: String, appName: String, appEmoji: String, overrideCount: Int) {
        val intent = Intent(this, MainActivity::class.java).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or 
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP
            putExtra("route", "cooling-ladder")
            putExtra("packageName", packageName)
            putExtra("appName", appName)
            putExtra("appEmoji", appEmoji)
            putExtra("overrideCount", overrideCount)
        }
        startActivity(intent)
    }  

    private fun unregisterAppReceiver() {
        try {
            appOpenedReceiver?.let { unregisterReceiver(it) }
        } catch (e: Exception) {
            // Already unregistered
        }
        appOpenedReceiver = null
    }

    override fun onDestroy() {
        super.onDestroy()
        unregisterAppReceiver()
    }
}