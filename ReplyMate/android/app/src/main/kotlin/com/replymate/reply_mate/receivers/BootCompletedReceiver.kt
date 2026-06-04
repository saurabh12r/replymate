package com.replymate.reply_mate.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import com.replymate.reply_mate.services.AutoReplyForegroundManager
import com.replymate.reply_mate.services.AutoReplyForegroundService

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
            if (cfg.isEnabledFailSafe()) {
                Log.d(TAG, "Auto-reply is enabled, starting foreground service on boot.")
                AutoReplyForegroundManager.markAppReady()
                AutoReplyForegroundService.start(context)
            }
        } catch (t: Throwable) {
            Log.e(TAG, "Boot receiver failed", t)
        }
    }

    companion object {
        private const val TAG = "ReplyMateBootReceiver"
    }
}
