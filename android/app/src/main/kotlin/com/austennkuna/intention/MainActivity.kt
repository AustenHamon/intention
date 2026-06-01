package com.austennkuna.intention

import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.text.TextUtils
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val METHOD_CHANNEL = "com.austennkuna.intention/accessibility"
    private val EVENT_CHANNEL = "com.austennkuna.intention/app_events"
    private val OVERLAY_CHANNEL = "com.austennkuna.intention/overlay"

    private var eventSink: EventChannel.EventSink? = null
    private var appOpenedReceiver: BroadcastReceiver? = null
    private var overlayDismissReceiver: BroadcastReceiver? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Accessibility method channel
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
                "updateMonitoredPackages" -> {
                    val packages = call.argument<List<String>>("packages") ?: emptyList()
                    IntentionAccessibilityService.monitoredPackages.clear()
                    IntentionAccessibilityService.monitoredPackages.addAll(packages)
                    android.util.Log.d("INTENTION", "Updated monitored packages: $packages")
                    result.success(true)
                }
                "isDeviceAdminActive" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val component = ComponentName(this, IntentionDeviceAdminReceiver::class.java)
                    result.success(dpm.isAdminActive(component))
                }
                "activateDeviceAdmin" -> {
                    val component = ComponentName(this, IntentionDeviceAdminReceiver::class.java)
                    val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                        putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, component)
                        putExtra(
                            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                            "Strict Mode prevents uninstalling Intention without disabling it first."
                        )
                    }
                    startActivity(intent)
                    result.success(true)
                }
                "deactivateDeviceAdmin" -> {
                    val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                    val component = ComponentName(this, IntentionDeviceAdminReceiver::class.java)
                    dpm.removeActiveAdmin(component)
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
                registerAppReceiver()
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                unregisterAppReceiver()
            }
        })

        // Overlay method channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            OVERLAY_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkOverlayPermission" -> {
                    result.success(Settings.canDrawOverlays(this))
                }
                "requestOverlayPermission" -> {
                    val intent = Intent(
                        Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                        Uri.parse("package:$packageName")
                    )
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    startActivity(intent)
                    result.success(true)
                }
                "showOverlay" -> {
                    val pkg = call.argument<String>("packageName") ?: ""
                    val appName = call.argument<String>("appName") ?: "App"
                    val overrideCount = call.argument<Int>("overrideCount") ?: 0
                    val showOverrideCount = call.argument<Boolean>("showOverrideCount") ?: true
                    val positiveFraming = call.argument<Boolean>("positiveFraming") ?: true
                    val strictMode = call.argument<Boolean>("strictMode") ?: false

                    if (Settings.canDrawOverlays(this)) {
                        val intent = Intent(this, OverlayService::class.java).apply {
                            putExtra(OverlayService.EXTRA_APP_PACKAGE, pkg)
                            putExtra(OverlayService.EXTRA_APP_NAME, appName)
                            putExtra(OverlayService.EXTRA_OVERRIDE_COUNT, overrideCount)
                            putExtra(OverlayService.EXTRA_SHOW_OVERRIDE_COUNT, showOverrideCount)
                            putExtra(OverlayService.EXTRA_POSITIVE_FRAMING, positiveFraming)
                            putExtra(OverlayService.EXTRA_STRICT_MODE, strictMode)
                        }
                        startForegroundService(intent)
                        result.success(true)
                    } else {
                        val intent = Intent(
                            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
                            Uri.parse("package:$packageName")
                        )
                        intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
                        startActivity(intent)
                        result.success(false)
                    }
                }
                "dismissOverlay" -> {
                    stopService(Intent(this, OverlayService::class.java))
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // Listen for overlay dismissed broadcast and forward to Flutter
        overlayDismissReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    OVERLAY_CHANNEL
                ).invokeMethod("overlayDismissed", null)
            }
        }
        val dismissFilter = IntentFilter("com.austennkuna.intention.OVERLAY_DISMISSED")
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(overlayDismissReceiver, dismissFilter, RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(overlayDismissReceiver, dismissFilter)
        }
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

    private fun registerAppReceiver() {
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
        try {
            overlayDismissReceiver?.let { unregisterReceiver(it) }
        } catch (e: Exception) {
            // Already unregistered
        }
        overlayDismissReceiver = null
    }
}