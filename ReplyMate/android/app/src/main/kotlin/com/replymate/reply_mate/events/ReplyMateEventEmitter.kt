package com.replymate.reply_mate.events

import io.flutter.plugin.common.EventChannel

/**
 * Streams auto-reply events to Flutter when the engine is running (foreground-friendly UI updates).
 */
object ReplyMateEventEmitter {
    @Volatile
    private var sink: EventChannel.EventSink? = null

    fun attach(events: EventChannel.EventSink?) {
        sink = events
    }

    fun emit(payload: Map<String, Any?>) {
        try {
            sink?.success(payload)
        } catch (_: Exception) {
        }
    }
}
