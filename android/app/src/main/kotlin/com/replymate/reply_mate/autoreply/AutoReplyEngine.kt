package com.replymate.reply_mate.autoreply

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.text.TextUtils
import android.util.Log
import androidx.core.content.ContextCompat
import com.replymate.reply_mate.activity.ActivityEventType
import com.replymate.reply_mate.activity.ActivityLogPendingStore
import com.replymate.reply_mate.events.ReplyMateEventEmitter
import com.replymate.reply_mate.sms.SmsSendHelper
import java.util.Calendar
import java.util.UUID

enum class AutoReplyEvent {
    CALL_ANSWERED,
    MISSED_CALL,
    MISSED_WHATSAPP_CALL,
    BUSY_CALL,
    OUTGOING_CALL
}

object AutoReplyEngine {
    private const val TAG = "ReplyMateAutoReply"
    /** Cooldown per phone (across ALL events), restart-proof via SharedPreferences. */
    private const val THROTTLE_WINDOW_MS = 60 * 60 * 1000L // 1 hour

    // New (vNext): per-phone cooldown.
    private const val KEY_LAST_REPLY_AT_PHONE_PREFIX = "last_reply_at_phone_"

    // Legacy (pre vNext): single last phone+event cooldown.
    private const val LEGACY_KEY_LAST_REPLY_PHONE = "last_reply_phone"
    private const val LEGACY_KEY_LAST_REPLY_EVENT = "last_reply_event"
    private const val LEGACY_KEY_LAST_REPLY_AT = "last_reply_at"

    /**
     * Creates activity log + dispatches SMS when allowed. Logs and events are centralized here
     * so receivers stay thin (restart-safe throttling in prefs).
     */
    fun handleEvent(
        context: Context,
        event: AutoReplyEvent,
        rawPhoneNumber: String?,
    ): Boolean {
        val config = AutoReplyConfigStore(context)
        Log.d(TAG, "Event detected: event=$event rawPhone=$rawPhoneNumber")
        if (!config.isEnabledFailSafe()) {
            Log.d(TAG, "Blocked: autoReplyEnabled=false")
            return false
        }
        if (!isEventEnabled(config, event)) {
            Log.d(TAG, "Blocked: event toggle disabled for $event")
            return false
        }
        if (!isWithinActiveWindow(config)) {
            Log.d(
                TAG,
                "Blocked: outside active window start=${config.startMinutes()} end=${config.endMinutes()}"
            )
            return false
        }
        if (!hasSmsPermission(context)) {
            Log.d(TAG, "Blocked: SEND_SMS permission missing")
            emitUiEvent(
                mapOf(
                    "kind" to "blocked",
                    "reason" to "missing_sms_permission",
                    "event" to event.name,
                    "timestamp" to System.currentTimeMillis()
                )
            )
            return false
        }

        val phoneNumber = sanitizePhone(rawPhoneNumber) ?: return false
        Log.d(TAG, "Phone extracted: normalizedPhone=$phoneNumber")
        val digitsForFilter = ContactPhoneNormalize.digitsOnly(phoneNumber)
        if (!ContactFilterNativeStore.shouldSendSms(context.applicationContext, digitsForFilter)) {
            Log.d(TAG, "Blocked: contact filter")
            return false
        }
        val message = config.messageForEvent(event).trim()
        if (message.isEmpty()) {
            Log.d(TAG, "Blocked: empty auto-reply message")
            return false
        }

        if (config.throttleEnabled() && shouldThrottle(context, phoneNumber)) {
            Log.d(TAG, "Blocked: throttled for phone=$phoneNumber event=$event")
            emitUiEvent(
                mapOf(
                    "kind" to "throttled",
                    "event" to event.name,
                    "phone" to phoneNumber,
                    "timestamp" to System.currentTimeMillis()
                )
            )
            return false
        }

        val logId = UUID.randomUUID().toString()
        val activityType = activityTypeFor(event)
        ActivityLogPendingStore.appendCall(
            context.applicationContext,
            id = logId,
            type = activityType,
            phone = phoneNumber,
            name = "",
            replied = false,
            messageSent = message
        )

        emitUiEvent(
            mapOf(
                "kind" to "dispatching",
                "event" to event.name,
                "phone" to phoneNumber,
                "messagePreview" to message.take(120),
                "logId" to logId,
                "timestamp" to System.currentTimeMillis()
            )
        )

        return try {
            val smsManager = resolveSmsManager()
            val parts = smsManager.divideMessage(message)
            Log.d(
                TAG,
                "Calling sendSms: phone=$phoneNumber event=$event parts=${parts.size} logId=$logId"
            )
            SmsSendHelper.sendMultipartTextMessageWithSentCallback(
                context,
                smsManager,
                phoneNumber,
                parts,
                logId
            )
            updateThrottleState(context, phoneNumber)
            Log.d(TAG, "SMS send triggered successfully for phone=$phoneNumber")
            true
        } catch (e: Exception) {
            Log.e(TAG, "SMS send failed for phone=$phoneNumber event=$event", e)
            ActivityLogPendingStore.appendPatchReplied(
                context.applicationContext,
                logId,
                false
            )
            emitUiEvent(
                mapOf(
                    "kind" to "sms_failed",
                    "event" to event.name,
                    "phone" to phoneNumber,
                    "error" to (e.message ?: "unknown"),
                    "timestamp" to System.currentTimeMillis()
                )
            )
            false
        }
    }

    private fun activityTypeFor(event: AutoReplyEvent): Int {
        return when (event) {
            AutoReplyEvent.CALL_ANSWERED -> ActivityEventType.INCOMING_CALL
            AutoReplyEvent.MISSED_CALL -> ActivityEventType.MISSED_CALL
            AutoReplyEvent.MISSED_WHATSAPP_CALL -> ActivityEventType.WHATSAPP_CALL
            AutoReplyEvent.BUSY_CALL -> ActivityEventType.BUSY_CALL
            AutoReplyEvent.OUTGOING_CALL -> ActivityEventType.OUTGOING_CALL
        }
    }

    private fun emitUiEvent(map: Map<String, Any?>) {
        ReplyMateEventEmitter.emit(map)
    }

    private fun resolveSmsManager(): SmsManager {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val subId = SubscriptionManager.getDefaultSmsSubscriptionId()
            if (subId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                return SmsManager.getSmsManagerForSubscriptionId(subId)
            }
        }
        return SmsManager.getDefault()
    }

    private fun hasSmsPermission(context: Context): Boolean {
        return ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.SEND_SMS
        ) == PackageManager.PERMISSION_GRANTED
    }

    private fun isEventEnabled(config: AutoReplyConfigStore, event: AutoReplyEvent): Boolean {
        return when (event) {
            AutoReplyEvent.CALL_ANSWERED -> config.replyOnCallAnswered()
            AutoReplyEvent.MISSED_CALL -> config.replyOnMissedCall()
            AutoReplyEvent.MISSED_WHATSAPP_CALL -> config.replyOnWhatsappCall()
            AutoReplyEvent.BUSY_CALL -> config.replyOnBusyCall()
            AutoReplyEvent.OUTGOING_CALL -> config.replyOnOutgoingCall()
        }
    }

    private fun isWithinActiveWindow(config: AutoReplyConfigStore): Boolean {
        if (!config.useTimeRange()) return true
        val now = Calendar.getInstance()
        val current = now.get(Calendar.HOUR_OF_DAY) * 60 + now.get(Calendar.MINUTE)
        val start = config.startMinutes()
        val end = config.endMinutes()
        if (start == end) return true
        return if (start < end) {
            current in start..end
        } else {
            current >= start || current <= end
        }
    }

    private fun sanitizePhone(phone: String?): String? {
        if (phone.isNullOrBlank()) {
            Log.d(TAG, "Phone extraction failed: phone is null/blank")
            return null
        }
        val normalized = phone.replace(Regex("[^+\\d]"), "")
        if (TextUtils.isEmpty(normalized)) {
            Log.d(TAG, "Phone extraction failed: normalized phone empty from raw=$phone")
            return null
        }
        return normalized
    }

    @Synchronized
    private fun shouldThrottle(context: Context, phone: String): Boolean {
        val prefs = context.getSharedPreferences(AutoReplyConfigStore.PREFS_NAME, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()

        // New: per-phone last-sent timestamp (all events share this).
        val key = KEY_LAST_REPLY_AT_PHONE_PREFIX + phone
        val lastAtForPhone = prefs.getLong(key, 0L)
        if (lastAtForPhone > 0L && now - lastAtForPhone < THROTTLE_WINDOW_MS) {
            return true
        }

        // Migration safety: if previous version sent recently (even for a different event),
        // keep honoring that recent send to avoid spamming right after upgrade.
        val legacyPhone = prefs.getString(LEGACY_KEY_LAST_REPLY_PHONE, null)
        val legacyAt = prefs.getLong(LEGACY_KEY_LAST_REPLY_AT, 0L)
        if (legacyPhone == phone && legacyAt > 0L && now - legacyAt < THROTTLE_WINDOW_MS) {
            return true
        }

        return false
    }

    @Synchronized
    private fun updateThrottleState(context: Context, phone: String) {
        val prefs = context.getSharedPreferences(AutoReplyConfigStore.PREFS_NAME, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        prefs.edit()
            .putLong(KEY_LAST_REPLY_AT_PHONE_PREFIX + phone, now)
            // Also update legacy keys so older readers (if any) remain consistent.
            .putString(LEGACY_KEY_LAST_REPLY_PHONE, phone)
            .putString(LEGACY_KEY_LAST_REPLY_EVENT, "ANY")
            .putLong(LEGACY_KEY_LAST_REPLY_AT, now)
            .apply()
    }
}
