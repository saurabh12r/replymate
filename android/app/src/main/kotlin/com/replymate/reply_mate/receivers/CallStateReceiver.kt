package com.replymate.reply_mate.receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.provider.CallLog
import android.telephony.TelephonyManager
import android.util.Log
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import com.replymate.reply_mate.autoreply.AutoReplyEngine
import com.replymate.reply_mate.autoreply.AutoReplyEvent
import com.replymate.reply_mate.autoreply.CallSubscriptionResolver

/**
 * Tracks [TelephonyManager.ACTION_PHONE_STATE_CHANGED] and maps transitions to
 * one of 7 [AutoReplyEvent] types:
 *
 *  Incoming:
 *   - CALL_ANSWERED  (RINGING → OFFHOOK → IDLE)
 *   - MISSED_CALL    (RINGING → IDLE, call log is not REJECTED_TYPE)
 *   - REJECTED_CALL  (RINGING → IDLE, call log shows REJECTED_TYPE)
 *   - BUSY_CALL      (RINGING while already on a call)
 *
 *  Outgoing:
 *   - OUTGOING_ANSWERED   (IDLE → OFFHOOK → IDLE, call log duration > 0)
 *   - OUTGOING_UNANSWERED (IDLE → OFFHOOK → IDLE, call log duration == 0)
 *
 *  WhatsApp missed call is handled by [ReplyMateNotificationListenerService].
 */
class CallStateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        try {
            onReceiveImpl(context, intent)
        } catch (t: Throwable) {
            Log.e(TAG, "onReceive failed", t)
        }
    }

    private fun onReceiveImpl(context: Context, intent: Intent) {
        if (AutoReplyConfigStore(context).getBlocked()) return
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        val configStore = AutoReplyConfigStore(context)
        if (!configStore.isEnabledFailSafe()) {
            Log.d(TAG, "Blocked call event: autoReplyEnabled=false")
            return
        }

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val prevState = lastState
        val incoming = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        val intentSub = CallSubscriptionResolver.subscriptionIdFromPhoneStateIntent(intent)
        if (intentSub != null) {
            lastCallSubscriptionId = intentSub
        }
        Log.d(
            TAG,
            "Call state event: state=$state prevState=$prevState incoming=$incoming " +
                "wasRinging=$wasRinging wasOffhook=$wasOffhook isOnCall=$isOnCall " +
                "wasOutgoing=$wasOutgoing intentSub=$intentSub lastSub=$lastCallSubscriptionId"
        )
        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                if (isOnCall) {
                    Log.d(TAG, "Busy condition: RINGING while already OFFHOOK → BUSY_CALL")
                    val sub = intentSub ?: lastCallSubscriptionId
                    AutoReplyEngine.handleEvent(
                        context,
                        AutoReplyEvent.BUSY_CALL,
                        incoming,
                        sub
                    )
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
                if (prevState == TelephonyManager.EXTRA_STATE_IDLE && !wasRinging) {
                    // Outgoing call started — record state but do NOT fire an event yet.
                    // The outcome is determined when the call ends (IDLE).
                    val outgoing = CallSubscriptionResolver.getLatestOutgoingCall(context)
                    outgoingNumber = outgoing?.number
                    outgoingSubscriptionId = outgoing?.subscriptionId
                    wasOutgoing = true
                    Log.d(
                        TAG,
                        "Detected OUTGOING call start (IDLE->OFFHOOK) number=${outgoing?.number} sub=${outgoing?.subscriptionId}"
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

                if (wasOutgoing) {
                    // --- Outgoing call ended: determine outcome from call log ---
                    handleOutgoingCallEnded(context)
                } else if (wasRinging) {
                    // --- Incoming call ended ---
                    handleIncomingCallEnded(context, incoming)
                }

                resetState()
            }
        }
        lastState = state
    }

    /**
     * An outgoing call just ended (OFFHOOK → IDLE after IDLE → OFFHOOK without RINGING).
     * Query call log to determine if the other party picked up (duration > 0) or not.
     */
    private fun handleOutgoingCallEnded(context: Context) {
        val callInfo = CallSubscriptionResolver.getLatestCallLogEntry(context)
        val resolvedNumber = outgoingNumber ?: callInfo?.number
        val sub = outgoingSubscriptionId
            ?: callInfo?.subscriptionId
            ?: lastCallSubscriptionId
            ?: CallSubscriptionResolver.getLatestCallLogSubscriptionId(context)

        if (callInfo != null && callInfo.type == CallLog.Calls.OUTGOING_TYPE && callInfo.duration > 0) {
            Log.d(TAG, "Outgoing call ANSWERED: duration=${callInfo.duration} phone=$resolvedNumber")
            AutoReplyEngine.handleEvent(
                context,
                AutoReplyEvent.OUTGOING_ANSWERED,
                resolvedNumber,
                sub
            )
        } else {
            Log.d(TAG, "Outgoing call UNANSWERED: duration=${callInfo?.duration ?: 0} phone=$resolvedNumber")
            AutoReplyEngine.handleEvent(
                context,
                AutoReplyEvent.OUTGOING_UNANSWERED,
                resolvedNumber,
                sub
            )
        }
    }

    /**
     * An incoming call ended. Determine if it was answered, missed, or rejected.
     */
    private fun handleIncomingCallEnded(context: Context, intentIncoming: String?) {
        val callInfo = CallSubscriptionResolver.getLatestCallLogEntry(context)
        val resolvedNumber = incomingNumber ?: intentIncoming ?: callInfo?.number
        val subForIdle = lastCallSubscriptionId
            ?: callInfo?.subscriptionId
            ?: CallSubscriptionResolver.getLatestCallLogSubscriptionId(context)

        Log.d(
            TAG,
            "Transition: IDLE resolvedNumber=$resolvedNumber callLogType=${callInfo?.type} subForIdle=$subForIdle"
        )

        val answeredByLogFallback = !wasOffhook &&
            callInfo?.type == CallLog.Calls.INCOMING_TYPE

        if (wasOffhook || answeredByLogFallback) {
            Log.d(TAG, "Detected ANSWERED call flow (RINGING->OFFHOOK->IDLE)")
            AutoReplyEngine.handleEvent(
                context,
                AutoReplyEvent.CALL_ANSWERED,
                resolvedNumber,
                subForIdle
            )
        } else if (callInfo != null && CallSubscriptionResolver.isRejectedType(callInfo.type)) {
            Log.d(TAG, "Detected REJECTED call flow (RINGING->IDLE, call log REJECTED_TYPE)")
            AutoReplyEngine.handleEvent(
                context,
                AutoReplyEvent.REJECTED_CALL,
                resolvedNumber,
                subForIdle
            )
        } else {
            Log.d(TAG, "Detected MISSED call flow (RINGING->IDLE)")
            AutoReplyEngine.handleEvent(
                context,
                AutoReplyEvent.MISSED_CALL,
                resolvedNumber,
                subForIdle
            )
        }
    }

    private fun resetState() {
        wasRinging = false
        wasOffhook = false
        wasOutgoing = false
        incomingNumber = null
        outgoingNumber = null
        outgoingSubscriptionId = null
        lastCallSubscriptionId = null
    }

    companion object {
        private const val TAG = "ReplyMateCallReceiver"
        private var wasRinging: Boolean = false
        private var wasOffhook: Boolean = false
        private var wasOutgoing: Boolean = false
        private var incomingNumber: String? = null
        private var outgoingNumber: String? = null
        private var outgoingSubscriptionId: Int? = null
        private var isOnCall: Boolean = false
        private var lastState: String = TelephonyManager.EXTRA_STATE_IDLE
        private var lastCallSubscriptionId: Int? = null
    }
}
