package com.replymate.reply_mate.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import com.replymate.reply_mate.services.AutoReplyForegroundManager

/**
 * Restarts the foreground service after reboot when auto-reply is on.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        try {
            if (intent?.action != Intent.ACTION_BOOT_COMPLETED &&
                intent?.action != "android.intent.action.QUICKBOOT_POWERON"
            ) {
                return
            }
            val cfg = AutoReplyConfigStore(context.applicationContext)
            if (cfg.getBlocked()) return
            // Foreground service is not started during boot; it is synced only
            // after the user opens the app (appReady) or via user actions.
        } catch (t: Throwable) {
            Log.e(TAG, "Boot receiver failed", t)
        }
    }

    companion object {
        private const val TAG = "ReplyMateBootReceiver"
    }
}
