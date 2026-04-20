package com.replymate.reply_mate.autoreply

import android.content.Context
import android.telephony.SubscriptionManager
import android.util.Log
import org.json.JSONArray
import org.json.JSONObject
import java.util.UUID

/**
 * Multi-store registry (JSON in SharedPreferences). Source of truth for per-SIM auto-reply rules
 * and template-based messages after migration.
 */
class StoreConfigStore(private val context: Context) {
    private val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)

    fun ensureMigrated() {
        if (prefs.getBoolean(KEY_MIGRATED, false)) return
        val existing = prefs.getString(KEY_STORES_JSON, null)
        if (!existing.isNullOrBlank() && existing != "{}" && existing != "[]") {
            try {
                JSONArray(existing)
                prefs.edit().putBoolean(KEY_MIGRATED, true).apply()
                return
            } catch (_: Exception) {
                // Fall through to legacy migration attempt below.
            }
        }
        try {
            val legacy = AutoReplyConfigStore(context)
            val store = buildDefaultStoreFromLegacy(legacy)
            val json = storesToJson(listOf(store))
            prefs.edit()
                .putString(KEY_STORES_JSON, json)
                .putBoolean(KEY_MIGRATED, true)
                .apply()
            Log.d(TAG, "Store migration completed: 1 default store")
        } catch (e: Exception) {
            Log.e(TAG, "Store migration failed", e)
        }
    }

    fun getStores(): List<StoreRecord> {
        ensureMigrated()
        return parseStores(prefs.getString(KEY_STORES_JSON, null))
    }

    fun getStoresJsonOrEmpty(): String {
        ensureMigrated()
        return prefs.getString(KEY_STORES_JSON, "[]") ?: "[]"
    }

    /**
     * Saves stores. Enforces **one subscriptionId → one store**: if two stores share
     * the same non-null subscription id, the **last** store in the list keeps the SIM;
     * earlier stores have `subscriptionId` cleared (matches "reassign to new store").
     */
    fun setStoresJson(json: String) {
        val list = parseStores(json)
        val deduped = enforceUniqueSubscriptionIds(list)
        prefs.edit()
            .putString(KEY_STORES_JSON, storesToJson(deduped))
            .putBoolean(KEY_MIGRATED, true)
            .apply()
    }

    fun findStoreBySubscriptionId(subscriptionId: Int): StoreRecord? {
        if (subscriptionId == SubscriptionManager.INVALID_SUBSCRIPTION_ID) return null
        return getStores().firstOrNull { it.subscriptionId == subscriptionId }
    }

    private fun enforceUniqueSubscriptionIds(stores: List<StoreRecord>): List<StoreRecord> {
        val lastIndexForSub = mutableMapOf<Int, Int>()
        for (i in stores.indices) {
            val sid = stores[i].subscriptionId
            if (sid != null && sid != SubscriptionManager.INVALID_SUBSCRIPTION_ID) {
                lastIndexForSub[sid] = i
            }
        }
        return stores.mapIndexed { i, s ->
            val sid = s.subscriptionId
            if (sid == null || sid == SubscriptionManager.INVALID_SUBSCRIPTION_ID) return@mapIndexed s
            if (lastIndexForSub[sid] != i) s.copy(subscriptionId = null) else s
        }
    }

    companion object {
        private const val TAG = "ReplyMateStoreConfig"
        const val PREFS_NAME = "replymate_store_prefs"
        private const val KEY_STORES_JSON = "stores_json_v1"
        private const val KEY_MIGRATED = "stores_migrated_v1"

        const val DEFAULT_STORE_ID = "default-store"

        fun buildDefaultStoreFromLegacy(legacy: AutoReplyConfigStore): StoreRecord {
            val msgMissed = legacy.missedCallMessage()
            val msgIncoming = legacy.incomingCallMessage()
            val msgWa = legacy.whatsappCallMessage()
            val msgBusy = legacy.busyCallMessage()
            val msgRejected = legacy.rejectedCallMessage()
            val msgOutAns = legacy.outgoingAnsweredMessage()
            val msgOutUnans = legacy.outgoingUnansweredMessage()

            val templates = mutableListOf<StoreTemplate>()
            val idToTemplate = mutableMapOf<String, String>()
            fun idFor(text: String): String {
                val existing = idToTemplate.entries.find { it.value == text }?.key
                if (existing != null) return existing
                val id = UUID.randomUUID().toString()
                idToTemplate[id] = text
                templates.add(StoreTemplate(id = id, text = text))
                return id
            }

            val eventMap = mapOf(
                StoreEventKeys.MISSED_CALL to idFor(msgMissed),
                StoreEventKeys.INCOMING_CALL to idFor(msgIncoming),
                StoreEventKeys.MISSED_WHATSAPP to idFor(msgWa),
                StoreEventKeys.BUSY_CALL to idFor(msgBusy),
                StoreEventKeys.REJECTED_CALL to idFor(msgRejected),
                StoreEventKeys.OUTGOING_ANSWERED to idFor(msgOutAns),
                StoreEventKeys.OUTGOING_UNANSWERED to idFor(msgOutUnans),
            )

            return StoreRecord(
                id = DEFAULT_STORE_ID,
                name = "My business",
                subscriptionId = null,
                active = true,
                replyMissedCall = legacy.replyOnMissedCall(),
                replyIncomingCall = legacy.replyOnCallAnswered(),
                replyWhatsappCall = legacy.replyOnWhatsappCall(),
                replyBusyCall = legacy.replyOnBusyCall(),
                replyRejectedCall = legacy.replyOnRejectedCall(),
                replyOutgoingAnswered = legacy.replyOnOutgoingAnswered(),
                replyOutgoingUnanswered = legacy.replyOnOutgoingUnanswered(),
                enableDaysSetup = false,
                selectedDays = emptyList(),
                vacationMode = false,
                vacationMessage = "",
                templates = templates,
                eventTemplateIds = eventMap,
            )
        }

        fun parseStores(raw: String?): List<StoreRecord> {
            if (raw.isNullOrBlank()) return emptyList()
            return try {
                val arr = JSONArray(raw)
                val out = ArrayList<StoreRecord>(arr.length())
                for (i in 0 until arr.length()) {
                    val o = arr.getJSONObject(i)
                    out.add(parseStore(o))
                }
                out
            } catch (e: Exception) {
                Log.e(TAG, "parseStores failed", e)
                emptyList()
            }
        }

        private fun parseStore(o: JSONObject): StoreRecord {
            val templates = mutableListOf<StoreTemplate>()
            val ta = o.optJSONArray("templates")
            if (ta != null) {
                for (i in 0 until ta.length()) {
                    val t = ta.getJSONObject(i)
                    templates.add(
                        StoreTemplate(
                            id = t.optString("id", ""),
                            text = t.optString("text", ""),
                        )
                    )
                }
            }
            val eventMap = mutableMapOf<String, String>()
            val em = o.optJSONObject("eventTemplateIds")
            if (em != null) {
                val keys = em.keys()
                while (keys.hasNext()) {
                    val k = keys.next()
                    eventMap[k] = em.optString(k, "")
                }
            }
            // Migrate legacy "outgoing_call" key to the two new keys if present.
            val legacyOutgoing = eventMap.remove(StoreEventKeys.LEGACY_OUTGOING_CALL)
            if (legacyOutgoing != null && legacyOutgoing.isNotEmpty()) {
                if (!eventMap.containsKey(StoreEventKeys.OUTGOING_ANSWERED)) {
                    eventMap[StoreEventKeys.OUTGOING_ANSWERED] = legacyOutgoing
                }
                if (!eventMap.containsKey(StoreEventKeys.OUTGOING_UNANSWERED)) {
                    eventMap[StoreEventKeys.OUTGOING_UNANSWERED] = legacyOutgoing
                }
            }

            val sub = if (o.has("subscriptionId") && !o.isNull("subscriptionId")) {
                o.optInt("subscriptionId", SubscriptionManager.INVALID_SUBSCRIPTION_ID).takeIf {
                    it != SubscriptionManager.INVALID_SUBSCRIPTION_ID
                }
            } else {
                null
            }

            // Legacy field migration: old "replyOutgoingCall" → both new outgoing toggles.
            val legacyOutToggle = o.optBoolean("replyOutgoingCall", false)
            
            val enableDaysSetup = o.optBoolean("enableDaysSetup", false)
            val selectedDays = mutableListOf<Int>()
            val sda = o.optJSONArray("selectedDays")
            if (sda != null) {
                for (i in 0 until sda.length()) {
                    selectedDays.add(sda.getInt(i))
                }
            }

            return StoreRecord(
                id = o.optString("id", UUID.randomUUID().toString()),
                name = o.optString("name", "Business"),
                subscriptionId = sub,
                active = o.optBoolean("active", true),
                replyMissedCall = o.optBoolean("replyMissedCall", true),
                replyIncomingCall = o.optBoolean("replyIncomingCall", false),
                replyWhatsappCall = o.optBoolean("replyWhatsappCall", true),
                replyBusyCall = o.optBoolean("replyBusyCall", false),
                replyRejectedCall = o.optBoolean("replyRejectedCall", false),
                replyOutgoingAnswered = o.optBoolean("replyOutgoingAnswered", legacyOutToggle),
                replyOutgoingUnanswered = o.optBoolean("replyOutgoingUnanswered", legacyOutToggle),
                enableDaysSetup = enableDaysSetup,
                selectedDays = selectedDays,
                vacationMode = o.optBoolean("vacationMode", false),
                vacationMessage = o.optString("vacationMessage", ""),
                templates = templates,
                eventTemplateIds = eventMap,
                imagePath = o.optString("imagePath", null).takeIf { !it.isNullOrBlank() },
            )
        }

        fun storesToJson(stores: List<StoreRecord>): String {
            val arr = JSONArray()
            for (s in stores) {
                arr.put(storeToJson(s))
            }
            return arr.toString()
        }

        fun storeToJson(s: StoreRecord): JSONObject {
            val o = JSONObject()
            o.put("id", s.id)
            o.put("name", s.name)
            if (s.subscriptionId != null) {
                o.put("subscriptionId", s.subscriptionId)
            } else {
                o.put("subscriptionId", JSONObject.NULL)
            }
            o.put("active", s.active)
            o.put("replyMissedCall", s.replyMissedCall)
            o.put("replyIncomingCall", s.replyIncomingCall)
            o.put("replyWhatsappCall", s.replyWhatsappCall)
            o.put("replyBusyCall", s.replyBusyCall)
            o.put("replyRejectedCall", s.replyRejectedCall)
            o.put("replyOutgoingAnswered", s.replyOutgoingAnswered)
            o.put("replyOutgoingUnanswered", s.replyOutgoingUnanswered)
            o.put("enableDaysSetup", s.enableDaysSetup)
            val sda = JSONArray()
            for (d in s.selectedDays) {
                sda.put(d)
            }
            o.put("selectedDays", sda)
            o.put("vacationMode", s.vacationMode)
            o.put("vacationMessage", s.vacationMessage)
            val ta = JSONArray()
            for (t in s.templates) {
                val to = JSONObject()
                to.put("id", t.id)
                to.put("text", t.text)
                ta.put(to)
            }
            o.put("templates", ta)
            val em = JSONObject()
            for ((k, v) in s.eventTemplateIds) {
                em.put(k, v)
            }
            o.put("eventTemplateIds", em)
            if (!s.imagePath.isNullOrBlank()) {
                o.put("imagePath", s.imagePath)
            }
            return o
        }
    }
}
