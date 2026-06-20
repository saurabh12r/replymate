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
import com.google.android.gms.tasks.Tasks
import com.google.firebase.FirebaseApp
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FirebaseFirestore
import com.replymate.reply_mate.autoreply.CallSubscriptionResolver
import com.replymate.reply_mate.services.AutoReplyForegroundService
import java.util.concurrent.TimeUnit
import kotlinx.coroutines.launch
import kotlinx.coroutines.delay

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
import com.replymate.reply_mate.autoreply.CallStateStore

/**
 * Tracks [TelephonyManager.ACTION_PHONE_STATE_CHANGED] and maps transitions to
 * one of 7 [AutoReplyEvent] types.
 */
class CallStateReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        kotlinx.coroutines.CoroutineScope(kotlinx.coroutines.Dispatchers.IO).launch {
            try {
                onReceiveImpl(context, intent)
                // Keep the receiver process alive for 4 seconds to ensure Firestore async sync
                kotlinx.coroutines.delay(4000)
            } catch (t: Throwable) {
                Log.e(TAG, "onReceive failed", t)
            } finally {
                pendingResult.finish()
            }
        }
    }


    private fun onReceiveImpl(context: Context, intent: Intent) {
        val configStore = AutoReplyConfigStore(context)
        
        // 1. Real-time fallback sync from Firestore
        try {
            if (FirebaseApp.getApps(context).isEmpty()) {
                FirebaseApp.initializeApp(context.applicationContext)
            }
            val uid = FirebaseAuth.getInstance().currentUser?.phoneNumber?.takeIf { it.isNotEmpty() }
                ?: configStore.getUserId()
            if (!uid.isNullOrEmpty()) {
                val db = FirebaseFirestore.getInstance()
                val task = db.collection("users").document(uid).get()
                val doc = Tasks.await(task, 2500, TimeUnit.MILLISECONDS)
                if (doc != null && doc.exists()) {
                    val isBlocked = doc.getBoolean("isBlocked") == true
                    val isApproved = doc.getBoolean("isApproved") == true
                    
                    val subEndTimestamp = doc.getTimestamp("subscriptionEnd")
                    val subEndMs = subEndTimestamp?.toDate()?.time ?: 0L
                    
                    // Check if expired in Firestore
                    val isExpired = subEndMs > 0L && System.currentTimeMillis() > subEndMs
                    val nextPlanDur = doc.getLong("nextPlanDurationDays")?.toInt() ?: 0
                    
                    var finalBlocked = isBlocked || !isApproved
                    if (isExpired) {
                        if (nextPlanDur > 0) {
                            val newSubEndMs = subEndMs + nextPlanDur * 24L * 60L * 60L * 1000L
                            configStore.setSubEndTime(newSubEndMs)
                            configStore.setNextPlanDurationDays(0)
                            finalBlocked = false
                        } else {
                            finalBlocked = true
                        }
                    } else {
                        configStore.setSubEndTime(subEndMs)
                        configStore.setNextPlanDurationDays(nextPlanDur)
                    }
                    
                    configStore.setBlocked(finalBlocked)
                    Log.d(TAG, "Real-time background sync from Firestore successful: blocked=$finalBlocked subEndMs=$subEndMs nextPlanDur=$nextPlanDur")
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Real-time background sync from Firestore failed/timed out: ${e.message}")
        }

        if (configStore.getBlocked()) {
            AutoReplyForegroundService.stop(context)
            return
        }
        if (intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) return
        if (!configStore.isEnabledFailSafe()) {
            Log.d(TAG, "Blocked call event: autoReplyEnabled=false")
            return
        }

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE) ?: return
        val store = CallStateStore(context)
        // Read prevState from SharedPreferences (survives process death between calls)
        val prevState = store.lastPhoneState
        val incoming = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        val intentSub = CallSubscriptionResolver.subscriptionIdFromPhoneStateIntent(intent)
        if (intentSub != null) {
            store.lastCallSubscriptionId = intentSub
        }

        Log.d(
            TAG,
            "Call state event: state=$state prevState=$prevState incoming=$incoming " +
                "wasRinging=${store.wasRinging} wasOffhook=${store.wasOffhook} isOnCall=${store.isOnCall} " +
                "wasOutgoing=${store.wasOutgoing} intentSub=$intentSub lastSub=${store.lastCallSubscriptionId}"
        )

        when (state) {
            TelephonyManager.EXTRA_STATE_RINGING -> {
                if (store.isOnCall) {
                    Log.d(TAG, "Busy condition: RINGING while already OFFHOOK → BUSY_CALL")
                    val sub = intentSub ?: store.lastCallSubscriptionId
                    AutoReplyEngine.handleEvent(
                        context,
                        AutoReplyEvent.BUSY_CALL,
                        incoming,
                        sub
                    )
                    store.reset()
                    // Persist the new state before returning early
                    store.lastPhoneState = state
                    return
                }
                // Record when this call started ringing so freshness check is
                // anchored to this call, not a fixed 30 s window from IDLE time.
                store.ringingStartedAt = System.currentTimeMillis()
                store.incomingNumber = incoming
                store.wasRinging = true
                store.wasOffhook = false
                Log.d(TAG, "Transition: RINGING incomingNumber=${store.incomingNumber}")
            }

            TelephonyManager.EXTRA_STATE_OFFHOOK -> {
                store.isOnCall = true
                if (prevState == TelephonyManager.EXTRA_STATE_IDLE && !store.wasRinging) {
                    store.wasOutgoing = true
                    Log.d(TAG, "Detected OUTGOING call start (IDLE->OFFHOOK)")
                }
                if (!incoming.isNullOrBlank()) {
                    store.incomingNumber = incoming
                }
                if (store.wasRinging) {
                    store.wasOffhook = true
                    Log.d(TAG, "Transition: OFFHOOK while ringing")
                }
            }

            TelephonyManager.EXTRA_STATE_IDLE -> {
                store.isOnCall = false
                store.callIdleAt = System.currentTimeMillis()

                // Staleness guard: if RINGING was never recorded (ringingStartedAt == 0)
                // this is an orphan IDLE from a previous call whose state was never set.
                // Or if too much time has passed since RINGING, the call is stale —
                // discard to prevent a Doze-delayed broadcast from firing a late SMS.
                val ringingAt = store.ringingStartedAt
                val idleAt = store.callIdleAt
                val callAgeMs = if (ringingAt > 0L) idleAt - ringingAt else Long.MAX_VALUE

                if (store.wasOutgoing || store.wasRinging) {
                    if (ringingAt == 0L) {
                        Log.w(TAG, "Orphan IDLE: wasRinging/wasOutgoing=true but ringingStartedAt=0. Discarding stale event.")
                    } else if (callAgeMs > MAX_CALL_AGE_MS) {
                        Log.w(
                            TAG,
                            "Stale IDLE discarded: call age=${callAgeMs / 1000}s exceeds ${MAX_CALL_AGE_MS / 1000}s limit. " +
                            "Android likely batched this broadcast (Doze mode). " +
                            "ringingAt=$ringingAt idleAt=$idleAt"
                        )
                    } else if (store.wasOutgoing) {
                        handleOutgoingCallEnded(context, store)
                    } else {
                        handleIncomingCallEnded(context, incoming, store)
                    }
                }

                // reset() uses synchronous commit() — state is fully cleared before
                // any subsequent RINGING broadcast is handled.
                store.reset()
            }
        }
        // Persist state to SharedPreferences so it survives process death
        store.lastPhoneState = state
    }

    private fun handleOutgoingCallEnded(context: Context, store: CallStateStore) {
        val callInfo = getRecentCallLogWithRetry(context, store.ringingStartedAt)
        val timestamp = callInfo?.timestamp ?: 0L
        // Use ringingStartedAt as fallback dedup key when call log isn't written yet.
        // Prevents the same call from being processed twice if IDLE fires twice.
        val dedupKey = if (timestamp > 0L) timestamp else store.ringingStartedAt
        if (dedupKey > 0 && dedupKey == store.lastProcessedCallTimestamp) {
            Log.d(TAG, "Deduplication: Outgoing call already processed for key=$dedupKey")
            return
        }

        val resolvedNumber = store.outgoingNumber ?: callInfo?.number
        val sub = store.outgoingSubscriptionId
            ?: callInfo?.subscriptionId
            ?: store.lastCallSubscriptionId
            ?: CallSubscriptionResolver.getLatestCallLogSubscriptionId(context)

        if (callInfo != null && callInfo.type == CallLog.Calls.OUTGOING_TYPE && callInfo.duration > 0) {
            Log.d(TAG, "Outgoing call ANSWERED: duration=${callInfo.duration} phone=$resolvedNumber")
            val handled = AutoReplyEngine.handleEvent(
                context,
                AutoReplyEvent.OUTGOING_ANSWERED,
                resolvedNumber,
                sub
            )
            if (handled && dedupKey > 0) store.lastProcessedCallTimestamp = dedupKey
        } else {
            Log.d(TAG, "Outgoing call UNANSWERED: duration=${callInfo?.duration ?: 0} phone=$resolvedNumber")
            val handled = AutoReplyEngine.handleEvent(
                context,
                AutoReplyEvent.OUTGOING_UNANSWERED,
                resolvedNumber,
                sub
            )
            if (handled && dedupKey > 0) store.lastProcessedCallTimestamp = dedupKey
        }
    }

    private fun handleIncomingCallEnded(context: Context, intentIncoming: String?, store: CallStateStore) {
        val callInfo = getRecentCallLogWithRetry(context, store.ringingStartedAt)
        val timestamp = callInfo?.timestamp ?: 0L
        // Use ringingStartedAt as fallback dedup key when call log isn't written yet.
        // Prevents the same call from being processed twice if IDLE fires twice.
        val dedupKey = if (timestamp > 0L) timestamp else store.ringingStartedAt
        if (dedupKey > 0 && dedupKey == store.lastProcessedCallTimestamp) {
            Log.d(TAG, "Deduplication: Incoming call already processed for key=$dedupKey")
            return
        }

        val resolvedNumber = store.incomingNumber ?: intentIncoming ?: callInfo?.number
        val subForIdle = store.lastCallSubscriptionId
            ?: callInfo?.subscriptionId
            ?: CallSubscriptionResolver.getLatestCallLogSubscriptionId(context)

        Log.d(
            TAG,
            "Transition: IDLE resolvedNumber=$resolvedNumber callLogType=${callInfo?.type} subForIdle=$subForIdle ts=$timestamp"
        )

        val answeredByLogFallback = !store.wasOffhook &&
            callInfo?.type == CallLog.Calls.INCOMING_TYPE

        val event = when {
            store.wasOffhook || answeredByLogFallback -> AutoReplyEvent.CALL_ANSWERED
            callInfo != null && CallSubscriptionResolver.isRejectedType(callInfo.type) -> AutoReplyEvent.REJECTED_CALL
            else -> AutoReplyEvent.MISSED_CALL
        }

        Log.d(TAG, "Detected $event flow for number=$resolvedNumber")
        val handled = AutoReplyEngine.handleEvent(
            context,
            event,
            resolvedNumber,
            subForIdle
        )
        if (handled && dedupKey > 0) store.lastProcessedCallTimestamp = dedupKey
    }

    /**
     * Returns the most recent call-log entry IF it belongs to the current call.
     * "Belongs to current call" means its timestamp is >= [ringingStartedAt], i.e.
     * it was created after this call started ringing — not a stale entry from a
     * PREVIOUS call.  Without anchoring to [ringingStartedAt] a P1 call-log entry
     * written slowly (e.g. 28 s later) could appear "fresh" (within 30 s of now)
     * during P2's IDLE handling and bleed P1's number into P2's SMS.
     *
     * Falls back to the old 30-s-from-now window only when ringingStartedAt is 0
     * (safety net for unexpected states).
     */
    private fun getRecentCallLogWithRetry(
        context: Context,
        ringingStartedAt: Long
    ): CallSubscriptionResolver.RecentCallInfo? {
        // Use ringing-start as the lower bound so only entries created DURING or
        // AFTER this call are accepted.  Allow a 2 s margin for clock jitter.
        val cutoff = if (ringingStartedAt > 0L) ringingStartedAt - 2_000L
                     else System.currentTimeMillis() - 30_000L

        fun isFresh(info: CallSubscriptionResolver.RecentCallInfo) = info.timestamp >= cutoff

        // First attempt — no delay
        var callInfo = CallSubscriptionResolver.getLatestCallLogEntry(context)
        if (callInfo != null && isFresh(callInfo)) return callInfo

        // Second attempt after short delay
        try { Thread.sleep(200) } catch (_: Exception) {}
        callInfo = CallSubscriptionResolver.getLatestCallLogEntry(context)
        if (callInfo != null && isFresh(callInfo)) return callInfo

        // Third attempt after another short delay
        try { Thread.sleep(300) } catch (_: Exception) {}
        callInfo = CallSubscriptionResolver.getLatestCallLogEntry(context)
        if (callInfo != null && isFresh(callInfo)) return callInfo

        // No fresh entry after all retries — return null so we never use a stale number.
        Log.d(TAG, "getRecentCallLogWithRetry: no fresh entry for cutoff=$cutoff, returning null")
        return null
    }

    companion object {
        private const val TAG = "ReplyMateCallReceiver"
        /**
         * Maximum time between RINGING and IDLE before we treat the IDLE as stale.
         * 5 minutes is more than enough for any real call (answered, missed, or rejected).
         * A delayed IDLE arriving more than 5 min after RINGING is almost certainly
         * an Android Doze-batched broadcast from a much older call.
         */
        private const val MAX_CALL_AGE_MS = 5L * 60 * 1000  // 5 minutes
    }
}
