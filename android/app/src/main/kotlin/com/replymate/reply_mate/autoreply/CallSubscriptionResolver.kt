package com.replymate.reply_mate.autoreply

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.CallLog
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import androidx.core.content.ContextCompat

object CallSubscriptionResolver {
    /** Column name for [CallLog.Calls] — API 29+ (use string for compileSdk compatibility). */
    private const val SUBSCRIPTION_ID_COLUMN = "subscription_id"
    fun subscriptionIdFromPhoneStateIntent(intent: Intent): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val v = intent.getIntExtra(
            TelephonyManager.EXTRA_SUBSCRIPTION_ID,
            SubscriptionManager.INVALID_SUBSCRIPTION_ID
        )
        return if (v != SubscriptionManager.INVALID_SUBSCRIPTION_ID) v else null
    }

    fun getLatestCallLogSubscriptionId(context: Context): Int? {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q) return null
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED
        if (!hasPermission) return null
        return try {
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(SUBSCRIPTION_ID_COLUMN),
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val idx = it.getColumnIndex(SUBSCRIPTION_ID_COLUMN)
                    if (idx >= 0 && !it.isNull(idx)) {
                        val sub = it.getInt(idx)
                        if (sub != SubscriptionManager.INVALID_SUBSCRIPTION_ID) return sub
                    }
                }
            }
            null
        } catch (_: Exception) {
            null
        }
    }

    data class OutgoingCallRow(
        val number: String?,
        val subscriptionId: Int?,
    )

    fun getLatestOutgoingCall(context: Context): OutgoingCallRow? {
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED
        if (!hasPermission) return null
        return try {
            val columns = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DATE,
                    SUBSCRIPTION_ID_COLUMN,
                )
            } else {
                arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.TYPE, CallLog.Calls.DATE)
            }
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                columns,
                "${CallLog.Calls.TYPE}=?",
                arrayOf(CallLog.Calls.OUTGOING_TYPE.toString()),
                "${CallLog.Calls.DATE} DESC"
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val numberIdx = it.getColumnIndex(CallLog.Calls.NUMBER)
                    val number = if (numberIdx >= 0) it.getString(numberIdx) else null
                    var sub: Int? = null
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val subIdx = it.getColumnIndex(SUBSCRIPTION_ID_COLUMN)
                        if (subIdx >= 0 && !it.isNull(subIdx)) {
                            val v = it.getInt(subIdx)
                            if (v != SubscriptionManager.INVALID_SUBSCRIPTION_ID) sub = v
                        }
                    }
                    return OutgoingCallRow(number = number, subscriptionId = sub)
                }
            }
            null
        } catch (_: Exception) {
            null
        }
    }
}
