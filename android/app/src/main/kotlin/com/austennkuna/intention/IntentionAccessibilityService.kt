package com.austennkuna.intention

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.Intent
import android.view.accessibility.AccessibilityEvent

class IntentionAccessibilityService : AccessibilityService() {

    companion object {
        const val ACTION_APP_OPENED = "com.austennkuna.intention.APP_OPENED"
        const val EXTRA_PACKAGE_NAME = "package_name"
        var isRunning = false

        // Keep monitored packages here — updated from Flutter via broadcast
        val monitoredPackages = mutableSetOf<String>()
    }

    private var lastPackage = ""

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
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event?.eventType != AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED) return

        val packageName = event.packageName?.toString() ?: return

        // Ignore system UI and our own app
        if (packageName == "com.austennkuna.intention") return
        if (packageName == "com.android.systemui") return
        if (packageName == lastPackage) return

        lastPackage = packageName

        android.util.Log.d("INTENTION", "App opened: $packageName")

        // Only broadcast if this package is in our monitored list
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

    override fun onInterrupt() {
        isRunning = false
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
    }
}