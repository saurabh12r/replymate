package com.replymate.reply_mate

import android.app.Application
import com.replymate.reply_mate.services.AutoReplyForegroundManager

/**
 * Restores foreground service when the process starts (e.g. after swipe-away restart).
 */
class ReplyMateApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        AutoReplyForegroundManager.sync(this)
    }
}
