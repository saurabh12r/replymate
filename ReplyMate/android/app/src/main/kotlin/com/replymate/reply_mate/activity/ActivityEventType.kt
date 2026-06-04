package com.replymate.reply_mate.activity

/**
 * Must match Dart [EventType] index order (call activities only).
 */
object ActivityEventType {
    const val INCOMING_CALL = 0
    const val MISSED_CALL = 1
    const val WHATSAPP_CALL = 2
    const val BUSY_CALL = 3
    const val REJECTED_CALL = 4
    const val OUTGOING_ANSWERED = 5
    const val OUTGOING_UNANSWERED = 6
}
