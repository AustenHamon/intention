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
    }

    private var lastPackage = ""

    override fun onServiceConnected() {
        super.onServiceConnected()
        isRunning = true

        // Configure what events we listen for
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

    if (packageName == "com.austennkuna.intention") return
    if (packageName == "com.android.systemui") return
    if (packageName == lastPackage) return

    lastPackage = packageName

    android.util.Log.d("INTENTION", "App opened: $packageName")

    // Broadcast to Flutter
    val broadcastIntent = Intent(ACTION_APP_OPENED).apply {
        putExtra(EXTRA_PACKAGE_NAME, packageName)
        setPackage(applicationContext.packageName)
    }
    sendBroadcast(broadcastIntent)

    // Bring Intention app to foreground
    val launchIntent = applicationContext.packageManager
        .getLaunchIntentForPackage(applicationContext.packageName)
    launchIntent?.apply {
        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP)
        startActivity(this)
    }
}
override fun onInterrupt() {
    android.util.Log.d("INTENTION", "Accessibility service interrupted")
}
}
