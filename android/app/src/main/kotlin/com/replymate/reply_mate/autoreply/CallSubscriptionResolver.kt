package com.replymate.reply_mate.autoreply

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.provider.CallLog
import android.telephony.SubscriptionManager
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.content.ContextCompat

object CallSubscriptionResolver {
    private const val TAG = "ReplyMateCallSubRes"
    /** Column name for [CallLog.Calls] — API 29+ (use string for compileSdk compatibility). */
    private const val SUBSCRIPTION_ID_COLUMN = "subscription_id"

    /** Android N+ call log type for calls the user explicitly rejected. */
    private const val CALL_LOG_REJECTED_TYPE = 5

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

    /**
     * Returns the most recent call log entry (any type). Used to determine:
     *  - Incoming missed vs rejected (call log type [CALL_LOG_REJECTED_TYPE])
     *  - Outgoing call outcome (duration > 0 means answered)
     */
    data class RecentCallInfo(
        val number: String?,
        val type: Int,
        val duration: Long,
        val subscriptionId: Int?,
    )

    fun getLatestCallLogEntry(context: Context): RecentCallInfo? {
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED
        if (!hasPermission) {
            Log.d(TAG, "getLatestCallLogEntry: READ_CALL_LOG not granted")
            return null
        }
        return try {
            val columns = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DURATION,
                    CallLog.Calls.DATE,
                    SUBSCRIPTION_ID_COLUMN,
                )
            } else {
                arrayOf(
                    CallLog.Calls.NUMBER,
                    CallLog.Calls.TYPE,
                    CallLog.Calls.DURATION,
                    CallLog.Calls.DATE,
                )
            }
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                columns,
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val numberIdx = it.getColumnIndex(CallLog.Calls.NUMBER)
                    val typeIdx = it.getColumnIndex(CallLog.Calls.TYPE)
                    val durationIdx = it.getColumnIndex(CallLog.Calls.DURATION)
                    if (typeIdx < 0) return null
                    val number = if (numberIdx >= 0) it.getString(numberIdx) else null
                    val type = it.getInt(typeIdx)
                    val duration = if (durationIdx >= 0) it.getLong(durationIdx) else 0L
                    var sub: Int? = null
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        val subIdx = it.getColumnIndex(SUBSCRIPTION_ID_COLUMN)
                        if (subIdx >= 0 && !it.isNull(subIdx)) {
                            val v = it.getInt(subIdx)
                            if (v != SubscriptionManager.INVALID_SUBSCRIPTION_ID) sub = v
                        }
                    }
                    Log.d(TAG, "getLatestCallLogEntry: number=$number type=$type duration=$duration sub=$sub")
                    return RecentCallInfo(number = number, type = type, duration = duration, subscriptionId = sub)
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "getLatestCallLogEntry failed", e)
            null
        }
    }

    /** Whether [type] is the Android N+ "rejected by user" call log type. */
    fun isRejectedType(type: Int): Boolean = type == CALL_LOG_REJECTED_TYPE
}
