package com.replymate.reply_mate.receivers

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.provider.CallLog
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.content.ContextCompat
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import com.replymate.reply_mate.autoreply.AutoReplyEngine
import com.replymate.reply_mate.autoreply.AutoReplyEvent

class CallStateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        val configStore = AutoReplyConfigStore(context)
        if (!configStore.isEnabledFailSafe()) {
            Log.d(TAG, "Blocked call event: autoReplyEnabled=false")
            return
        }

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val prevState = lastState
        val incoming = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        Log.d(
            TAG,
            "Call state event: state=$state prevState=$prevState incoming=$incoming wasRinging=$wasRinging wasOffhook=$wasOffhook isOnCall=$isOnCall"
        )
        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                // If user is already on a call, a second incoming call is the "busy" condition.
                if (isOnCall) {
                    Log.d(TAG, "Busy condition: RINGING while already OFFHOOK → BUSY_CALL")
                    AutoReplyEngine.handleEvent(
                        context,
                        AutoReplyEvent.BUSY_CALL,
                        incoming
                    )
                    // Don't treat this as a normal ringing flow (avoids sending missed/incoming later).
                    wasRinging = false
                    wasOffhook = false
                    incomingNumber = null
                    return
                }
                incomingNumber = incoming
                wasRinging = true
                wasOffhook = false
                Log.d(TAG, "Transition: RINGING incomingNumber=$incomingNumber")
            }

            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                isOnCall = true
                // Outgoing call detection (best-effort): OFFHOOK while previous state was IDLE
                // and we were not in a ringing flow.
                if (prevState == TelephonyManager.EXTRA_STATE_IDLE && !wasRinging) {
                    val outgoingNumber = getLastOutgoingNumber(context)
                    Log.d(TAG, "Detected OUTGOING call flow (IDLE->OFFHOOK) number=$outgoingNumber")
                    AutoReplyEngine.handleEvent(
                        context,
                        AutoReplyEvent.OUTGOING_CALL,
                        outgoingNumber
                    )
                }
                if (!incoming.isNullOrBlank()) {
                    incomingNumber = incoming
                }
                if (wasRinging) {
                    wasOffhook = true
                    Log.d(TAG, "Transition: OFFHOOK while ringing")
                }
            }

            TelephonyManager.EXTRA_STATE_IDLE -> {
                isOnCall = false
                val lastCall = getLastCallInfo(context)
                val resolvedNumber = incomingNumber ?: incoming ?: lastCall?.number
                Log.d(
                    TAG,
                    "Transition: IDLE resolvedNumber=$resolvedNumber lastType=${lastCall?.type}"
                )
                val answeredByLogFallback = wasRinging &&
                    !wasOffhook &&
                    lastCall?.type == CallLog.Calls.INCOMING_TYPE
                if (wasRinging && (wasOffhook || answeredByLogFallback)) {
                    Log.d(TAG, "Detected ANSWERED call flow (RINGING->OFFHOOK->IDLE)")
                    AutoReplyEngine.handleEvent(
                        context,
                        AutoReplyEvent.CALL_ANSWERED,
                        resolvedNumber
                    )
                } else if (wasRinging) {
                    Log.d(TAG, "Detected MISSED call flow (RINGING->IDLE)")
                    AutoReplyEngine.handleEvent(
                        context,
                        AutoReplyEvent.MISSED_CALL,
                        resolvedNumber
                    )
                }
                wasRinging = false
                wasOffhook = false
                incomingNumber = null
            }
        }
        lastState = state
    }

    private fun getLastOutgoingNumber(context: Context): String? {
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED
        if (!hasPermission) {
            Log.d(TAG, "Outgoing lookup skipped: READ_CALL_LOG not granted")
            return null
        }
        return try {
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.TYPE, CallLog.Calls.DATE),
                "${CallLog.Calls.TYPE}=?",
                arrayOf(CallLog.Calls.OUTGOING_TYPE.toString()),
                "${CallLog.Calls.DATE} DESC"
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val numberIdx = it.getColumnIndex(CallLog.Calls.NUMBER)
                    if (numberIdx >= 0) {
                        val number = it.getString(numberIdx)
                        Log.d(TAG, "Outgoing lookup number=$number")
                        return number
                    }
                }
            }
            null
        } catch (e: Exception) {
            Log.e(TAG, "Outgoing lookup failed", e)
            null
        }
    }

    private fun getLastCallInfo(context: Context): LastCallInfo? {
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.READ_CALL_LOG
        ) == PackageManager.PERMISSION_GRANTED
        if (!hasPermission) {
            Log.d(TAG, "Call log fallback skipped: READ_CALL_LOG not granted")
            return null
        }

        return try {
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.NUMBER, CallLog.Calls.TYPE, CallLog.Calls.DATE),
                null,
                null,
                "${CallLog.Calls.DATE} DESC"
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val numberIdx = it.getColumnIndex(CallLog.Calls.NUMBER)
                    val typeIdx = it.getColumnIndex(CallLog.Calls.TYPE)
                    if (numberIdx >= 0 && typeIdx >= 0) {
                        val number = it.getString(numberIdx)
                        val type = it.getInt(typeIdx)
                        Log.d(TAG, "Call log fallback number=$number type=$type")
                        return LastCallInfo(number = number, type = type)
                    }
                }
            }
            Log.d(TAG, "Call log fallback: no recent call found")
            null
        } catch (e: Exception) {
            Log.e(TAG, "Call log fallback failed", e)
            null
        }
    }

    companion object {
        private const val TAG = "ReplyMateCallReceiver"
        private var wasRinging: Boolean = false
        private var wasOffhook: Boolean = false
        private var incomingNumber: String? = null
        private var isOnCall: Boolean = false
        private var lastState: String = TelephonyManager.EXTRA_STATE_IDLE
    }

    data class LastCallInfo(
        val number: String?,
        val type: Int
    )
}
