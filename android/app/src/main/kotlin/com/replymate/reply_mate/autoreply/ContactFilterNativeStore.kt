package com.replymate.reply_mate.autoreply

import android.content.Context
import android.util.Log
import org.json.JSONArray

/**
 * Native mirror of Flutter contact filter (SharedPreferences written from Dart via MethodChannel).
 */
object ContactFilterNativeStore {
    private const val TAG = "ReplyMateContactFilter"
    private const val PREFS_NAME = "replymate_contact_filter_native"
    private const val KEY_MODE = "filter_mode"
    private const val KEY_PHONES_JSON = "phones_json"

    fun syncFromFlutter(context: Context, filterMode: String, phonesJson: String) {
        context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .edit()
            .putString(KEY_MODE, filterMode)
            .putString(KEY_PHONES_JSON, phonesJson)
            .apply()
    }

    /**
     * @param digitsOnly digits-only string (no + or spaces)
     */
    fun shouldSendSms(context: Context, digitsOnly: String): Boolean {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val mode = prefs.getString(KEY_MODE, "ALL") ?: "ALL"
        if (mode == "ALL") return true
        val canon = ContactPhoneNormalize.canonicalPhoneKey(digitsOnly)
        if (canon.length < 10) {
            return mode != "ONLY"
        }
        val set = parsePhones(prefs.getString(KEY_PHONES_JSON, "[]"))
        return when (mode) {
            "ONLY" -> set.contains(canon)
            "EXCLUDE" -> !set.contains(canon)
            else -> true
        }
    }

    private fun parsePhones(json: String?): Set<String> {
        if (json.isNullOrBlank()) return emptySet()
        return try {
            val arr = JSONArray(json)
            val out = HashSet<String>()
            for (i in 0 until arr.length()) {
                val v = arr.optString(i, null) ?: continue
                val d = ContactPhoneNormalize.digitsOnly(v)
                if (d.isEmpty()) continue
                val k = ContactPhoneNormalize.canonicalPhoneKey(d)
                if (k.length >= 10) out.add(k)
            }
            out
        } catch (e: Exception) {
            Log.w(TAG, "parsePhones failed", e)
            emptySet()
        }
    }
}
