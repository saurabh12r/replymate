package com.replymate.reply_mate.services

import android.net.Uri
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import com.replymate.reply_mate.autoreply.AutoReplyConfigStore
import com.replymate.reply_mate.autoreply.AutoReplyEngine
import com.replymate.reply_mate.autoreply.AutoReplyEvent

class ReplyMateNotificationListenerService : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        // Global master guard: if OFF/unset/error, do not process anything.
        if (!AutoReplyConfigStore(this).isEnabledFailSafe()) {
            Log.d(TAG, "Blocked notification event: autoReplyEnabled=false")
            return
        }

        val pkg = sbn.packageName ?: return
        if (pkg != WHATSAPP && pkg != WHATSAPP_BUSINESS) {
            return
        }

        val extras = sbn.notification.extras
        val title = extras?.getString("android.title").orEmpty()
        val text = extras?.getString("android.text").orEmpty()
        Log.d(TAG, "WhatsApp notification received: pkg=$pkg title=$title text=$text")
        val lowerText = text.lowercase()
        val lowerTitle = title.lowercase()

        val isMissedWhatsAppCall = MISSED_CALL_KEYWORDS.any {
            lowerText.contains(it) || lowerTitle.contains(it)
        }
        if (!isMissedWhatsAppCall) {
            Log.d(TAG, "Skipped: notification is not a missed WhatsApp call")
            return
        }

        val phoneFromPeople = extractPhoneFromPeople(extras?.getStringArray("android.people"))
        val phoneFromText = extractPhoneFromText("$title $text")
        val phoneNumber = phoneFromPeople ?: phoneFromText
        Log.d(
            TAG,
            "Phone extraction: fromPeople=$phoneFromPeople fromText=$phoneFromText resolved=$phoneNumber"
        )
        AutoReplyEngine.handleEvent(
            this,
            AutoReplyEvent.MISSED_WHATSAPP_CALL,
            phoneNumber
        )
    }

    override fun onNotificationRemoved(sbn: StatusBarNotification) {
        Log.d(TAG, "Notification removed from: ${sbn.packageName}")
    }

    private fun extractPhoneFromPeople(people: Array<String>?): String? {
        if (people.isNullOrEmpty()) return null
        for (value in people) {
            try {
                val uri = Uri.parse(value)
                if (uri.scheme.equals("tel", ignoreCase = true)) {
                    val number = uri.schemeSpecificPart
                    if (!number.isNullOrBlank()) return number
                }
            } catch (_: Exception) {
            }
        }
        return null
    }

    private fun extractPhoneFromText(text: String): String? {
        val match = Regex("(\\+?\\d[\\d\\s-]{7,}\\d)").find(text)
        return match?.value?.replace(" ", "")?.replace("-", "")
    }

    companion object {
        private const val TAG = "ReplyMateNotifListener"
        private const val WHATSAPP = "com.whatsapp"
        private const val WHATSAPP_BUSINESS = "com.whatsapp.w4b"
        private val MISSED_CALL_KEYWORDS = listOf(
            "missed call",
            "missed voice call",
            "missed video call"
        )
    }
}
