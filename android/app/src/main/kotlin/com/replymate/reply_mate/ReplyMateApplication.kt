package com.replymate.reply_mate

import android.app.Application
import android.util.Log

/**
 * Restores foreground service when the process starts (e.g. after swipe-away restart).
 */
class ReplyMateApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Application.onCreate")
    }

    companion object {
        private const val TAG = "ReplyMateApp"
    }
}
