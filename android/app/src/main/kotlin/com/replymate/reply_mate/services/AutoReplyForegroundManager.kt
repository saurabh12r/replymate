package com.replymate.reply_mate.services

import android.content.Context
import android.util.Log
import com.replymate.reply_mate.appstate.AppStateStore
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore

/**
 * Ensures a single foreground service instance when auto-reply is enabled.
 */
object AutoReplyForegroundManager {
    private const val TAG = "ReplyMateFgsMgr"

    @Volatile
    private var appReady: Boolean = false

    fun markAppReady() {
        appReady = true
        Log.d(TAG, "markAppReady")
    }

    @JvmStatic
    fun sync(context: Context) {
        try {
            if (!appReady || !AppStateStore.isAppReady(context)) {
                Log.d(TAG, "Skipping sync: app not ready")
                return
            }
            val app = context.applicationContext
            val cfg = AutoReplyConfigStore(app)
            // Hard block: when user is blocked, fully disable any foreground processing.
            if (cfg.getBlocked()) {
                AutoReplyForegroundService.stop(app)
                return
            }
            if (cfg.isEnabledFailSafe()) {
                AutoReplyForegroundService.start(app)
            } else {
                AutoReplyForegroundService.stop(app)
            }
        } catch (t: Throwable) {
            Log.e(TAG, "sync failed", t)
        }
    }
}
