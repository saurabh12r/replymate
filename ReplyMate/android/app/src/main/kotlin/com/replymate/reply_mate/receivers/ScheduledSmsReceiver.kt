package com.replymate.reply_mate.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.os.Build
import android.util.Log
import com.replymate.reply_mate.sms.SmsSendHelper
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class ScheduledSmsReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "ReplyMate/SchedSms"
        const val EXTRA_ID = "id"
        const val EXTRA_PHONE = "phone"
        const val EXTRA_MESSAGE = "message"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(EXTRA_ID) ?: return
        val phone = intent.getStringExtra(EXTRA_PHONE) ?: return
        val message = intent.getStringExtra(EXTRA_MESSAGE) ?: return

        if (com.replymate.reply_mate.autoreply.AutoReplyConfigStore(context).getBlocked()) {
            Log.d(TAG, "ScheduledSmsReceiver blocked because subscription expired or blocked")
            return
        }

        Log.d(TAG, "ScheduledSmsReceiver triggered for id=$id, phone=$phone")

        // goAsync() keeps the broadcast process alive until pendingResult.finish() is called,
        // preventing the OS from killing the process mid-send when the app is closed.
        val pendingResult = goAsync()
        CoroutineScope(Dispatchers.IO).launch {
            try {
                val logId = UUID.randomUUID().toString()

                // Resolve default SMS subscription
                var subId = SubscriptionManager.getDefaultSmsSubscriptionId()
                if (subId == SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                    subId = SubscriptionManager.getDefaultSubscriptionId()
                }

                val smsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                    val baseManager = context.getSystemService(SmsManager::class.java)
                    if (subId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                        baseManager.createForSubscriptionId(subId)
                    } else {
                        baseManager
                    }
                } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1 && subId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                    @Suppress("DEPRECATION")
                    SmsManager.getSmsManagerForSubscriptionId(subId)
                } else {
                    @Suppress("DEPRECATION")
                    SmsManager.getDefault()
                }

                // Regular SMS path
                val parts = smsManager.divideMessage(message)
                SmsSendHelper.sendMultipartTextMessageWithSentCallback(
                    context,
                    smsManager,
                    phone,
                    parts,
                    logId
                )
                Log.d(TAG, "Scheduled SMS sent to $phone")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to send scheduled SMS to $phone", e)
            } finally {
                pendingResult.finish()
            }
        }
    }
}
