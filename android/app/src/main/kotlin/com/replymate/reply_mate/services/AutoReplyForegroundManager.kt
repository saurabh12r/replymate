package com.replymate.reply_mate.services

import android.content.Context
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore

/**
 * Ensures a single foreground service instance when auto-reply is enabled.
 */
object AutoReplyForegroundManager {
    @JvmStatic
    fun sync(context: Context) {
        val app = context.applicationContext
        val cfg = AutoReplyConfigStore(app)
        if (cfg.isEnabledFailSafe()) {
            AutoReplyForegroundService.start(app)
        } else {
            AutoReplyForegroundService.stop(app)
        }
    }
}
