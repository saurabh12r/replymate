package com.replymate.reply_mate.autoreply

/** JSON / Flutter keys for per-store event template mapping. */
object StoreEventKeys {
    const val MISSED_CALL = "missed_call"
    const val INCOMING_CALL = "incoming_call"
    const val MISSED_WHATSAPP = "missed_whatsapp"
    const val BUSY_CALL = "busy_call"
    const val REJECTED_CALL = "rejected_call"
    const val OUTGOING_ANSWERED = "outgoing_answered"
    const val OUTGOING_UNANSWERED = "outgoing_unanswered"

    /** Legacy key kept only for migration. */
    const val LEGACY_OUTGOING_CALL = "outgoing_call"

    fun forAutoReplyEvent(event: AutoReplyEvent): String {
        return when (event) {
            AutoReplyEvent.MISSED_CALL -> MISSED_CALL
            AutoReplyEvent.CALL_ANSWERED -> INCOMING_CALL
            AutoReplyEvent.MISSED_WHATSAPP_CALL -> MISSED_WHATSAPP
            AutoReplyEvent.BUSY_CALL -> BUSY_CALL
            AutoReplyEvent.REJECTED_CALL -> REJECTED_CALL
            AutoReplyEvent.OUTGOING_ANSWERED -> OUTGOING_ANSWERED
            AutoReplyEvent.OUTGOING_UNANSWERED -> OUTGOING_UNANSWERED
        }
    }
}
