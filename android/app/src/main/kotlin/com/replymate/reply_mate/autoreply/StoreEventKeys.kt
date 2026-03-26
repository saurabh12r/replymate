package com.replymate.reply_mate.autoreply

/** JSON / Flutter keys for per-store event template mapping. */
object StoreEventKeys {
    const val MISSED_CALL = "missed_call"
    const val INCOMING_CALL = "incoming_call"
    const val MISSED_WHATSAPP = "missed_whatsapp"
    const val BUSY_CALL = "busy_call"
    const val OUTGOING_CALL = "outgoing_call"

    fun forAutoReplyEvent(event: AutoReplyEvent): String {
        return when (event) {
            AutoReplyEvent.MISSED_CALL -> MISSED_CALL
            AutoReplyEvent.CALL_ANSWERED -> INCOMING_CALL
            AutoReplyEvent.MISSED_WHATSAPP_CALL -> MISSED_WHATSAPP
            AutoReplyEvent.BUSY_CALL -> BUSY_CALL
            AutoReplyEvent.OUTGOING_CALL -> OUTGOING_CALL
        }
    }
}
