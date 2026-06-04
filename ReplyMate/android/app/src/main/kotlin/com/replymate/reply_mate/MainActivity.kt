package com.replymate.reply_mate

import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.os.Environment
import android.os.Handler
import android.os.Looper
import android.os.PowerManager
import android.provider.CallLog
import android.provider.MediaStore
import android.provider.Settings
import android.provider.Telephony
import android.app.role.RoleManager
import android.telephony.SmsManager
import android.telephony.SubscriptionManager
import android.util.Log
import com.google.firebase.auth.FirebaseAuth
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
import androidx.core.app.ActivityCompat
import android.content.pm.PackageManager
import java.io.File
import kotlin.concurrent.thread

class MainActivity : FlutterActivity() {
    private val autoReplyChannel = "replymate/auto_reply"
    private val activityLogChannel = "replymate/activity_log"
    private val autoReplyEventsChannel = "replymate/auto_reply_events"
    private val callLogChannel = "replymate/call_log"
    private val statsChannel = "replymate/stats"

    private var pendingSmsDefaultResult: MethodChannel.Result? = null
    private var pendingCallLogPermissionResult: MethodChannel.Result? = null
    private val REQUEST_CODE_READ_CALL_LOG = 1234

    override fun onCreate(savedInstanceState: Bundle?) {
        Log.d(TAG, "MainActivity.onCreate")
        super.onCreate(savedInstanceState)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE_DEFAULT_SMS) {
            val isDefault = Telephony.Sms.getDefaultSmsPackage(applicationContext) == applicationContext.packageName
            pendingSmsDefaultResult?.success(isDefault)
            pendingSmsDefaultResult = null
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_CODE_READ_CALL_LOG) {
            val granted = grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED
            pendingCallLogPermissionResult?.success(granted)
            pendingCallLogPermissionResult = null
        }
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

                "scheduleSms" -> {
                    try {
                        val id = call.argument<String>("id") ?: return@setMethodCallHandler
                        val phone = call.argument<String>("phoneNumber") ?: return@setMethodCallHandler
                        val message = call.argument<String>("message") ?: return@setMethodCallHandler
                        val timeMillis = call.argument<Long>("timeMillis") ?: return@setMethodCallHandler

                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                        val intent = Intent(applicationContext, com.replymate.reply_mate.receivers.ScheduledSmsReceiver::class.java).apply {
                            putExtra(com.replymate.reply_mate.receivers.ScheduledSmsReceiver.EXTRA_ID, id)
                            putExtra(com.replymate.reply_mate.receivers.ScheduledSmsReceiver.EXTRA_PHONE, phone)
                            putExtra(com.replymate.reply_mate.receivers.ScheduledSmsReceiver.EXTRA_MESSAGE, message)
                        }
                        
                        // We use the ID hash code as the pending intent request code so it's unique
                        val requestCode = id.hashCode()
                        val pendingIntent = android.app.PendingIntent.getBroadcast(
                            applicationContext,
                            requestCode,
                            intent,
                            android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                        )

                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            if (alarmManager.canScheduleExactAlarms()) {
                                alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
                            } else {
                                // Fallback if exact alarm permission is revoked
                                alarmManager.setAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
                            }
                        } else {
                            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                                alarmManager.setExactAndAllowWhileIdle(android.app.AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
                            } else {
                                alarmManager.setExact(android.app.AlarmManager.RTC_WAKEUP, timeMillis, pendingIntent)
                            }
                        }

                        Log.d(TAG, "Scheduled SMS id=$id for time=$timeMillis")
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to schedule SMS", e)
                        result.error("schedule_failed", e.message, null)
                    }
                }

                "cancelScheduledSms" -> {
                    try {
                        val id = call.argument<String>("id") ?: return@setMethodCallHandler
                        val alarmManager = getSystemService(Context.ALARM_SERVICE) as android.app.AlarmManager
                        val intent = Intent(applicationContext, com.replymate.reply_mate.receivers.ScheduledSmsReceiver::class.java)
                        
                        val requestCode = id.hashCode()
                        val pendingIntent = android.app.PendingIntent.getBroadcast(
                            applicationContext,
                            requestCode,
                            intent,
                            android.app.PendingIntent.FLAG_NO_CREATE or android.app.PendingIntent.FLAG_IMMUTABLE
                        )

                        if (pendingIntent != null) {
                            alarmManager.cancel(pendingIntent)
                            pendingIntent.cancel()
                            Log.d(TAG, "Cancelled scheduled SMS id=$id")
                        }
                        result.success(true)
                    } catch (e: Exception) {
                        Log.e(TAG, "Failed to cancel scheduled SMS", e)
                        result.error("cancel_failed", e.message, null)
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

                    // Only update subEndTime when a real value is provided.
                    // Do NOT call setSubEndTime(0L) when null — that would wipe the stored
                    // expiry date and disable the native background subscription check, allowing
                    // SMS to fire after the subscription expires while the app is closed.
                    val subEndRaw = call.argument<Any>("subscriptionEndMs")
                    val subEndMs = (subEndRaw as? Number)?.toLong()
                    if (subEndMs != null && subEndMs > 0L) {
                        configStore.setSubEndTime(subEndMs)
                    }
                    // If blocking without an end time (e.g. admin block), preserve whatever
                    // end time was previously stored so the expiry check keeps working.

                    val nextPlanDurRaw = call.argument<Any>("nextPlanDurationDays")
                    val nextPlanDurDays = (nextPlanDurRaw as? Number)?.toInt() ?: 0
                    configStore.setNextPlanDurationDays(nextPlanDurDays)

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

                "setThrottleDuration" -> {
                    val duration = call.argument<Int>("throttleDuration") ?: 1
                    configStore.setThrottleDuration(duration)
                    result.success(true)
                }

                "syncContactFilterNative" -> {
                    val mode = call.argument<String>("filterMode") ?: "ALL"
                    val phonesJson = call.argument<String>("phonesJson") ?: "[]"
                    ContactFilterNativeStore.syncFromFlutter(applicationContext, mode, phonesJson)
                    result.success(true)
                }

                "isIgnoringBatteryOptimizations" -> {
                    try {
                        val pm = getSystemService(Context.POWER_SERVICE) as PowerManager
                        val isIgnoring = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                            pm.isIgnoringBatteryOptimizations(packageName)
                        } else {
                            true
                        }
                        result.success(isIgnoring)
                    } catch (e: Exception) {
                        result.error("check_failed", e.message, null)
                    }
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

                "isDefaultSmsApp" -> {
                    try {
                        val isDefault = Telephony.Sms.getDefaultSmsPackage(applicationContext) == applicationContext.packageName
                        result.success(isDefault)
                    } catch (e: Exception) {
                        result.error("check_failed", e.message, null)
                    }
                }

                "requestDefaultSmsApp" -> {
                    try {
                        val isAlreadyDefault = Telephony.Sms.getDefaultSmsPackage(applicationContext) == applicationContext.packageName
                        if (isAlreadyDefault) {
                            result.success(true)
                            return@setMethodCallHandler
                        }

                        pendingSmsDefaultResult = result
                        
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                            val roleManager = getSystemService(RoleManager::class.java)
                            if (roleManager != null && roleManager.isRoleAvailable(RoleManager.ROLE_SMS)) {
                                val intent = roleManager.createRequestRoleIntent(RoleManager.ROLE_SMS)
                                startActivityForResult(intent, REQUEST_CODE_DEFAULT_SMS)
                            } else {
                                val intent = Intent(Settings.ACTION_MANAGE_DEFAULT_APPS_SETTINGS)
                                startActivityForResult(intent, REQUEST_CODE_DEFAULT_SMS)
                            }
                        } else {
                            val intent = Intent(Telephony.Sms.Intents.ACTION_CHANGE_DEFAULT)
                            intent.putExtra(Telephony.Sms.Intents.EXTRA_PACKAGE_NAME, applicationContext.packageName)
                            startActivityForResult(intent, REQUEST_CODE_DEFAULT_SMS)
                        }
                    } catch (e: Exception) {
                        result.error("intent_failed", e.message, null)
                        pendingSmsDefaultResult?.success(false)
                        pendingSmsDefaultResult = null
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
                "setUserId" -> {
                    val userId = call.argument<String>("userId")
                    configStore.setUserId(userId)
                    result.success(true)
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

                "saveFileToDownloads" -> {
                    thread(name = "ReplyMateSaveFile") {
                        try {
                            val sourcePath = call.argument<String>("filePath")
                            val fileName = call.argument<String>("fileName")
                            val mimeType = call.argument<String>("mimeType") ?: "text/csv"
                            if (sourcePath == null || fileName == null) {
                                result.error("invalid_args", "filePath and fileName required", null)
                                return@thread
                            }
                            val sourceFile = File(sourcePath)
                            if (!sourceFile.exists()) {
                                result.error("file_not_found", "Source file not found: $sourcePath", null)
                                return@thread
                            }
                            val savedPath = saveToPublicDownloads(applicationContext, sourceFile, fileName, mimeType)
                            result.success(savedPath)
                        } catch (e: Exception) {
                            Log.e(TAG, "saveFileToDownloads failed", e)
                            result.error("save_failed", e.message, null)
                        }
                    }
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            callLogChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "checkCallLogPermission" -> {
                    val hasPermission = androidx.core.content.ContextCompat.checkSelfPermission(
                        applicationContext,
                        android.Manifest.permission.READ_CALL_LOG
                    ) == PackageManager.PERMISSION_GRANTED
                    result.success(hasPermission)
                }
                "requestCallLogPermission" -> {
                    val hasPermission = androidx.core.content.ContextCompat.checkSelfPermission(
                        applicationContext,
                        android.Manifest.permission.READ_CALL_LOG
                    ) == PackageManager.PERMISSION_GRANTED
                    if (hasPermission) {
                        result.success(true)
                    } else {
                        pendingCallLogPermissionResult = result
                        ActivityCompat.requestPermissions(
                            this,
                            arrayOf(android.Manifest.permission.READ_CALL_LOG),
                            REQUEST_CODE_READ_CALL_LOG
                        )
                    }
                }
                "getRecentCalls" -> {
                    val list = mutableListOf<Map<String, String>>()
                    val hasPermission = androidx.core.content.ContextCompat.checkSelfPermission(
                        applicationContext,
                        android.Manifest.permission.READ_CALL_LOG
                    ) == android.content.pm.PackageManager.PERMISSION_GRANTED
                    if (!hasPermission) {
                        result.success(list)
                        return@setMethodCallHandler
                    }
                    try {
                        val projection = arrayOf(
                            CallLog.Calls.NUMBER,
                            CallLog.Calls.CACHED_NAME
                        )
                        val cursor = applicationContext.contentResolver.query(
                            CallLog.Calls.CONTENT_URI,
                            projection,
                            null,
                            null,
                            "${CallLog.Calls.DATE} DESC"
                        )
                        cursor?.use {
                            val numberIdx = it.getColumnIndex(CallLog.Calls.NUMBER)
                            val nameIdx = it.getColumnIndex(CallLog.Calls.CACHED_NAME)
                            var count = 0
                            while (it.moveToNext() && count < 100) {
                                val number = if (numberIdx >= 0) it.getString(numberIdx) else null
                                val name = if (nameIdx >= 0) it.getString(nameIdx) else null
                                if (!number.isNullOrEmpty()) {
                                    list.add(mapOf(
                                        "number" to number,
                                        "name" to (name ?: "")
                                    ))
                                    count++
                                }
                            }
                        }
                        result.success(list)
                    } catch (e: Exception) {
                        Log.e("MainActivity", "Error querying call log", e)
                        result.error("call_log_error", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Stats channel handler
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            statsChannel
        ).setMethodCallHandler { call, result ->
            try {
                val now = System.currentTimeMillis()
                val calendar = java.util.Calendar.getInstance()
                calendar.timeInMillis = now
                val year = calendar.get(java.util.Calendar.YEAR)
                val month = calendar.get(java.util.Calendar.MONTH) + 1
                val day = calendar.get(java.util.Calendar.DAY_OF_MONTH)
                
                val dailyId = "$year-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}"
                val monthlyId = "$year-${month.toString().padStart(2, '0')}"
                
                when (call.method) {
                    "incrementSmsSent" -> {
                        val db = com.google.firebase.firestore.FirebaseFirestore.getInstance()
                        
                        // Get phone number directly from Firebase Auth
                        val firebaseUser = com.google.firebase.auth.FirebaseAuth.getInstance().currentUser
                        val userId = firebaseUser?.phoneNumber?.takeIf { it.isNotEmpty() }
                            ?: configStore.getUserId()
                        
                        if (!userId.isNullOrEmpty()) {
                            val userDocRef = db.collection("stats").document(userId)
                            
                            // Cumulative stats
                            userDocRef.set(mapOf(
                                "totalSmsSent" to com.google.firebase.firestore.FieldValue.increment(1),
                                "lastSmsAt" to com.google.firebase.Timestamp.now(),
                                "lastActiveAt" to com.google.firebase.Timestamp.now()
                            ), com.google.firebase.firestore.SetOptions.merge())
                            
                            // Daily stats
                            userDocRef.collection("daily").document(dailyId).set(mapOf(
                                "smsSent" to com.google.firebase.firestore.FieldValue.increment(1),
                                "updatedAt" to com.google.firebase.Timestamp.now()
                            ), com.google.firebase.firestore.SetOptions.merge())
                            
                            // Monthly stats
                            userDocRef.collection("monthly").document(monthlyId).set(mapOf(
                                "smsSent" to com.google.firebase.firestore.FieldValue.increment(1),
                                "updatedAt" to com.google.firebase.Timestamp.now()
                            ), com.google.firebase.firestore.SetOptions.merge())
                        }
                        result.success(true)
                    }
                    "incrementSmsFailed" -> {
                        val db = com.google.firebase.firestore.FirebaseFirestore.getInstance()
                        
                        // Get phone number directly from Firebase Auth
                        val firebaseUser = com.google.firebase.auth.FirebaseAuth.getInstance().currentUser
                        val userId = firebaseUser?.phoneNumber?.takeIf { it.isNotEmpty() }
                            ?: configStore.getUserId()
                        
                        if (!userId.isNullOrEmpty()) {
                            val userDocRef = db.collection("stats").document(userId)
                            
                            // Cumulative stats
                            userDocRef.set(mapOf(
                                "totalSmsFailed" to com.google.firebase.firestore.FieldValue.increment(1),
                                "lastSmsAt" to com.google.firebase.Timestamp.now(),
                                "lastActiveAt" to com.google.firebase.Timestamp.now()
                            ), com.google.firebase.firestore.SetOptions.merge())
                            
                            // Daily stats
                            userDocRef.collection("daily").document(dailyId).set(mapOf(
                                "smsFailed" to com.google.firebase.firestore.FieldValue.increment(1),
                                "updatedAt" to com.google.firebase.Timestamp.now()
                            ), com.google.firebase.firestore.SetOptions.merge())
                            
                            // Monthly stats
                            userDocRef.collection("monthly").document(monthlyId).set(mapOf(
                                "smsFailed" to com.google.firebase.firestore.FieldValue.increment(1),
                                "updatedAt" to com.google.firebase.Timestamp.now()
                            ), com.google.firebase.firestore.SetOptions.merge())
                        }
                        result.success(true)
                    }
                    "incrementCallReceived" -> {
                        val db = com.google.firebase.firestore.FirebaseFirestore.getInstance()
                        val missed = call.argument<Boolean>("missed") ?: false
                        
                        val firebaseUser = com.google.firebase.auth.FirebaseAuth.getInstance().currentUser
                        val userId = firebaseUser?.phoneNumber?.takeIf { it.isNotEmpty() }
                            ?: configStore.getUserId()
                        
                        if (!userId.isNullOrEmpty()) {
                            val userDocRef = db.collection("stats").document(userId)
                            
                            // Update lastActiveAt on call
                            userDocRef.set(mapOf(
                                "lastActiveAt" to com.google.firebase.Timestamp.now()
                            ), com.google.firebase.firestore.SetOptions.merge())
                        }
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Stats update failed", e)
                result.error("stats_failed", e.message, null)
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

    /**
     * Saves [sourceFile] to the public Downloads folder.
     * Uses MediaStore on Android 10+ (API 29+) for reliable public visibility.
     * Falls back to direct copy on older Android.
     */
    private fun saveToPublicDownloads(
        context: Context,
        sourceFile: File,
        fileName: String,
        mimeType: String
    ): String {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // Android 10+ — use MediaStore
            val resolver = context.contentResolver
            val contentValues = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val collection = MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            val itemUri = resolver.insert(collection, contentValues)
                ?: throw IllegalStateException("MediaStore insert returned null")

            resolver.openOutputStream(itemUri).use { os ->
                checkNotNull(os) { "Failed to open output stream for $itemUri" }
                sourceFile.inputStream().use { it.copyTo(os) }
            }

            contentValues.clear()
            contentValues.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(itemUri, contentValues, null, null)

            itemUri.toString()
        } else {
            // Android 9 and below — direct file copy to public Downloads
            @Suppress("DEPRECATION")
            val downloadsDir = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            if (!downloadsDir.exists()) downloadsDir.mkdirs()
            val destFile = File(downloadsDir, fileName)
            sourceFile.copyTo(destFile, overwrite = true)
            destFile.absolutePath
        }
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

    private fun resolveSmsManager(): SmsManager {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val smsManager = applicationContext.getSystemService(SmsManager::class.java)
            val subId = SubscriptionManager.getDefaultSmsSubscriptionId()
            if (subId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                return smsManager.createForSubscriptionId(subId)
            }
            return smsManager
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP_MR1) {
            val subId = SubscriptionManager.getDefaultSmsSubscriptionId()
            if (subId != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                return SmsManager.getSmsManagerForSubscriptionId(subId)
            }
        }
        @Suppress("DEPRECATION")
        return SmsManager.getDefault()
    }

    companion object {
        private const val TAG = "ReplyMateMainActivity"
        private const val REQUEST_CODE_DEFAULT_SMS = 10101
    }
}
