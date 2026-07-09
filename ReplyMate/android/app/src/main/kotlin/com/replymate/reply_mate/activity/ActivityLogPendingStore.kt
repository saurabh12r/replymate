package com.replymate.reply_mate.activity

import android.content.Context
import org.json.JSONObject
import java.io.File

/**
 * Append-only JSONL queue read by Flutter into Hive. Used when the Dart isolate is not running.
 */
object ActivityLogPendingStore {
    private const val FILE_NAME = "replymate_activity_pending.jsonl"

    @Synchronized
    fun appendCall(
        context: Context,
        id: String,
        type: Int,
        phone: String?,
        name: String?,
        replied: Boolean,
        messageSent: String = "",
        isVacation: Boolean = false
    ) {
        val normalizedPhone = phone?.trim().orEmpty()
        val normalizedName = name?.trim().orEmpty()
        val msg = messageSent.trim()
        val ts = System.currentTimeMillis()
        val json = JSONObject().apply {
            put("kind", "call")
            put("id", id)
            put("name", normalizedName)
            put("phoneNumber", normalizedPhone)
            put("type", type)
            put("replied", replied)
            put("messageSent", msg)
            put("timestamp", ts)
            put("isVacation", isVacation)
        }
        appendRawLine(context, json.toString())
    }

    @Synchronized
    fun appendPatchReplied(context: Context, id: String, replied: Boolean) {
        val json = JSONObject().apply {
            put("kind", "patchReplied")
            put("id", id)
            put("replied", replied)
        }
        appendRawLine(context, json.toString())
    }

    private fun appendRawLine(context: Context, line: String) {
        val file = File(context.filesDir, FILE_NAME)
        file.appendText(line + "\n")
    }

    @Synchronized
    fun pullLines(context: Context): List<String> {
        val file = File(context.filesDir, FILE_NAME)
        if (!file.exists()) return emptyList()
        return try {
            val lines = file.readLines().filter { it.isNotBlank() }
            file.delete()
            lines
        } catch (_: Exception) {
            emptyList()
        }
    }
}
