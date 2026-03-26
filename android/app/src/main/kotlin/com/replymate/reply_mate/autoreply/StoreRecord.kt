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
    val replyOutgoingCall: Boolean,
    val templates: List<StoreTemplate>,
    /** Event key → template id */
    val eventTemplateIds: Map<String, String>,
) {
    fun isEventEnabled(event: AutoReplyEvent): Boolean {
        return when (event) {
            AutoReplyEvent.MISSED_CALL -> replyMissedCall
            AutoReplyEvent.CALL_ANSWERED -> replyIncomingCall
            AutoReplyEvent.MISSED_WHATSAPP_CALL -> replyWhatsappCall
            AutoReplyEvent.BUSY_CALL -> replyBusyCall
            AutoReplyEvent.OUTGOING_CALL -> replyOutgoingCall
        }
    }

    fun resolveMessage(event: AutoReplyEvent): String? {
        val key = StoreEventKeys.forAutoReplyEvent(event)
        val templateId = eventTemplateIds[key] ?: return null
        val t = templates.find { it.id == templateId } ?: return null
        return t.text.trim().takeIf { it.isNotEmpty() }
    }
}
