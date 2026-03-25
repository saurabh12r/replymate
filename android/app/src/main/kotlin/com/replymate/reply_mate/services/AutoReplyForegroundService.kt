package com.replymate.reply_mate.services

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import com.replymate.reply_mate.MainActivity
import com.replymate.reply_mate.R

/**
 * Foreground service keeps the process in a higher priority tier for call/SMS receivers.
 * Call detection remains via manifest [BroadcastReceiver]; this does not register a second listener.
 */
class AutoReplyForegroundService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        createChannel()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(NOTIFICATION_ID, buildNotification())
        return START_STICKY
    }

    private fun createChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val mgr = getSystemService(NotificationManager::class.java) ?: return
        val ch = NotificationChannel(
            CHANNEL_ID,
            getString(R.string.replymate_fgs_channel_name),
            NotificationManager.IMPORTANCE_LOW
        ).apply {
            description = getString(R.string.replymate_fgs_channel_desc)
            setShowBadge(false)
        }
        mgr.createNotificationChannel(ch)
    }

    private fun buildNotification(): Notification {
        val launch = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_SINGLE_TOP
            },
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.replymate_fgs_title))
            .setContentText(getString(R.string.replymate_fgs_text))
            .setOngoing(true)
            .setContentIntent(launch)
            .setCategory(NotificationCompat.CATEGORY_SERVICE)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .build()
    }

    companion object {
        const val NOTIFICATION_ID = 71001
        const val CHANNEL_ID = "replymate_auto_reply_fgs"

        fun start(context: Context) {
            val app = context.applicationContext
            val i = Intent(app, AutoReplyForegroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                app.startForegroundService(i)
            } else {
                @Suppress("DEPRECATION")
                app.startService(i)
            }
        }

        fun stop(context: Context) {
            val app = context.applicationContext
            app.stopService(Intent(app, AutoReplyForegroundService::class.java))
        }
    }
}
