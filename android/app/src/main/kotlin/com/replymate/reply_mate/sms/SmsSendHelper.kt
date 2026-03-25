package com.replymate.reply_mate.sms

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.telephony.SmsManager
import com.replymate.reply_mate.receivers.SmsSendResultReceiver
import java.util.ArrayList

object SmsSendHelper {
    /**
     * Sends multipart SMS; last part carries [SmsSendResultReceiver].
     * @param correlationLogId when non-null, SMS result updates that activity row's [replied] flag in Hive.
     */
    fun sendMultipartTextMessageWithSentCallback(
        context: Context,
        smsManager: SmsManager,
        destinationAddress: String,
        parts: ArrayList<String>,
        correlationLogId: String? = null
    ) {
        val size = parts.size
        val sentIntents = ArrayList<PendingIntent?>(size)
        val deliveryIntents = ArrayList<PendingIntent?>(size)
        val appCtx = context.applicationContext
        for (i in 0 until size) {
            if (i == size - 1) {
                val requestCode = (destinationAddress.hashCode() xor System.nanoTime().toInt()) and 0x7fff
                val sentIntent = PendingIntent.getBroadcast(
                    appCtx,
                    requestCode,
                    Intent(appCtx, SmsSendResultReceiver::class.java).apply {
                        putExtra(SmsSendResultReceiver.EXTRA_PHONE, destinationAddress)
                        if (!correlationLogId.isNullOrEmpty()) {
                            putExtra(SmsSendResultReceiver.EXTRA_LOG_ID, correlationLogId)
                        }
                    },
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                sentIntents.add(sentIntent)
            } else {
                sentIntents.add(null)
            }
            deliveryIntents.add(null)
        }
        @Suppress("UNCHECKED_CAST")
        smsManager.sendMultipartTextMessage(
            destinationAddress,
            null,
            parts,
            sentIntents as ArrayList<PendingIntent>,
            deliveryIntents as ArrayList<PendingIntent>
        )
    }
}
