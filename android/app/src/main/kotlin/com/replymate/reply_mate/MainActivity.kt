package com.replymate.reply_mate

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.Settings
import android.app.role.RoleManager
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log
import com.replymate.reply_mate.activity.ActivityLogPendingStore
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import com.replymate.reply_mate.autoreply.ContactFilterNativeStore
import com.replymate.reply_mate.autoreply.StoreConfigStore
import com.replymate.reply_mate.appstate.AppStateStore
import com.replymate.reply_mate.events.ReplyMateEventEmitter
import com.replymate.reply_mate.services.AutoReplyForegroundManager
import com.replymate.reply_mate.sms.SmsSendHelper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val notificationListenerChannel = "replymate/notification_listener"
    private val autoReplyChannel = "replymate/auto_reply"
    private val activityLogChannel = "replymate/activity_log"
    private val autoReplyEventsChannel = "replymate/auto_reply_events"

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "MainActivity.onCreate")
        super.onCreate(savedInstanceState)
    }

    override fun onPostResume() {
        super.onPostResume()
        // Mark app ready AFTER UI is visible (persisted for receivers).
        Handler(Looper.getMainLooper()).postDelayed({
            try {
                AppStateStore.setAppReady(applicationContext, true)
                AutoReplyForegroundManager.markAppReady()
            } catch (t: Throwable) {
                Log.e(TAG, "markAppReady failed", t)
            }
        }, 1500)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        Log.d(TAG, "configureFlutterEngine: start")
        super.configureFlutterEngine(flutterEngine)
        val configStore = AutoReplyConfigStore(applicationContext)

        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            autoReplyEventsChannel
        ).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                ReplyMateEventEmitter.attach(events)
            }

            override fun onCancel(arguments: Any?) {
                ReplyMateEventEmitter.attach(null)
            }
        })
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            notificationListenerChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "openNotificationListenerSettings" -> {
                    val intent = Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS)
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                }

                "isNotificationListenerEnabled" -> {
                    result.success(isNotificationListenerEnabled())
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            autoReplyChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startCallListener" -> {
                    configStore.setEnabled(true)
                    asyncSyncForegroundService()
                    result.success(true)
                }

                "stopCallListener" -> {
                    configStore.setEnabled(false)
                    asyncSyncForegroundService()
                    result.success(true)
                }

                "sendSms" -> {
                    val phone = call.argument<String>("phone")
                    val message = call.argument<String>("message")
                    if (phone.isNullOrBlank() || message.isNullOrBlank()) {
                        result.error("invalid_args", "phone/message required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val smsManager = resolveSmsManager()
                        val parts = smsManager.divideMessage(message)
                        SmsSendHelper.sendMultipartTextMessageWithSentCallback(
                            applicationContext,
                            smsManager,
                            phone,
                            parts
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("sms_failed", e.message, null)
                    }
                }

                "updateAutoReplyConfig" -> {
                    val autoReplyEnabled = call.argument<Boolean>("autoReplyEnabled") ?: false
                    val replyOnCallAnswered = call.argument<Boolean>("replyOnCallAnswered") ?: false
                    val replyOnMissedCall = call.argument<Boolean>("replyOnMissedCall") ?: true
                    val replyOnWhatsappCall = call.argument<Boolean>("replyOnWhatsappCall") ?: true
                    val replyOnBusyCall = call.argument<Boolean>("replyOnBusyCall") ?: false
                    val replyOnRejectedCall = call.argument<Boolean>("replyOnRejectedCall") ?: false
                    val replyOnOutgoingAnswered = call.argument<Boolean>("replyOnOutgoingAnswered") ?: false
                    val replyOnOutgoingUnanswered = call.argument<Boolean>("replyOnOutgoingUnanswered") ?: false
                    val useTimeRange = call.argument<Boolean>("useTimeRange") ?: false
                    val startMinutes = call.argument<Int>("startMinutes") ?: 540
                    val endMinutes = call.argument<Int>("endMinutes") ?: 1260
                    val defaultReplyMessage =
                        call.argument<String>("defaultReplyMessage") ?: "I'll call you later."

                    configStore.setConfig(
                        autoReplyEnabled = autoReplyEnabled,
                        replyOnCallAnswered = replyOnCallAnswered,
                        replyOnMissedCall = replyOnMissedCall,
                        replyOnWhatsappCall = replyOnWhatsappCall,
                        replyOnBusyCall = replyOnBusyCall,
                        replyOnRejectedCall = replyOnRejectedCall,
                        replyOnOutgoingAnswered = replyOnOutgoingAnswered,
                        replyOnOutgoingUnanswered = replyOnOutgoingUnanswered,
                        useTimeRange = useTimeRange,
                        startMinutes = startMinutes,
                        endMinutes = endMinutes,
                        defaultReplyMessage = defaultReplyMessage
                    )
                    asyncSyncForegroundService()
                    result.success(true)
                }

                "setAutoReplyEnabled" -> {
                    val enabled = call.argument<Boolean>("autoReplyEnabled") ?: false
                    configStore.setEnabled(enabled)
                    asyncSyncForegroundService()
                    result.success(true)
                }

                "setBlocked" -> {
                    val value = call.argument<Boolean>("value") ?: false
                    configStore.setBlocked(value)
                    // Block must immediately disable background processing.
                    asyncSyncForegroundService()
                    result.success(true)
                }

                "setReplyRules" -> {
                    val replyOnMissedCall = call.argument<Boolean>("replyOnMissedCall") ?: true
                    val replyOnIncomingCall = call.argument<Boolean>("replyOnIncomingCall") ?: false
                    val replyOnWhatsappCall = call.argument<Boolean>("replyOnWhatsappCall") ?: true
                    val replyOnBusyCall = call.argument<Boolean>("replyOnBusyCall") ?: false
                    val replyOnRejectedCall = call.argument<Boolean>("replyOnRejectedCall") ?: false
                    val replyOnOutgoingAnswered = call.argument<Boolean>("replyOnOutgoingAnswered") ?: false
                    val replyOnOutgoingUnanswered = call.argument<Boolean>("replyOnOutgoingUnanswered") ?: false
                    configStore.setReplyRules(
                        replyOnMissedCall = replyOnMissedCall,
                        replyOnIncomingCall = replyOnIncomingCall,
                        replyOnWhatsappCall = replyOnWhatsappCall,
                        replyOnBusyCall = replyOnBusyCall,
                        replyOnRejectedCall = replyOnRejectedCall,
                        replyOnOutgoingAnswered = replyOnOutgoingAnswered,
                        replyOnOutgoingUnanswered = replyOnOutgoingUnanswered
                    )
                    asyncSyncForegroundService()
                    result.success(true)
                }

                "setCustomMessages" -> {
                    val missedCallMessage = call.argument<String>("missedCallMessage").orEmpty()
                    val incomingCallMessage = call.argument<String>("incomingCallMessage").orEmpty()
                    val whatsappCallMessage = call.argument<String>("whatsappCallMessage").orEmpty()
                    val busyCallMessage = call.argument<String>("busyCallMessage").orEmpty()
                    val rejectedCallMessage = call.argument<String>("rejectedCallMessage").orEmpty()
                    val outgoingAnsweredMessage = call.argument<String>("outgoingAnsweredMessage").orEmpty()
                    val outgoingUnansweredMessage = call.argument<String>("outgoingUnansweredMessage").orEmpty()
                    configStore.setCustomMessages(
                        missedCallMessage = missedCallMessage,
                        incomingCallMessage = incomingCallMessage,
                        whatsappCallMessage = whatsappCallMessage,
                        busyCallMessage = busyCallMessage,
                        rejectedCallMessage = rejectedCallMessage,
                        outgoingAnsweredMessage = outgoingAnsweredMessage,
                        outgoingUnansweredMessage = outgoingUnansweredMessage
                    )
                    asyncSyncForegroundService()
                    result.success(true)
                }

                "setThrottleEnabled" -> {
                    val enabled = call.argument<Boolean>("throttleEnabled") ?: true
                    configStore.setThrottleEnabled(enabled)
                    asyncSyncForegroundService()
                    result.success(true)
                }

                "syncContactFilterNative" -> {
                    val mode = call.argument<String>("filterMode") ?: "ALL"
                    val phonesJson = call.argument<String>("phonesJson") ?: "[]"
                    ContactFilterNativeStore.syncFromFlutter(applicationContext, mode, phonesJson)
                    result.success(true)
                }

                "openBatteryOptimizationSettings" -> {
                    try {
                        startActivity(
                            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                        )
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("intent_failed", e.message, null)
                    }
                }

                "requestIgnoreBatteryOptimizations" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                            val pkg = packageName
                            if (!pm.isIgnoringBatteryOptimizations(pkg)) {
                                val i = Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS).apply {
                                    data = Uri.parse("package:$pkg")
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(i)
                            }
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("intent_failed", e.message, null)
                    }
                }

                "requestDefaultSmsRole" -> {
                    try {
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roleManager = getSystemService(RoleManager::class.java)
                            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                startActivity(intent)
                            } else {
                                // Fallback: open default apps settings if role is not available.
                                val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                            }
                        } else {
                            val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("intent_failed", e.message, null)
                    }
                }

                "getAutoReplyConfig" -> {
                    result.success(configStore.toMap())
                }

                "listSubscriptionInfos" -> {
                    try {
                        result.success(listSubscriptionInfos())
                    } catch (e: Exception) {
                        result.error("subscription_list_failed", e.message, null)
                    }
                }

                "getDefaultSmsSubscriptionId" -> {
                    try {
                        val subId = SubscriptionManager.getDefaultSmsSubscriptionId()
                        if (subId == SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                            result.success(null)
                        } else {
                            result.success(subId)
                        }
                    } catch (e: Exception) {
                        result.error("default_sms_sub_failed", e.message, null)
                    }
                }

                "getStoresJson" -> {
                    try {
                        val storeStore = StoreConfigStore(applicationContext)
                        storeStore.ensureMigrated()
                        result.success(storeStore.getStoresJsonOrEmpty())
                    } catch (e: Exception) {
                        result.error("get_stores_failed", e.message, null)
                    }
                }

                "setStoresJson" -> {
                    try {
                        val json = call.argument<String>("storesJson")
                        if (json == null) {
                            result.error("invalid_args", "storesJson is required", null)
                            return@setMethodCallHandler
                        }
                        StoreConfigStore(applicationContext).setStoresJson(json)
                        syncForegroundService()
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("set_stores_failed", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            activityLogChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pullPendingLogs" -> {
                    try {
                        val lines = ActivityLogPendingStore.pullLines(applicationContext)
                        result.success(lines)
                    } catch (e: Exception) {
                        Log.e(TAG, "pullPendingLogs failed", e)
                        result.error("pull_failed", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }

        Log.d(TAG, "configureFlutterEngine: end")
    }

    private fun asyncSyncForegroundService() {
        // Avoid blocking Flutter engine startup / UI thread on some OEM devices.
        thread(name = "ReplyMateFgsSync") {
            try {
                syncForegroundService()
            } catch (t: Throwable) {
                Log.e(TAG, "syncForegroundService async failed", t)
            }
        }
    }

    private fun syncForegroundService() {
        AutoReplyForegroundManager.sync(applicationContext)
    }

    private fun listSubscriptionInfos(): List<Map<String, Any?>> {
        val sm = applicationContext.getSystemService(SubscriptionManager::class.java)
            ?: return emptyList()
        val list = sm.activeSubscriptionInfoList ?: return emptyList()
        return list.map { info ->
            mapOf(
                "subscriptionId" to info.subscriptionId,
                "displayName" to info.displayName?.toString().orEmpty(),
                "simSlotIndex" to info.simSlotIndex,
            )
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val packageName = applicationContext.packageName
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners"
        ) ?: return false
        val names = flat.split(":")
        return names.any {
            val componentName = ComponentName.unflattenFromString(it)
            componentName?.packageName == packageName
        }
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

    companion object {
        private const val TAG = "ReplyMateMainActivity"
    }
}
