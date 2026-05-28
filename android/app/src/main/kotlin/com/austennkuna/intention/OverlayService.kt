package com.austennkuna.intention

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.PixelFormat
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView
import androidx.core.app.NotificationCompat
import android.os.CountDownTimer
import android.view.animation.AlphaAnimation
import android.view.animation.Animation

class OverlayService : Service() {

    companion object {
        const val EXTRA_APP_NAME = "app_name"
        const val EXTRA_APP_PACKAGE = "app_package"
        const val EXTRA_OVERRIDE_COUNT = "override_count"
        const val CHANNEL_ID = "intention_overlay"

        var isRunning = false

        fun shouldShowOverlay(packageName: String): Boolean =
            !isRunning && packageName.isNotEmpty()
    }

    private var windowManager: WindowManager? = null
    private var overlayView: View? = null
    private var countDownTimer: CountDownTimer? = null

    private var appName = ""
    private var packageName = ""
    private var overrideCount = 0

    // Tier wait times in milliseconds
    private val waitTimes = listOf(5000L, 15000L, 60000L)

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        isRunning = true
        startForeground(1, createNotification())
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        appName = intent?.getStringExtra(EXTRA_APP_NAME) ?: "App"
        packageName = intent?.getStringExtra(EXTRA_APP_PACKAGE) ?: ""
        overrideCount = intent?.getIntExtra(EXTRA_OVERRIDE_COUNT, 0) ?: 0

        showOverlay()
        return START_NOT_STICKY
    }

    private fun showOverlay() {
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            else
                WindowManager.LayoutParams.TYPE_PHONE,
            WindowManager.LayoutParams.FLAG_NOT_TOUCH_MODAL or
                    WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            PixelFormat.TRANSLUCENT
        )
        params.gravity = Gravity.TOP or Gravity.START

        overlayView = createOverlayView()

        try {
            windowManager?.addView(overlayView, params)
            fadeIn(overlayView!!)
        } catch (e: Exception) {
            stopSelf()
        }
    }

    private fun createOverlayView(): View {
        val context = this
        val waitTime = waitTimes.getOrElse(overrideCount) { waitTimes.last() }
        val waitSeconds = (waitTime / 1000).toInt()

        // Root layout
        val root = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(60, 120, 60, 120)
            val bg = GradientDrawable(
                GradientDrawable.Orientation.TL_BR,
                intArrayOf(
                    Color.parseColor("#E60A0E27"),
                    Color.parseColor("#E61A1040")
                )
            )
            background = bg
        }

        // App emoji / icon placeholder
        val emojiText = TextView(context).apply {
            text = getAppEmoji()
            textSize = 56f
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }

        // Title
        val title = TextView(context).apply {
            text = getTierTitle()
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(0, 0, 0, 16)
        }

        // Subtitle
        val subtitle = TextView(context).apply {
            text = getTierMessage()
            textSize = 16f
            setTextColor(Color.parseColor("#B3FFFFFF"))
            gravity = Gravity.CENTER
            setLineSpacing(0f, 1.4f)
            setPadding(40, 0, 40, 48)
        }

        // Timer container
        val timerContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#1AFFFFFF"))
                cornerRadius = 60f
                setStroke(2, Color.parseColor("#33FFFFFF"))
            }
            background = bg
            setPadding(80, 60, 80, 60)
        }

        // Timer text
        val timerText = TextView(context).apply {
            text = "$waitSeconds"
            textSize = 64f
            setTextColor(getTimerColor())
            gravity = Gravity.CENTER
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }

        val timerLabel = TextView(context).apply {
            text = "seconds"
            textSize = 14f
            setTextColor(Color.parseColor("#66FFFFFF"))
            gravity = Gravity.CENTER
        }

        timerContainer.addView(timerText)
        timerContainer.addView(timerLabel)
        
        // Progress bar
         val progressBar = ProgressBar(
            context, null,
            android.R.attr.progressBarStyleHorizontal
         )
         progressBar.max = waitSeconds
         progressBar.progress = waitSeconds
         progressBar.progressDrawable?.setColorFilter(
             getTimerColor(),
             android.graphics.PorterDuff.Mode.SRC_IN
         )
         progressBar.setPadding(0, 40, 0, 40)

        // Intention input (for tier 2+)
        val intentionInput = android.widget.EditText(context).apply {
            hint = "Why do you need this right now?"
            setHintTextColor(Color.parseColor("#66FFFFFF"))
            setTextColor(Color.WHITE)
            textSize = 16f
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#1AFFFFFF"))
                cornerRadius = 24f
                setStroke(2, Color.parseColor("#33FFFFFF"))
            }
            background = bg
            setPadding(40, 32, 40, 32)
            visibility = if (overrideCount >= 1) View.VISIBLE else View.GONE
        }

        // Proceed button
        val proceedBtn = Button(context).apply {
            text = "Please wait..."
            isEnabled = false
            alpha = 0.5f
            val bg = GradientDrawable().apply {
                setColor(getTimerColor())
                cornerRadius = 40f
            }
            background = bg
            setTextColor(Color.WHITE)
            textSize = 18f
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            setPadding(60, 32, 60, 32)
        }

        // Exit button
        val exitBtn = Button(context).apply {
            text = "Go back to home"
            val bg = GradientDrawable().apply {
                setColor(Color.parseColor("#1AFFFFFF"))
                cornerRadius = 40f
                setStroke(2, Color.parseColor("#33FFFFFF"))
            }
            background = bg
            setTextColor(Color.parseColor("#80FFFFFF"))
            textSize = 16f
            setPadding(60, 28, 60, 28)
        }

        // Override count badge
        val overrideBadge = TextView(context).apply {
            text = "Override ${overrideCount + 1}"
            textSize = 12f
            setTextColor(getTimerColor())
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, 32)
        }

        // Start countdown
        countDownTimer = object : CountDownTimer(waitTime, 1000) {
            override fun onTick(millisUntilFinished: Long) {
                val secondsLeft = (millisUntilFinished / 1000).toInt()
                timerText.text = "$secondsLeft"
                progressBar.progress = secondsLeft
            }

            override fun onFinish() {
                timerText.text = "0"
                progressBar.progress = 0

                // Show appropriate next step
                if (overrideCount >= 1) {
                    intentionInput.visibility = View.VISIBLE
                    proceedBtn.text = "Open $appName"
                    proceedBtn.isEnabled = true
                    proceedBtn.alpha = 1.0f
                } else {
                    proceedBtn.text = "Open $appName"
                    proceedBtn.isEnabled = true
                    proceedBtn.alpha = 1.0f
                }

                // Pulse animation on button
                val pulse = AlphaAnimation(0.6f, 1.0f).apply {
                    duration = 500
                    repeatCount = 2
                    repeatMode = Animation.REVERSE
                }
                proceedBtn.startAnimation(pulse)
            }
        }.start()

        // Button listeners
        proceedBtn.setOnClickListener {
            // Check intention input if required
            if (overrideCount >= 1 && intentionInput.text.toString().trim().length < 5) {
                intentionInput.error = "Please state your intention (min 5 chars)"
                return@setOnClickListener
            }
            // Launch the monitored app
            val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            launchIntent?.let {
                it.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(it)
            }
            removeOverlay()
        }

        exitBtn.setOnClickListener {
            // Go back to home screen
            val homeIntent = Intent(Intent.ACTION_MAIN).apply {
                addCategory(Intent.CATEGORY_HOME)
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            startActivity(homeIntent)
            removeOverlay()
        }

        // Assemble layout
        val buttonContainer = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(0, 48, 0, 0)
        }

        val proceedParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { setMargins(0, 0, 0, 16) }

        val exitParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )

        buttonContainer.addView(proceedBtn, proceedParams)
        buttonContainer.addView(exitBtn, exitParams)

        root.addView(overrideBadge)
        root.addView(emojiText)
        root.addView(title)
        root.addView(subtitle)
        root.addView(timerContainer)
        root.addView(progressBar)
        root.addView(intentionInput)
        root.addView(buttonContainer)

        return root
    }

    private fun getAppEmoji(): String {
        return when (packageName) {
            "com.zhiliaoapp.musically" -> "🎵"
            "com.instagram.android" -> "📸"
            "com.twitter.android" -> "🐦"
            "com.google.android.youtube" -> "▶️"
            "com.facebook.katana" -> "👥"
            "com.whatsapp" -> "💬"
            "com.snapchat.android" -> "👻"
            else -> "📱"
        }
    }

    private fun getTierTitle(): String {
        return when (overrideCount) {
            0 -> "Take a breath"
            1 -> "Pause & reflect"
            else -> "Are you sure?"
        }
    }

    private fun getTierMessage(): String {
        return when (overrideCount) {
            0 -> "You've reached your limit for $appName.\nTake a moment before continuing."
            1 -> "This is your second override today.\nIs this how you want to spend your time?"
            else -> "You've overridden your limit multiple times.\nPlease state your intention clearly."
        }
    }

    private fun getTimerColor(): Int {
        return when (overrideCount) {
            0 -> Color.parseColor("#4F9EFF")
            1 -> Color.parseColor("#F59E0B")
            else -> Color.parseColor("#EF4444")
        }
    }

    private fun fadeIn(view: View) {
        val anim = AlphaAnimation(0f, 1f).apply {
            duration = 400
            fillAfter = true
        }
        view.startAnimation(anim)
    }

    private fun removeOverlay() {
        countDownTimer?.cancel()
        try {
            overlayView?.let { windowManager?.removeView(it) }
        } catch (e: Exception) {
            // View already removed
        }
        overlayView = null

        val intent = Intent("com.austennkuna.intention.OVERLAY_DISMISSED").apply {
            setPackage(applicationContext.packageName)
        }
        sendBroadcast(intent)

        stopSelf()
    }

    override fun onDestroy() {
        super.onDestroy()
        isRunning = false
        removeOverlay()
    }

    private fun createNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Intention Overlay",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Screen time intervention overlay"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("Intention")
            .setContentText("Mindful friction active")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }
}