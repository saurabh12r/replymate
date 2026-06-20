package com.replymate.reply_mate.services

import android.os.Build
import android.util.Log
import com.google.firebase.messaging.RemoteMessage
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingService

class MyFirebaseMessagingService : FlutterFirebaseMessagingService() {

    override fun onMessageReceived(remoteMessage: RemoteMessage) {
        val data = remoteMessage.data
        Log.d(TAG, "onMessageReceived: data=$data")

        val type = data["type"]
        if (type != null) {
            val context = applicationContext
            val configStore = AutoReplyConfigStore(context)
            when (type) {
                "account_suspended" -> {
                    Log.i(TAG, "Suspending account immediately...")
                    configStore.setBlocked(true)
                    AutoReplyForegroundService.stop(context)
                }
                "account_approved", "account_unblocked" -> {
                    Log.i(TAG, "Unblocking/activating account immediately...")
                    configStore.setBlocked(false)
                    
                    val subEndStr = data["subscriptionEnd"]
                    if (!subEndStr.isNullOrEmpty()) {
                        val subEndMs = parseIsoEpochMs(subEndStr)
                        if (subEndMs > 0L) {
                            configStore.setSubEndTime(subEndMs)
                            Log.i(TAG, "Updated subscription end time: $subEndMs")
                        }
                    }
                    
                    if (configStore.isEnabledFailSafe()) {
                        AutoReplyForegroundService.start(context)
                    } else {
                        AutoReplyForegroundService.stop(context)
                    }
                }
                "plan_assigned" -> {
                    Log.i(TAG, "Plan assigned, syncing subscription time...")
                    val subEndStr = data["subscriptionEnd"]
                    if (!subEndStr.isNullOrEmpty()) {
                        val subEndMs = parseIsoEpochMs(subEndStr)
                        if (subEndMs > 0L) {
                            configStore.setSubEndTime(subEndMs)
                            Log.i(TAG, "Updated subscription end time to: $subEndMs")
                            
                            if (subEndMs > System.currentTimeMillis()) {
                                configStore.setBlocked(false)
                                if (configStore.isEnabledFailSafe()) {
                                    AutoReplyForegroundService.start(context)
                                }
                            }
                        }
                    }
                    if (!configStore.isEnabledFailSafe()) {
                        AutoReplyForegroundService.stop(context)
                    }
                }
            }
        }

        // Delegate to standard flutter service so it parses messages, notifications, etc.
        super.onMessageReceived(remoteMessage)
    }

    private fun parseIsoEpochMs(isoStr: String): Long {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                java.time.Instant.parse(isoStr).toEpochMilli()
            } else {
                val cleaned = isoStr.replace("Z", "+0000").replace(Regex("\\.\\d+"), "")
                val sdf = java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ssZ", java.util.Locale.US)
                sdf.parse(cleaned)?.time ?: 0L
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to parse ISO date: $isoStr", e)
            0L
        }
    }

    companion object {
        private const val TAG = "ReplyMateFcmService"
    }
}
