package com.replymate.reply_mate.receivers

import android.app.Activity
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.firestore.FieldValue
import com.google.firebase.firestore.FirebaseFirestore
import com.google.firebase.firestore.SetOptions
import com.replymate.reply_mate.activity.ActivityLogPendingStore
import com.replymate.reply_mate.autoreply.AutoReplyEngine
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.util.Calendar

/**
 * Receives [SmsManager] multipart "sent" result for the last part only.
 */
class SmsSendResultReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val pendingResult = goAsync()
        try {
            onReceiveImpl(context, intent, pendingResult)
        } catch (t: Throwable) {
            Log.e(TAG, "onReceive failed", t)
            pendingResult.finish()
        }
    }

    private fun onReceiveImpl(context: Context, intent: Intent, pendingResult: PendingResult) {
        val phone = intent.getStringExtra(EXTRA_PHONE)
        val logId = intent.getStringExtra(EXTRA_LOG_ID)
        
        val actualResultCode = pendingResult.resultCode
        val isSuccess = actualResultCode == Activity.RESULT_OK
        
        if (!logId.isNullOrEmpty()) {
            if (!isSuccess) {
                Log.d(TAG, "SMS send failed resultCode=$actualResultCode logId=$logId phone=$phone")
            } else {
                Log.d(TAG, "SMS sent successfully logId=$logId phone=$phone")
                if (!phone.isNullOrEmpty()) {
                    AutoReplyEngine.updateThrottleState(context.applicationContext, phone)
                }
            }
            ActivityLogPendingStore.appendPatchReplied(context.applicationContext, logId, isSuccess)
            _updateStats(context, isSuccess, pendingResult)
            return
        }
        if (!isSuccess) {
            Log.d(TAG, "SMS send failed (no activity log id) resultCode=$actualResultCode phone=$phone")
            _updateStats(context, false, pendingResult)
        } else {
            pendingResult.finish()
        }
    }

    private fun _updateStats(context: Context, success: Boolean, pendingResult: PendingResult) {
        CoroutineScope(Dispatchers.IO).launch {
            try {
                try {
                    if (com.google.firebase.FirebaseApp.getApps(context).isEmpty()) {
                        com.google.firebase.FirebaseApp.initializeApp(context.applicationContext)
                    }
                } catch (fe: Exception) {
                    Log.w(TAG, "Failed to initialize Firebase in _updateStats", fe)
                }
                val db = FirebaseFirestore.getInstance()
                val now = Calendar.getInstance()
                val year = now.get(Calendar.YEAR)
                val month = now.get(Calendar.MONTH) + 1
                val day = now.get(Calendar.DAY_OF_MONTH)

                val dailyId = "$year-${month.toString().padStart(2, '0')}-${day.toString().padStart(2, '0')}"
                val monthlyId = "$year-${month.toString().padStart(2, '0')}"

                // Use phone number as the document ID in stats collection to match admin portal
                val firebaseUser = FirebaseAuth.getInstance().currentUser
                val uid = firebaseUser?.phoneNumber?.takeIf { it.isNotEmpty() }
                    ?: AutoReplyConfigStore(context).getUserId()
                Log.d(TAG, "User ID for stats: $uid")

                val field = if (success) "smsSent" else "smsFailed"
                val totalField = if (success) "totalSmsSent" else "totalSmsFailed"

                val batch = db.batch()

                // 1. Global daily_stats
                val globalDailyRef = db.collection("daily_stats").document(dailyId)
                batch.set(globalDailyRef, mapOf(
                    "date" to com.google.firebase.Timestamp.now(),
                    field to FieldValue.increment(1)
                ), SetOptions.merge())

                // 2. Global monthly_stats
                val globalMonthlyRef = db.collection("monthly_stats").document(monthlyId)
                batch.set(globalMonthlyRef, mapOf(
                    "year" to year,
                    "month" to month,
                    field to FieldValue.increment(1)
                ), SetOptions.merge())

                if (!uid.isNullOrEmpty()) {
                    val userStatsRef = db.collection("stats").document(uid)

                    // 3. Cumulative totals on stats/{uid}
                    batch.set(userStatsRef, mapOf(
                        totalField to FieldValue.increment(1),
                        "lastSmsAt" to com.google.firebase.Timestamp.now(),
                        "lastActiveAt" to com.google.firebase.Timestamp.now()
                    ), SetOptions.merge())

                    // 4. Per-user daily: stats/{uid}/daily/{dailyId}
                    val userDailyRef = userStatsRef.collection("daily").document(dailyId)
                    batch.set(userDailyRef, mapOf(
                        field to FieldValue.increment(1),
                        "updatedAt" to com.google.firebase.Timestamp.now()
                    ), SetOptions.merge())

                    // 5. Per-user monthly: stats/{uid}/monthly/{monthlyId}
                    val userMonthlyRef = userStatsRef.collection("monthly").document(monthlyId)
                    batch.set(userMonthlyRef, mapOf(
                        field to FieldValue.increment(1),
                        "updatedAt" to com.google.firebase.Timestamp.now()
                    ), SetOptions.merge())

                    Log.d(TAG, "Stats updated: $field for uid=$uid")
                } else {
                    Log.d(TAG, "No uid — per-user stats not recorded")
                }

                batch.commit().addOnCompleteListener {
                    pendingResult.finish()
                }
            } catch (e: Exception) {
                Log.w(TAG, "Failed to update stats: $e")
                pendingResult.finish()
            }
        }
    }

    companion object {
        const val EXTRA_PHONE = "extra_phone"
        const val EXTRA_LOG_ID = "extra_log_id"
        private const val TAG = "ReplyMateSmsResult"
    }
}
