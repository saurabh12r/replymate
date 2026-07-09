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
import com.replymate.reply_mate.sms.MmsSendHelper
import com.replymate.reply_mate.sms.SmsSendHelper
import java.util.Calendar
import java.util.UUID
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

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

        var resolvedSubId = subscriptionId
        if (resolvedSubId == null || resolvedSubId == SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
            resolvedSubId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
                val smsSub = SubscriptionManager.getDefaultSmsSubscriptionId()
                if (smsSub != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                    smsSub
                } else {
                    val defSub = SubscriptionManager.getDefaultSubscriptionId()
                    if (defSub != SubscriptionManager.INVALID_SUBSCRIPTION_ID) defSub else null
                }
            } else {
                null
            }
            Log.d(TAG, "No subscriptionId for event. Resolved to default: $resolvedSubId")
        }

        val stores = storeConfig.getStores()
        var store = if (resolvedSubId != null) {
            stores.firstOrNull { it.subscriptionId == resolvedSubId }
        } else {
            null
        }

        if (store == null) {
            // Fallback 1: If there is a store with subscriptionId == null (like the default store), use it.
            store = stores.firstOrNull { it.subscriptionId == null }
            if (store != null) {
                Log.d(TAG, "No store explicitly matched subscriptionId=$resolvedSubId. Falling back to store with null subscriptionId: ${store.id}")
            }
        }

        if (store == null) {
            // Fallback 2: If there is exactly one active store, use it.
            val activeStores = stores.filter { it.active }
            if (activeStores.size == 1) {
                store = activeStores.first()
                Log.d(TAG, "No store explicitly matched. Falling back to the single active store: ${store.id}")
            }
        }

        if (store == null) {
            // Fallback 3: Use the first active store or first store in general.
            store = stores.firstOrNull { it.active } ?: stores.firstOrNull()
            if (store != null) {
                Log.d(TAG, "No store matched. Falling back to first available store: ${store.id}")
            }
        }

        if (store == null) {
            Log.d(TAG, "Blocked: no store found in config")
            return false
        }
        if (store.subscriptionId != null && store.subscriptionId != resolvedSubId) {
            Log.d(TAG, "Blocked: store linked to a different subscriptionId storeSubId=${store.subscriptionId} resolvedSubId=$resolvedSubId")
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
        val appCtx = context.applicationContext

        // 1. Instantly offload slow database and network operations to a background coroutine
        // so that they do not delay the hardware SMS dispatching.
        CoroutineScope(Dispatchers.IO).launch {
            try {
                updateCallStats(appCtx, event)
            } catch (e: Exception) {
                Log.w(TAG, "Background updateCallStats failed", e)
            }

            try {
                val contactName = getContactName(appCtx, phoneNumber)
                ActivityLogPendingStore.appendCall(
                    appCtx,
                    id = logId,
                    type = activityType,
                    phone = phoneNumber,
                    name = contactName,
                    replied = false,
                    messageSent = message,
                    isVacation = store.vacationMode
                )
            } catch (e: Exception) {
                Log.w(TAG, "Background appendCall failed", e)
            }
        }

        // 2. Instantly emit the dispatching event to UI
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

        // 3. Dispatch the message at the Android OS layer.
        // Wait 3.5 seconds before handing off to SmsManager so the cellular modem has
        // time to fully release the voice channel from the just-ended call.
        // Without this delay many modems queue the SMS internally and only flush it
        // during the next cellular event (e.g. when the next caller rings), which
        // makes the SMS appear to fire "when P2 calls" rather than right after P1's call.
        try { Thread.sleep(3_500) } catch (_: InterruptedException) {}

        return try {
            val imagePath = store.imagePath
            if (!imagePath.isNullOrBlank()) {
                // ── MMS path: image + text ────────────────────────────────────────
                Log.d(TAG, "Sending MMS with image=$imagePath to $phoneNumber logId=$logId")
                val mmsSent = MmsSendHelper.sendMmsWithImage(
                    context = context,
                    subscriptionId = resolvedSubId,
                    destinationAddress = phoneNumber,
                    text = message,
                    imagePath = imagePath,
                )
                if (mmsSent) {
                    Log.d(TAG, "MMS dispatched successfully for phone=$phoneNumber")
                } else {
                    // Fallback to plain SMS
                    Log.w(TAG, "MMS failed; falling back to SMS for phone=$phoneNumber")
                    val smsManager = resolveSmsManagerForSubscription(context, resolvedSubId)
                    val parts = smsManager.divideMessage(message)
                    SmsSendHelper.sendMultipartTextMessageWithSentCallback(
                        context, smsManager, phoneNumber, parts, logId
                    )
                }
            } else {
                // ── Plain SMS path ────────────────────────────────────────────────
                val smsManager = resolveSmsManagerForSubscription(context, resolvedSubId)
                val parts = smsManager.divideMessage(message)
                Log.d(
                    TAG,
                    "Calling sendSms: phone=$phoneNumber event=$event parts=${parts.size} logId=$logId subId=$resolvedSubId"
                )
                SmsSendHelper.sendMultipartTextMessageWithSentCallback(
                    context,
                    smsManager,
                    phoneNumber,
                    parts,
                    logId
                )
            }
            Log.d(TAG, "Reply send triggered successfully for phone=$phoneNumber")
            true
        } catch (e: Exception) {
            Log.e(TAG, "SMS send failed for phone=$phoneNumber event=$event", e)
            CoroutineScope(Dispatchers.IO).launch {
                ActivityLogPendingStore.appendPatchReplied(
                    appCtx,
                    logId,
                    false
                )
            }
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

    private fun resolveSmsManagerForSubscription(context: Context, subscriptionId: Int?): SmsManager {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val smsManager = context.getSystemService(SmsManager::class.java)
            if (subscriptionId != null && subscriptionId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                return smsManager.createForSubscriptionId(subscriptionId)
            }
            return smsManager
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            if (subscriptionId != null && subscriptionId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                return SmsManager.getSmsManagerForSubscriptionId(subscriptionId)
            }
        }
        @Suppress("DEPRECATION")
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
        val config = AutoReplyConfigStore(context)
        val throttleWindowMs = config.throttleDuration() * 60 * 60 * 1000L
        val prefs = context.getSharedPreferences(AutoReplyConfigStore.PREFS_NAME, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()

        val key = KEY_LAST_REPLY_AT_PHONE_PREFIX + phone
        val lastAtForPhone = prefs.getLong(key, 0L)
        if (lastAtForPhone > 0L && now - lastAtForPhone < throttleWindowMs) {
            return true
        }

        val legacyPhone = prefs.getString(LEGACY_KEY_LAST_REPLY_PHONE, null)
        val legacyAt = prefs.getLong(LEGACY_KEY_LAST_REPLY_AT, 0L)
        if (legacyPhone == phone && legacyAt > 0L && now - legacyAt < throttleWindowMs) {
            return true
        }

        return false
    }

    @Synchronized
    fun updateThrottleState(context: Context, phone: String) {
        val prefs = context.getSharedPreferences(AutoReplyConfigStore.PREFS_NAME, Context.MODE_PRIVATE)
        val now = System.currentTimeMillis()
        prefs.edit()
            .putLong(KEY_LAST_REPLY_AT_PHONE_PREFIX + phone, now)
            .putString(LEGACY_KEY_LAST_REPLY_PHONE, phone)
            .putString(LEGACY_KEY_LAST_REPLY_EVENT, "ANY")
            .putLong(LEGACY_KEY_LAST_REPLY_AT, now)
            .commit()
    }

    @Synchronized
    fun updateCallStats(context: Context, event: AutoReplyEvent) {
        try {
            try {
                if (com.google.firebase.FirebaseApp.getApps(context).isEmpty()) {
                    com.google.firebase.FirebaseApp.initializeApp(context.applicationContext)
                }
            } catch (fe: Exception) {
                Log.w(TAG, "Failed to initialize Firebase in updateCallStats", fe)
            }
            val db = com.google.firebase.firestore.FirebaseFirestore.getInstance()
            val now = java.util.Calendar.getInstance()
            val year = now.get(java.util.Calendar.YEAR)
            val month = now.get(java.util.Calendar.MONTH) + 1
            val day = now.get(java.util.Calendar.DAY_OF_MONTH)

            val dailyId = "$year-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}"
            val monthlyId = "$year-${month.toString().padStart(2, '0')}"

            val isMissed = event == AutoReplyEvent.MISSED_CALL || event == AutoReplyEvent.MISSED_WHATSAPP_CALL || event == AutoReplyEvent.REJECTED_CALL || event == AutoReplyEvent.BUSY_CALL
            val isAnswered = event == AutoReplyEvent.CALL_ANSWERED
            val isIncoming = isMissed || isAnswered

            val batch = db.batch()

            if (isIncoming) {
                // 1. Global daily_stats
                val globalDailyUpdates = mutableMapOf<String, Any>(
                    "date" to com.google.firebase.Timestamp.now()
                )
                if (isAnswered) globalDailyUpdates["callsReceived"] = com.google.firebase.firestore.FieldValue.increment(1)
                if (isMissed) globalDailyUpdates["missedCalls"] = com.google.firebase.firestore.FieldValue.increment(1)
            batch.set(
                db.collection("daily_stats").document(dailyId),
                globalDailyUpdates,
                com.google.firebase.firestore.SetOptions.merge()
            )

                // 2. Global monthly_stats
                val globalMonthlyUpdates = mutableMapOf<String, Any>(
                    "year" to year,
                    "month" to month
                )
                if (isAnswered) globalMonthlyUpdates["callsReceived"] = com.google.firebase.firestore.FieldValue.increment(1)
                if (isMissed) globalMonthlyUpdates["missedCalls"] = com.google.firebase.firestore.FieldValue.increment(1)
                batch.set(
                    db.collection("monthly_stats").document(monthlyId),
                    globalMonthlyUpdates,
                    com.google.firebase.firestore.SetOptions.merge()
                )
            }

            // 3. Per-user stats/{uid}, stats/{uid}/daily, stats/{uid}/monthly
            // Use phone number as the document ID in stats collection to match admin portal
            val uid = com.google.firebase.auth.FirebaseAuth.getInstance().currentUser?.phoneNumber?.takeIf { it.isNotEmpty() }
                ?: AutoReplyConfigStore(context).getUserId()
            Log.d(TAG, "User ID for stats: $uid")
            if (!uid.isNullOrEmpty()) {
                val userStatsRef = db.collection("stats").document(uid)

                // Cumulative
                val cumulativeUpdates = mutableMapOf<String, Any>(
                    "lastActivity" to com.google.firebase.Timestamp.now()
                )
                if (isAnswered) cumulativeUpdates["callsReceived"] = com.google.firebase.firestore.FieldValue.increment(1)
                if (isMissed) cumulativeUpdates["missedCalls"] = com.google.firebase.firestore.FieldValue.increment(1)
                batch.set(userStatsRef, cumulativeUpdates, com.google.firebase.firestore.SetOptions.merge())

                // Per-user daily
                val userDailyUpdates = mutableMapOf<String, Any>(
                    "updatedAt" to com.google.firebase.Timestamp.now()
                )
                if (isAnswered) userDailyUpdates["callsReceived"] = com.google.firebase.firestore.FieldValue.increment(1)
                if (isMissed) userDailyUpdates["missedCalls"] = com.google.firebase.firestore.FieldValue.increment(1)
                batch.set(
                    userStatsRef.collection("daily").document(dailyId),
                    userDailyUpdates,
                    com.google.firebase.firestore.SetOptions.merge()
                )

                // Per-user monthly
                val userMonthlyUpdates = mutableMapOf<String, Any>(
                    "updatedAt" to com.google.firebase.Timestamp.now()
                )
                if (isAnswered) userMonthlyUpdates["callsReceived"] = com.google.firebase.firestore.FieldValue.increment(1)
                if (isMissed) userMonthlyUpdates["missedCalls"] = com.google.firebase.firestore.FieldValue.increment(1)
                batch.set(
                    userStatsRef.collection("monthly").document(monthlyId),
                    userMonthlyUpdates,
                    com.google.firebase.firestore.SetOptions.merge()
                )

                Log.d(TAG, "Call stats updated for event=$event uid=$uid")
            } else {
                Log.d(TAG, "Call stats: no uid — per-user stats skipped")
            }

            batch.commit()
        } catch (e: Exception) {
            Log.w(TAG, "Failed to update call stats: $e")
        }
    }

    private fun getContactName(context: Context, phoneNumber: String): String {
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return ""
        }
        return try {
            val uri = android.net.Uri.withAppendedPath(
                android.provider.ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
                android.net.Uri.encode(phoneNumber)
            )
            val projection = arrayOf(android.provider.ContactsContract.PhoneLookup.DISPLAY_NAME)
            context.contentResolver.query(uri, projection, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    cursor.getString(cursor.getColumnIndexOrThrow(android.provider.ContactsContract.PhoneLookup.DISPLAY_NAME)) ?: ""
                } else {
                    ""
                }
            } ?: ""
        } catch (e: Exception) {
            Log.e(TAG, "Error looking up contact name for $phoneNumber", e)
            ""
        }
    }
}
