package com.replymate.reply_mate

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.app.role.RoleManager
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import com.replymate.reply_mate.activity.ActivityLogPendingStore
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import com.replymate.reply_mate.autoreply.ContactFilterNativeStore
import com.replymate.reply_mate.events.ReplyMateEventEmitter
import com.replymate.reply_mate.services.AutoReplyForegroundManager
import com.replymate.reply_mate.sms.SmsSendHelper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val notificationListenerChannel = "replymate/notification_listener"
    private val autoReplyChannel = "replymate/auto_reply"
    private val activityLogChannel = "replymate/activity_log"
    private val autoReplyEventsChannel = "replymate/auto_reply_events"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
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
                    syncForegroundService()
                    result.success(true)
                }

                "stopCallListener" -> {
                    configStore.setEnabled(false)
                    syncForegroundService()
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
                    val replyOnOutgoingCall = call.argument<Boolean>("replyOnOutgoingCall") ?: false
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
                        replyOnOutgoingCall = replyOnOutgoingCall,
                        useTimeRange = useTimeRange,
                        startMinutes = startMinutes,
                        endMinutes = endMinutes,
                        defaultReplyMessage = defaultReplyMessage
                    )
                    syncForegroundService()
                    result.success(true)
                }

                "setAutoReplyEnabled" -> {
                    val enabled = call.argument<Boolean>("autoReplyEnabled") ?: false
                    configStore.setEnabled(enabled)
                    syncForegroundService()
                    result.success(true)
                }

                "setReplyRules" -> {
                    val replyOnMissedCall = call.argument<Boolean>("replyOnMissedCall") ?: true
                    val replyOnIncomingCall = call.argument<Boolean>("replyOnIncomingCall") ?: false
                    val replyOnWhatsappCall = call.argument<Boolean>("replyOnWhatsappCall") ?: true
                    val replyOnBusyCall = call.argument<Boolean>("replyOnBusyCall") ?: false
                    val replyOnOutgoingCall = call.argument<Boolean>("replyOnOutgoingCall") ?: false
                    configStore.setReplyRules(
                        replyOnMissedCall = replyOnMissedCall,
                        replyOnIncomingCall = replyOnIncomingCall,
                        replyOnWhatsappCall = replyOnWhatsappCall,
                        replyOnBusyCall = replyOnBusyCall,
                        replyOnOutgoingCall = replyOnOutgoingCall
                    )
                    syncForegroundService()
                    result.success(true)
                }

                "setCustomMessages" -> {
                    val missedCallMessage = call.argument<String>("missedCallMessage").orEmpty()
                    val incomingCallMessage = call.argument<String>("incomingCallMessage").orEmpty()
                    val whatsappCallMessage = call.argument<String>("whatsappCallMessage").orEmpty()
                    val busyCallMessage = call.argument<String>("busyCallMessage").orEmpty()
                    val outgoingCallMessage = call.argument<String>("outgoingCallMessage").orEmpty()
                    configStore.setCustomMessages(
                        missedCallMessage = missedCallMessage,
                        incomingCallMessage = incomingCallMessage,
                        whatsappCallMessage = whatsappCallMessage,
                        busyCallMessage = busyCallMessage,
                        outgoingCallMessage = outgoingCallMessage
                    )
                    syncForegroundService()
                    result.success(true)
                }

                "setThrottleEnabled" -> {
                    val enabled = call.argument<Boolean>("throttleEnabled") ?: true
                    configStore.setThrottleEnabled(enabled)
                    syncForegroundService()
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

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            activityLogChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pullPendingLogs" -> {
                    val lines = ActivityLogPendingStore.pullLines(applicationContext)
                    result.success(lines)
                }

                else -> result.notImplemented()
            }
        }

        syncForegroundService()
    }

    private fun syncForegroundService() {
        AutoReplyForegroundManager.sync(applicationContext)
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
}
