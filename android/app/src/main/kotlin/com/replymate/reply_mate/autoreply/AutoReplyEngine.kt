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
    REJECTED_CALL,
    OUTGOING_ANSWERED,
    OUTGOING_UNANSWERED,
}

object AutoReplyEngine {
    private const val TAG = "ReplyMateAutoReply"
    /** Cooldown per phone (across ALL events and stores), restart-proof via SharedPreferences. */
    private const val THROTTLE_WINDOW_MS = 60 * 60 * 1000L // 1 hour

    private const val KEY_LAST_REPLY_AT_PHONE_PREFIX = "last_reply_at_phone_"

    private const val LEGACY_KEY_LAST_REPLY_PHONE = "last_reply_phone"
    private const val LEGACY_KEY_LAST_REPLY_EVENT = "last_reply_event"
    private const val LEGACY_KEY_LAST_REPLY_AT = "last_reply_at"

    /**
     * @param subscriptionId SIM that owns this call event; must match a store's link. Null/invalid → no reply.
     */
    fun handleEvent(
        context: Context,
        event: AutoReplyEvent,
        rawPhoneNumber: String?,
        subscriptionId: Int?,
    ): Boolean {
        val config = AutoReplyConfigStore(context)
        // Hard block: native must immediately stop all processing when blocked.
        if (config.getBlocked()) return false
        val storeConfig = StoreConfigStore(context)
        storeConfig.ensureMigrated()

        Log.d(TAG, "Event detected: event=$event rawPhone=$rawPhoneNumber subscriptionId=$subscriptionId")

        if (!config.isEnabledFailSafe()) {
            Log.d(TAG, "Blocked: autoReplyEnabled=false")
            return false
        }

        if (subscriptionId == null || subscriptionId == SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
            Log.d(TAG, "Blocked: no subscriptionId for event")
            return false
        }

        val store = storeConfig.findStoreBySubscriptionId(subscriptionId)
        if (store == null) {
            Log.d(TAG, "Blocked: no store linked to subscriptionId=$subscriptionId")
            return false
        }
        if (!store.active) {
            Log.d(TAG, "Blocked: store inactive id=${store.id}")
            return false
        }
        if (!store.isEventEnabled(event)) {
            Log.d(TAG, "Blocked: event toggle disabled for $event store=${store.id}")
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

        val message = store.resolveMessage(event)?.trim().orEmpty()
        if (message.isEmpty()) {
            Log.d(TAG, "Blocked: empty template message for event=$event store=${store.id}")
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
            val smsManager = resolveSmsManagerForSubscription(subscriptionId)
            val parts = smsManager.divideMessage(message)
            Log.d(
                TAG,
                "Calling sendSms: phone=$phoneNumber event=$event parts=${parts.size} logId=$logId subId=$subscriptionId"
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
            AutoReplyEvent.REJECTED_CALL -> ActivityEventType.REJECTED_CALL
            AutoReplyEvent.OUTGOING_ANSWERED -> ActivityEventType.OUTGOING_ANSWERED
            AutoReplyEvent.OUTGOING_UNANSWERED -> ActivityEventType.OUTGOING_UNANSWERED
        }
    }

    private fun emitUiEvent(map: Map<String, Any?>) {
        ReplyMateEventEmitter.emit(map)
    }

    private fun resolveSmsManagerForSubscription(subscriptionId: Int): SmsManager {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            if (subscriptionId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                return SmsManager.getSmsManagerForSubscriptionId(subscriptionId)
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

        val key = KEY_LAST_REPLY_AT_PHONE_PREFIX + phone
        val lastAtForPhone = prefs.getLong(key, 0L)
        if (lastAtForPhone > 0L && now - lastAtForPhone < THROTTLE_WINDOW_MS) {
            return true
        }

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
            .putString(LEGACY_KEY_LAST_REPLY_PHONE, phone)
            .putString(LEGACY_KEY_LAST_REPLY_EVENT, "ANY")
            .putLong(LEGACY_KEY_LAST_REPLY_AT, now)
            .apply()
    }
}
