package com.replymate.reply_mate.autoreply

data class StoreTemplate(
    val id: String,
    val text: String,
)

data class StoreRecord(
    val id: String,
    val name: String,
    /** [android.telephony.SubscriptionManager.INVALID_SUBSCRIPTION_ID] means unassigned when null. */
    val subscriptionId: Int?,
    val active: Boolean,
    val replyMissedCall: Boolean,
    val replyIncomingCall: Boolean,
    val replyWhatsappCall: Boolean,
    val replyBusyCall: Boolean,
    val replyRejectedCall: Boolean,
    val replyOutgoingAnswered: Boolean,
    val replyOutgoingUnanswered: Boolean,
    val enableDaysSetup: Boolean = false,
    val selectedDays: List<Int> = emptyList(),
    val vacationMode: Boolean = false,
    val vacationMessage: String = "",
    val templates: List<StoreTemplate>,
    /** Event key → template id */
    val eventTemplateIds: Map<String, String>,
) {
    fun isEventEnabled(event: AutoReplyEvent): Boolean {
        if (enableDaysSetup) {
            val calendar = java.util.Calendar.getInstance()
            val javaDay = calendar.get(java.util.Calendar.DAY_OF_WEEK)
            // Map Java DAY_OF_WEEK (Sun=1, Mon=2) to Dart DateTime.weekday (Mon=1, ..., Sun=7)
            val currentDartDay = if (javaDay == java.util.Calendar.SUNDAY) 7 else javaDay - 1
            if (!selectedDays.contains(currentDartDay)) {
                return false
            }
        }
        if (vacationMode) {
            return true
        }
        return when (event) {
            AutoReplyEvent.MISSED_CALL -> replyMissedCall
            AutoReplyEvent.CALL_ANSWERED -> replyIncomingCall
            AutoReplyEvent.MISSED_WHATSAPP_CALL -> replyWhatsappCall
            AutoReplyEvent.BUSY_CALL -> replyBusyCall
            AutoReplyEvent.REJECTED_CALL -> replyRejectedCall
            AutoReplyEvent.OUTGOING_ANSWERED -> replyOutgoingAnswered
            AutoReplyEvent.OUTGOING_UNANSWERED -> replyOutgoingUnanswered
        }
    }

    fun resolveMessage(event: AutoReplyEvent): String? {
        if (vacationMode && vacationMessage.isNotBlank()) {
            return vacationMessage.trim()
        }
        val key = StoreEventKeys.forAutoReplyEvent(event)
        val templateId = eventTemplateIds[key] ?: return null
        val t = templates.find { it.id == templateId } ?: return null
        return t.text.trim().takeIf { it.isNotEmpty() }
    }
}
