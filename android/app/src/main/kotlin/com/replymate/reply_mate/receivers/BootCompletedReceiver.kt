package com.replymate.reply_mate.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import com.replymate.reply_mate.services.AutoReplyForegroundManager

/**
 * Restarts the foreground service after reboot when auto-reply is on.
 */
class BootCompletedReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        if (intent?.action != Intent.ACTION_BOOT_COMPLETED &&
            intent?.action != "android.intent.action.QUICKBOOT_POWERON"
        ) {
            return
        }
        val cfg = AutoReplyConfigStore(context.applicationContext)
        if (cfg.isEnabledFailSafe()) {
            AutoReplyForegroundManager.sync(context.applicationContext)
        }
    }
}
