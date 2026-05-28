package com.austennkuna.intention

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.os.Handler
import android.os.Looper
import android.view.accessibility.AccessibilityEvent

class IntentionAccessibilityService : AccessibilityService() {

    companion object {
        const val ACTION_APP_OPENED = "com.austennkuna.intention.APP_OPENED"
        const val EXTRA_PACKAGE_NAME = "package_name"
        var isRunning = false
        val monitoredPackages = mutableSetOf<String>()
        var currentForegroundPackage = ""
    }

    private var lastPackage = ""
    private val handler = Handler(Looper.getMainLooper())
    private val limitCheckInterval = 10_000L // 10 seconds

    private val limitCheckRunnable = object : Runnable {
        override fun run() {
            checkCurrentAppLimit()
            handler.postDelayed(this, limitCheckInterval)
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true
        val info = AccessibilityServiceInfo().apply {
            eventTypes = AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED
            feedbackType = AccessibilityServiceInfo.FEEDBACK_GENERIC
            flags = AccessibilityServiceInfo.FLAG_REPORT_VIEW_IDS
            notificationTimeout = 100
        }
        serviceInfo = info
        // Start periodic limit check
        handler.postDelayed(limitCheckRunnable, limitCheckInterval)
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        if (packageName == "com.austennkuna.intention") return
        if (packageName == "com.android.systemui") return
        if (packageName == lastPackage) return

        lastPackage = packageName
        currentForegroundPackage = packageName

        android.util.Log.d("INTENTION", "App opened: $packageName")

        if (monitoredPackages.isEmpty() || !monitoredPackages.contains(packageName)) {
            android.util.Log.d("INTENTION", "Ignoring $packageName — not in monitored list")
            return
        }

        android.util.Log.d("INTENTION", "Broadcasting monitored app: $packageName")

        val broadcastIntent = Intent(ACTION_APP_OPENED).apply {
            putExtra(EXTRA_PACKAGE_NAME, packageName)
            setPackage(applicationContext.packageName)
        }
        sendBroadcast(broadcastIntent)
    }

    private fun checkCurrentAppLimit() {
        val pkg = currentForegroundPackage
        if (pkg.isEmpty()) return
        if (!monitoredPackages.contains(pkg)) return
        if (OverlayService.isRunning) return

        android.util.Log.d("INTENTION", "Limit check: broadcasting $pkg for Flutter check")

        // Broadcast to Flutter to check the limit
        val broadcastIntent = Intent(ACTION_APP_OPENED).apply {
            putExtra(EXTRA_PACKAGE_NAME, pkg)
            setPackage(applicationContext.packageName)
        }
        sendBroadcast(broadcastIntent)
    }

    override fun onInterrupt() {
        isRunning = false
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        handler.removeCallbacks(limitCheckRunnable)
    }
}