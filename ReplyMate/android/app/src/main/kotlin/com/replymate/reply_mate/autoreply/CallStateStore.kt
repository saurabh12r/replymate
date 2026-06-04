package com.replymate.reply_mate.autoreply

import android.content.Context
import android.telephony.TelephonyManager

/**
 * Persists transient call state across BroadcastReceiver instances.
 * Using SharedPreferences instead of static variables prevents state loss when the process is killed.
 *
 * IMPORTANT: All writes use .commit() (synchronous) so that reset() is guaranteed to complete
 * before the next incoming call's RINGING broadcast is handled. Using .apply() (async) caused
 * a race condition where P2's RINGING event wrote new state that was then wiped by P1's
 * still-pending async reset(), causing P1's SMS to fire during P2's call.
 */
class CallStateStore(context: Context) {
    private val prefs = context.getSharedPreferences("replymate_call_state", Context.MODE_PRIVATE)

    var wasRinging: Boolean
        get() = prefs.getBoolean("was_ringing", false)
        set(value) { prefs.edit().putBoolean("was_ringing", value).commit() }

    var wasOffhook: Boolean
        get() = prefs.getBoolean("was_offhook", false)
        set(value) { prefs.edit().putBoolean("was_offhook", value).commit() }

    var wasOutgoing: Boolean
        get() = prefs.getBoolean("was_outgoing", false)
        set(value) { prefs.edit().putBoolean("was_outgoing", value).commit() }

    var isOnCall: Boolean
        get() = prefs.getBoolean("is_on_call", false)
        set(value) { prefs.edit().putBoolean("is_on_call", value).commit() }

    var incomingNumber: String?
        get() = prefs.getString("incoming_number", null)
        set(value) { prefs.edit().putString("incoming_number", value).commit() }

    var outgoingNumber: String?
        get() = prefs.getString("outgoing_number", null)
        set(value) { prefs.edit().putString("outgoing_number", value).commit() }

    var outgoingSubscriptionId: Int?
        get() {
            val v = prefs.getInt("outgoing_sub_id", -1)
            return if (v == -1) null else v
        }
        set(value) { prefs.edit().putInt("outgoing_sub_id", value ?: -1).commit() }

    var lastCallSubscriptionId: Int?
        get() {
            val v = prefs.getInt("last_call_sub_id", -1)
            return if (v == -1) null else v
        }
        set(value) { prefs.edit().putInt("last_call_sub_id", value ?: -1).commit() }

    var lastProcessedCallTimestamp: Long
        get() = prefs.getLong("last_processed_ts", 0L)
        set(value) { prefs.edit().putLong("last_processed_ts", value).commit() }

    /**
     * Persisted last telephony state so it survives process death between calls.
     * Prevents the static companion variable from resetting to IDLE when Android
     * kills and re-creates the receiver process between two rapid successive calls.
     */
    var lastPhoneState: String
        get() = prefs.getString("last_phone_state", TelephonyManager.EXTRA_STATE_IDLE)
            ?: TelephonyManager.EXTRA_STATE_IDLE
        set(value) { prefs.edit().putString("last_phone_state", value).commit() }

    /**
     * System.currentTimeMillis() captured when RINGING fires for the current call.
     * Used by getRecentCallLogWithRetry() to ensure only call-log entries created
     * DURING or AFTER this call are accepted (prevents P1's slow-written call-log
     * entry from leaking into P2's IDLE resolution).
     */
    var ringingStartedAt: Long
        get() = prefs.getLong("ringing_started_at", 0L)
        set(value) { prefs.edit().putLong("ringing_started_at", value).commit() }

    /**
     * Wall-clock time (System.currentTimeMillis) when the IDLE broadcast was received
     * for the current call. Written at IDLE time — used to detect if the IDLE was
     * held back by Android Doze/battery-saver and delivered hours later, which would
     * make it unsafe to send an auto-reply.
     */
    var callIdleAt: Long
        get() = prefs.getLong("call_idle_at", 0L)
        set(value) { prefs.edit().putLong("call_idle_at", value).commit() }

    /**
     * Atomically clears all per-call flags using synchronous commit().
     * MUST remain synchronous so that the next call's RINGING broadcast never
     * sees stale state from the previous call.
     */
    fun reset() {
        prefs.edit()
            .putBoolean("was_ringing", false)
            .putBoolean("was_offhook", false)
            .putBoolean("was_outgoing", false)
            .putString("incoming_number", null)
            .putString("outgoing_number", null)
            .putInt("outgoing_sub_id", -1)
            .putInt("last_call_sub_id", -1)
            .putLong("ringing_started_at", 0L)
            .putLong("call_idle_at", 0L)
            .commit()  // synchronous — guarantees state is cleared before next RINGING fires
    }
}
