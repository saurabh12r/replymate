package com.replymate.reply_mate.receivers

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.replymate.reply_mate.activity.ActivityLogPendingStore

/**
 * Receives [SmsManager] multipart "sent" result for the last part only.
 */
class SmsSendResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val logId = intent.getStringExtra(EXTRA_LOG_ID)
        if (!logId.isNullOrEmpty()) {
            val ok = resultCode == Activity.RESULT_OK
            if (!ok) {
                Log.d(TAG, "SMS send failed resultCode=$resultCode logId=$logId")
            }
            ActivityLogPendingStore.appendPatchReplied(context.applicationContext, logId, ok)
            return
        }
        if (resultCode != Activity.RESULT_OK) {
            Log.d(
                TAG,
                "SMS send failed (no activity log id) resultCode=$resultCode phone=${intent.getStringExtra(EXTRA_PHONE)}"
            )
        }
    }

    companion object {
        const val EXTRA_PHONE = "extra_phone"
        const val EXTRA_LOG_ID = "extra_log_id"
        private const val TAG = "ReplyMateSmsResult"
    }
}
