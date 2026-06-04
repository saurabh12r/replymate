package com.replymate.reply_mate.autoreply

import android.content.Context
import org.json.JSONObject

class AutoReplyConfigStore(context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun setBlocked(value: Boolean) {
        prefs.edit()
            .putBoolean(KEY_IS_BLOCKED, value)
            .commit()  // synchronous: must survive immediate process death
    }

    fun getBlocked(): Boolean {
        return try {
            val isExplicitlyBlocked = prefs.getBoolean(KEY_IS_BLOCKED, false)
            if (isExplicitlyBlocked) return true
            
            // Background check for subscription expiry
            var subEndMs = getSubEndTime()
            if (subEndMs > 0 && System.currentTimeMillis() > subEndMs) {
                // EXPIRED! But check if we have a next plan queued
                val nextPlanDurationDays = getNextPlanDurationDays()
                if (nextPlanDurationDays > 0) {
                    // Autonomously roll over and update expiration time
                    val newSubEndMs = subEndMs + nextPlanDurationDays * 24L * 60L * 60L * 1000L
                    setSubEndTime(newSubEndMs)
                    setNextPlanDurationDays(0) // Consume the queued plan
                    android.util.Log.d("ReplyMateConfigStore", "Autonomously rolled over to next plan. New end: $newSubEndMs")
                    return false // Not blocked!
                }
                return true
            }
            false
        } catch (_: Exception) {
            false
        }
    }

    fun setEnabled(enabled: Boolean) {
        prefs.edit()
            .putBoolean(KEY_MASTER_ENABLED, enabled)
            .putBoolean(KEY_AUTO_REPLY_ENABLED, enabled)
            .putBoolean(LEGACY_KEY_AUTO_REPLY_ENABLED, enabled)
            .commit()  // synchronous: must survive immediate process death
    }

    fun setReplyRules(
        replyOnMissedCall: Boolean,
        replyOnIncomingCall: Boolean,
        replyOnWhatsappCall: Boolean,
        replyOnBusyCall: Boolean,
        replyOnRejectedCall: Boolean,
        replyOnOutgoingAnswered: Boolean,
        replyOnOutgoingUnanswered: Boolean
    ) {
        prefs.edit()
            .putBoolean(KEY_REPLY_MISSED_CALL, replyOnMissedCall)
            .putBoolean(KEY_REPLY_INCOMING_CALL, replyOnIncomingCall)
            .putBoolean(KEY_REPLY_WHATSAPP_CALL, replyOnWhatsappCall)
            .putBoolean(KEY_REPLY_BUSY_CALL, replyOnBusyCall)
            .putBoolean(KEY_REPLY_REJECTED_CALL, replyOnRejectedCall)
            .putBoolean(KEY_REPLY_OUTGOING_ANSWERED, replyOnOutgoingAnswered)
            .putBoolean(KEY_REPLY_OUTGOING_UNANSWERED, replyOnOutgoingUnanswered)
            .putBoolean(KEY_REPLY_ON_MISSED_CALL, replyOnMissedCall)
            .putBoolean(KEY_REPLY_ON_CALL_ANSWERED, replyOnIncomingCall)
            .putBoolean(KEY_REPLY_ON_WHATSAPP_CALL, replyOnWhatsappCall)
            .apply()
    }

    fun setCustomMessages(
        missedCallMessage: String,
        incomingCallMessage: String,
        whatsappCallMessage: String,
        busyCallMessage: String,
        rejectedCallMessage: String,
        outgoingAnsweredMessage: String,
        outgoingUnansweredMessage: String
    ) {
        prefs.edit()
            .putString(KEY_MSG_MISSED_CALL, normalizeMessage(missedCallMessage, DEFAULT_MISSED_CALL_MESSAGE))
            .putString(KEY_MSG_INCOMING_CALL, normalizeMessage(incomingCallMessage, DEFAULT_INCOMING_CALL_MESSAGE))
            .putString(KEY_MSG_WHATSAPP_CALL, normalizeMessage(whatsappCallMessage, DEFAULT_WHATSAPP_CALL_MESSAGE))
            .putString(KEY_MSG_BUSY_CALL, normalizeMessage(busyCallMessage, DEFAULT_BUSY_CALL_MESSAGE))
            .putString(KEY_MSG_REJECTED_CALL, normalizeMessage(rejectedCallMessage, DEFAULT_REJECTED_CALL_MESSAGE))
            .putString(KEY_MSG_OUTGOING_ANSWERED, normalizeMessage(outgoingAnsweredMessage, DEFAULT_OUTGOING_ANSWERED_MESSAGE))
            .putString(KEY_MSG_OUTGOING_UNANSWERED, normalizeMessage(outgoingUnansweredMessage, DEFAULT_OUTGOING_UNANSWERED_MESSAGE))
            .apply()
    }

    fun setConfig(
        autoReplyEnabled: Boolean,
        replyOnCallAnswered: Boolean,
        replyOnMissedCall: Boolean,
        replyOnWhatsappCall: Boolean,
        replyOnBusyCall: Boolean,
        replyOnRejectedCall: Boolean,
        replyOnOutgoingAnswered: Boolean,
        replyOnOutgoingUnanswered: Boolean,
        useTimeRange: Boolean,
        startMinutes: Int,
        endMinutes: Int,
        defaultReplyMessage: String
    ) {
        prefs.edit()
            .putBoolean(KEY_MASTER_ENABLED, autoReplyEnabled)
            .putBoolean(KEY_AUTO_REPLY_ENABLED, autoReplyEnabled)
            .putBoolean(LEGACY_KEY_AUTO_REPLY_ENABLED, autoReplyEnabled)
            .putBoolean(KEY_REPLY_ON_CALL_ANSWERED, replyOnCallAnswered)
            .putBoolean(KEY_REPLY_ON_MISSED_CALL, replyOnMissedCall)
            .putBoolean(KEY_REPLY_ON_WHATSAPP_CALL, replyOnWhatsappCall)
            .putBoolean(KEY_REPLY_INCOMING_CALL, replyOnCallAnswered)
            .putBoolean(KEY_REPLY_MISSED_CALL, replyOnMissedCall)
            .putBoolean(KEY_REPLY_WHATSAPP_CALL, replyOnWhatsappCall)
            .putBoolean(KEY_REPLY_BUSY_CALL, replyOnBusyCall)
            .putBoolean(KEY_REPLY_REJECTED_CALL, replyOnRejectedCall)
            .putBoolean(KEY_REPLY_OUTGOING_ANSWERED, replyOnOutgoingAnswered)
            .putBoolean(KEY_REPLY_OUTGOING_UNANSWERED, replyOnOutgoingUnanswered)
            .putBoolean(KEY_USE_TIME_RANGE, useTimeRange)
            .putInt(KEY_START_MINUTES, startMinutes)
            .putInt(KEY_END_MINUTES, endMinutes)
            .putString(KEY_DEFAULT_REPLY_MESSAGE, defaultReplyMessage)
            .apply()
    }

    fun isEnabled(): Boolean {
        // Default is FALSE — if the key is missing (fresh install, cleared data, new process)
        // the engine must be OFF until the user explicitly enables it via the dashboard.
        // An accidental default of true caused SMS to fire even when the switch was off.
        return if (prefs.contains(KEY_MASTER_ENABLED)) {
            prefs.getBoolean(KEY_MASTER_ENABLED, false)
        } else if (prefs.contains(KEY_AUTO_REPLY_ENABLED)) {
            prefs.getBoolean(KEY_AUTO_REPLY_ENABLED, false)
        } else {
            prefs.getBoolean(LEGACY_KEY_AUTO_REPLY_ENABLED, false)
        }
    }

    fun isEnabledFailSafe(): Boolean {
        return try {
            if (getBlocked()) return false
            isEnabled()
        } catch (_: Exception) {
            false
        }
    }
    fun getAutoReplyEnabled(): Boolean = isEnabled()
    fun setAutoReplyEnabled(value: Boolean) = setEnabled(value)
    fun getReplyMissedCall(): Boolean = replyOnMissedCall()
    fun getReplyIncomingCall(): Boolean = replyOnCallAnswered()
    fun getReplyWhatsappCall(): Boolean = replyOnWhatsappCall()
    fun getReplyBusyCall(): Boolean = replyOnBusyCall()
    fun getReplyRejectedCall(): Boolean = replyOnRejectedCall()
    fun getReplyOutgoingAnswered(): Boolean = replyOnOutgoingAnswered()
    fun getReplyOutgoingUnanswered(): Boolean = replyOnOutgoingUnanswered()
    fun getThrottleEnabled(): Boolean = throttleEnabled()
    fun getMissedCallMessage(): String = missedCallMessage()
    fun getIncomingCallMessage(): String = incomingCallMessage()
    fun getWhatsappCallMessage(): String = whatsappCallMessage()
    fun getBusyCallMessage(): String = busyCallMessage()
    fun getRejectedCallMessage(): String = rejectedCallMessage()
    fun getOutgoingAnsweredMessage(): String = outgoingAnsweredMessage()
    fun getOutgoingUnansweredMessage(): String = outgoingUnansweredMessage()

    fun replyOnCallAnswered(): Boolean {
        return if (prefs.contains(KEY_REPLY_INCOMING_CALL)) {
            prefs.getBoolean(KEY_REPLY_INCOMING_CALL, false)
        } else {
            prefs.getBoolean(KEY_REPLY_ON_CALL_ANSWERED, false)
        }
    }
    fun replyOnMissedCall(): Boolean {
        return if (prefs.contains(KEY_REPLY_MISSED_CALL)) {
            prefs.getBoolean(KEY_REPLY_MISSED_CALL, true)
        } else {
            prefs.getBoolean(KEY_REPLY_ON_MISSED_CALL, true)
        }
    }
    fun replyOnWhatsappCall(): Boolean {
        return if (prefs.contains(KEY_REPLY_WHATSAPP_CALL)) {
            prefs.getBoolean(KEY_REPLY_WHATSAPP_CALL, true)
        } else {
            prefs.getBoolean(KEY_REPLY_ON_WHATSAPP_CALL, true)
        }
    }

    fun replyOnBusyCall(): Boolean {
        return prefs.getBoolean(KEY_REPLY_BUSY_CALL, false)
    }

    fun replyOnRejectedCall(): Boolean {
        return prefs.getBoolean(KEY_REPLY_REJECTED_CALL, false)
    }

    fun replyOnOutgoingAnswered(): Boolean {
        return prefs.getBoolean(KEY_REPLY_OUTGOING_ANSWERED, false)
    }

    fun replyOnOutgoingUnanswered(): Boolean {
        return prefs.getBoolean(KEY_REPLY_OUTGOING_UNANSWERED, false)
    }

    fun useTimeRange(): Boolean = prefs.getBoolean(KEY_USE_TIME_RANGE, false)
    fun startMinutes(): Int = prefs.getInt(KEY_START_MINUTES, 9 * 60)
    fun endMinutes(): Int = prefs.getInt(KEY_END_MINUTES, 21 * 60)
    fun defaultReplyMessage(): String =
        prefs.getString(KEY_DEFAULT_REPLY_MESSAGE, DEFAULT_MESSAGE) ?: DEFAULT_MESSAGE

    fun missedCallMessage(): String {
        val value = prefs.getString(KEY_MSG_MISSED_CALL, DEFAULT_MISSED_CALL_MESSAGE)?.trim()
        return if (value.isNullOrEmpty()) DEFAULT_MISSED_CALL_MESSAGE else value
    }

    fun incomingCallMessage(): String {
        val value = prefs.getString(KEY_MSG_INCOMING_CALL, DEFAULT_INCOMING_CALL_MESSAGE)?.trim()
        return if (value.isNullOrEmpty()) DEFAULT_INCOMING_CALL_MESSAGE else value
    }

    fun whatsappCallMessage(): String {
        val value = prefs.getString(KEY_MSG_WHATSAPP_CALL, DEFAULT_WHATSAPP_CALL_MESSAGE)?.trim()
        return if (value.isNullOrEmpty()) DEFAULT_WHATSAPP_CALL_MESSAGE else value
    }

    fun busyCallMessage(): String {
        val value = prefs.getString(KEY_MSG_BUSY_CALL, DEFAULT_BUSY_CALL_MESSAGE)?.trim()
        return if (value.isNullOrEmpty()) DEFAULT_BUSY_CALL_MESSAGE else value
    }

    fun rejectedCallMessage(): String {
        val value = prefs.getString(KEY_MSG_REJECTED_CALL, DEFAULT_REJECTED_CALL_MESSAGE)?.trim()
        return if (value.isNullOrEmpty()) DEFAULT_REJECTED_CALL_MESSAGE else value
    }

    fun outgoingAnsweredMessage(): String {
        val value = prefs.getString(KEY_MSG_OUTGOING_ANSWERED, DEFAULT_OUTGOING_ANSWERED_MESSAGE)?.trim()
        return if (value.isNullOrEmpty()) DEFAULT_OUTGOING_ANSWERED_MESSAGE else value
    }

    fun outgoingUnansweredMessage(): String {
        val value = prefs.getString(KEY_MSG_OUTGOING_UNANSWERED, DEFAULT_OUTGOING_UNANSWERED_MESSAGE)?.trim()
        return if (value.isNullOrEmpty()) DEFAULT_OUTGOING_UNANSWERED_MESSAGE else value
    }

    fun messageForEvent(event: AutoReplyEvent): String {
        return when (event) {
            AutoReplyEvent.MISSED_CALL -> missedCallMessage()
            AutoReplyEvent.CALL_ANSWERED -> incomingCallMessage()
            AutoReplyEvent.MISSED_WHATSAPP_CALL -> whatsappCallMessage()
            AutoReplyEvent.BUSY_CALL -> busyCallMessage()
            AutoReplyEvent.REJECTED_CALL -> rejectedCallMessage()
            AutoReplyEvent.OUTGOING_ANSWERED -> outgoingAnsweredMessage()
            AutoReplyEvent.OUTGOING_UNANSWERED -> outgoingUnansweredMessage()
        }
    }

    fun toMap(): Map<String, Any> {
        return mapOf(
            "autoReplyEnabled" to isEnabled(),
            "replyOnCallAnswered" to replyOnCallAnswered(),
            "replyOnMissedCall" to replyOnMissedCall(),
            "replyOnWhatsappCall" to replyOnWhatsappCall(),
            "replyOnBusyCall" to replyOnBusyCall(),
            "replyOnRejectedCall" to replyOnRejectedCall(),
            "replyOnOutgoingAnswered" to replyOnOutgoingAnswered(),
            "replyOnOutgoingUnanswered" to replyOnOutgoingUnanswered(),
            "throttleEnabled" to throttleEnabled(),
            "msgMissedCall" to missedCallMessage(),
            "msgIncomingCall" to incomingCallMessage(),
            "msgWhatsappCall" to whatsappCallMessage(),
            "msgBusyCall" to busyCallMessage(),
            "msgRejectedCall" to rejectedCallMessage(),
            "msgOutgoingAnswered" to outgoingAnsweredMessage(),
            "msgOutgoingUnanswered" to outgoingUnansweredMessage(),
            "useTimeRange" to useTimeRange(),
            "startMinutes" to startMinutes(),
            "endMinutes" to endMinutes(),
            "defaultReplyMessage" to defaultReplyMessage()
        )
    }

    fun toJson(): String = JSONObject(toMap()).toString()

    companion object {
        const val PREFS_NAME = "replymate_auto_reply_prefs"
        const val KEY_IS_BLOCKED = "is_blocked"
        const val KEY_MASTER_ENABLED = "auto_reply_enabled"
        const val KEY_AUTO_REPLY_ENABLED = "autoReplyEnabled"
        const val LEGACY_KEY_AUTO_REPLY_ENABLED = "auto_reply_enabled"
        const val KEY_REPLY_MISSED_CALL = "reply_missed_call"
        const val KEY_REPLY_INCOMING_CALL = "reply_incoming_call"
        const val KEY_REPLY_WHATSAPP_CALL = "reply_whatsapp_call"
        const val KEY_REPLY_BUSY_CALL = "reply_busy_call"
        const val KEY_REPLY_REJECTED_CALL = "reply_rejected_call"
        const val KEY_REPLY_OUTGOING_ANSWERED = "reply_outgoing_answered"
        const val KEY_REPLY_OUTGOING_UNANSWERED = "reply_outgoing_unanswered"
        const val KEY_REPLY_ON_CALL_ANSWERED = "reply_on_call_answered"
        const val KEY_REPLY_ON_MISSED_CALL = "reply_on_missed_call"
        const val KEY_REPLY_ON_WHATSAPP_CALL = "reply_on_whatsapp_call"
        const val KEY_MSG_MISSED_CALL = "msg_missed_call"
        const val KEY_MSG_INCOMING_CALL = "msg_incoming_call"
        const val KEY_MSG_WHATSAPP_CALL = "msg_whatsapp_call"
        const val KEY_MSG_BUSY_CALL = "msg_busy_call"
        const val KEY_MSG_REJECTED_CALL = "msg_rejected_call"
        const val KEY_MSG_OUTGOING_ANSWERED = "msg_outgoing_answered"
        const val KEY_MSG_OUTGOING_UNANSWERED = "msg_outgoing_unanswered"
        const val KEY_THROTTLE_ENABLED = "throttle_enabled"
        const val KEY_THROTTLE_DURATION = "throttle_duration"
        const val KEY_USE_TIME_RANGE = "use_time_range"
        const val KEY_START_MINUTES = "start_minutes"
        const val KEY_END_MINUTES = "end_minutes"
        const val KEY_DEFAULT_REPLY_MESSAGE = "default_reply_message"
        const val KEY_USER_ID = "user_id"
        const val KEY_SUB_END_TIME = "sub_end_time"
        const val KEY_NEXT_PLAN_DURATION = "next_plan_duration_days"
        const val DEFAULT_MISSED_CALL_MESSAGE = "Sorry, I missed your call. I'll call you back."
        const val DEFAULT_INCOMING_CALL_MESSAGE = "Thanks for calling! I'm currently busy, will get back to you soon."
        const val DEFAULT_WHATSAPP_CALL_MESSAGE = "Sorry, I missed your WhatsApp call."
        const val DEFAULT_BUSY_CALL_MESSAGE = "I'm on another call right now. I'll call you back."
        const val DEFAULT_REJECTED_CALL_MESSAGE = "Sorry, I can't take your call right now. I'll get back to you shortly."
        const val DEFAULT_OUTGOING_ANSWERED_MESSAGE = "Thanks for picking up! Just following up via SMS as well."
        const val DEFAULT_OUTGOING_UNANSWERED_MESSAGE = "I tried calling you but couldn't reach you. Please call me back when free."
        const val DEFAULT_MESSAGE = "Thanks for calling. I'll get back to you shortly."
    }

    fun throttleEnabled(): Boolean {
        return prefs.getBoolean(KEY_THROTTLE_ENABLED, true)
    }

    fun setThrottleEnabled(enabled: Boolean) {
        prefs.edit()
            .putBoolean(KEY_THROTTLE_ENABLED, enabled)
            .apply()
    }

    fun throttleDuration(): Int {
        return prefs.getInt(KEY_THROTTLE_DURATION, 1)
    }

    fun setThrottleDuration(hours: Int) {
        prefs.edit()
            .putInt(KEY_THROTTLE_DURATION, hours)
            .apply()
    }

    fun getUserId(): String? {
        return prefs.getString(KEY_USER_ID, null)
    }

    fun setUserId(userId: String?) {
        prefs.edit()
            .putString(KEY_USER_ID, userId)
            .apply()
    }

    fun getSubEndTime(): Long {
        return prefs.getLong(KEY_SUB_END_TIME, 0L)
    }

    fun setSubEndTime(endTimeMs: Long) {
        prefs.edit()
            .putLong(KEY_SUB_END_TIME, endTimeMs)
            .apply()
    }

    fun getNextPlanDurationDays(): Int {
        return prefs.getInt(KEY_NEXT_PLAN_DURATION, 0)
    }

    fun setNextPlanDurationDays(days: Int) {
        prefs.edit()
            .putInt(KEY_NEXT_PLAN_DURATION, days)
            .apply()
    }

    private fun normalizeMessage(value: String?, fallback: String): String {
        val normalized = value?.trim()
        return if (normalized.isNullOrEmpty()) fallback else normalized
    }
}
